//
//  AppsflyerSdkPlugin.swift
//  appsflyer_sdk
//

import Foundation
import UIKit
import Flutter

// Plugin version
private let kAppsFlyerPluginVersion = "7.0.1"

// Flutter channels
private let afMethodChannel = "af-api"
private let afEventChannel = "af-events"

// RPC method names that need plugin-side orchestration (everything else is forwarded generically).
private let kRpcInit = "init"
private let kRpcLogAndOpenStore = "logAndOpenStore"
private let kRpcSetPluginInfo = "setPluginInfo"

/// Upper bound for events buffered while no `af-events` sink is attached.
///
/// An integration that registers native listeners but never subscribes to the Dart streams — or
/// cancels its subscription for the rest of the session — would otherwise grow the buffer for the
/// lifetime of the engine. A session buffers a handful of events, so the cap only acts as a safety
/// valve. Mirrors `MAX_PENDING_EVENTS` in `AppsFlyerEventBus.kt`.
private let kMaxPendingEvents = 64

/// Matches `PLUGIN_DETACHED` / detach messaging in `AppsflyerSdkPlugin.kt`.
private let kPluginDetached = "PLUGIN_DETACHED"
private let kPluginDetachedMessage = "Plugin is not attached to a Flutter engine"

@objc(AppsflyerSdkPlugin)
public class AppsflyerSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    /// One entry of the ordered `init` RPC sequence. Built and consumed inside this class only —
    /// each entry's `params` is forwarded to the RPC layer as the untouched Foundation payload.
    private struct RpcCall {
        let method: String
        let params: NSDictionary
    }

    /// All mutable state below is confined to the main thread. Channel handlers and UIKit callbacks
    /// already arrive there, `AFRPCBridge` normalizes RPC completions and events onto it, and
    /// `tearDownForEngineDetach()` hops onto it — so none of it needs its own lock.
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var pendingEvents: [String] = []
    private var eventHandlerRegistered = false
    /// Set in `tearDownForEngineDetach()` so in-flight `executeJson` completions and nested
    /// `DispatchQueue.main.async` work from `logAndOpenStoreFromRpc` do not call `FlutterResult` or
    /// `markBridgeReady(markedBy:)` after this engine's channel is gone.
    private var isEngineDetached = false

    // ============================================================================
    // Plugin / channel lifecycle
    // ============================================================================

    init(messenger: FlutterBinaryMessenger) {
        let channel = FlutterEventChannel(name: afEventChannel, binaryMessenger: messenger)
        eventChannel = channel
        super.init()
        channel.setStreamHandler(self)
        // Wire the bridge event handler as early as possible: the RPC layer drops events emitted
        // before a handler is attached, so it must be set before start() and listener registration.
        registerEventHandler()
    }

    @objc(registerWithRegistrar:)
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if ENABLE_PURCHASE_CONNECTOR
        PurchaseConnectorPlugin.register(with: registrar)
        #endif
        let messenger = registrar.messenger()
        let instance = AppsflyerSdkPlugin(messenger: messenger)
        // publish: is required so FlutterEngine dealloc invokes detachFromEngineForRegistrar:.
        registrar.publish(instance)
        let channel = FlutterMethodChannel(name: afMethodChannel, binaryMessenger: messenger)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        addSceneDelegateIfSupported(instance, registrar: registrar)
    }

    /// Stands in for the Objective-C `__has_include(<Flutter/FlutterSceneLifeCycle.h>)` guard, which
    /// Swift has no equivalent of: `addSceneDelegate:` only exists in Flutter versions that ship
    /// `FlutterSceneLifeCycleDelegate`, so the registrar is probed for it instead. Flutter dispatches
    /// every scene callback through `respondsToSelector:` (it never checks protocol conformance), so
    /// the `scene:...` methods below participate exactly as the declared conformance used to.
    /// The iOS 13.0 availability check the Objective-C code carried is implied by the iOS 13
    /// deployment target of both the podspec and the SPM manifest.
    private static func addSceneDelegateIfSupported(_ instance: AppsflyerSdkPlugin,
                                                    registrar: FlutterPluginRegistrar) {
        let selector = NSSelectorFromString("addSceneDelegate:")
        guard registrar.responds(to: selector) else {
            return
        }
        _ = registrar.perform(selector, with: instance)
    }

    @objc(detachFromEngineForRegistrar:)
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        #if ENABLE_PURCHASE_CONNECTOR
        // The connector is registered from `register(with:)` but publishes no instance of its own, so
        // it only reaches a detach callback through this one. Android forwards the same pair of
        // lifecycle events to `AppsFlyerPurchaseConnector`.
        PurchaseConnectorPlugin.tearDownForEngineDetach(registrar: registrar)
        #endif
        tearDownForEngineDetach()
    }

    /// Engine detach is the one lifecycle callback that can arrive off the main thread — every other
    /// writer of this instance's state (`onListen`, `onCancel`, `deliverEvent`, and the RPC
    /// completions that read `isEngineDetached`) already runs there. Hopping serializes teardown
    /// against them instead of mutating `pendingEvents` and `eventSink` underneath a concurrent
    /// `deliverEvent`, mirroring `AppsFlyerAttribution.onMain`.
    ///
    /// `self` is captured strongly so teardown still completes if the engine releases the plugin
    /// first: both the bridge's handler slot and `AppsFlyerAttribution`'s queue are keyed on this
    /// instance's identity, and a released owner would leave the bridge holding a handler no
    /// detaching instance can claim.
    private func tearDownForEngineDetach() {
        onMain { [self] in
            isEngineDetached = true
            eventSink = nil
            pendingEvents.removeAll()
            eventHandlerRegistered = false
            // Ownership-checked: in a multi-engine host this instance may no longer hold the bridge's
            // single event-handler slot, and tearing down must not cut events off from the engine that
            // does. See `AFRPCBridge.eventHandlerOwner`.
            AFRPCBridge.removeEventHandler(owner: self)
            eventChannel?.setStreamHandler(nil)
            AppsFlyerAttribution.shared().resetBridgeStateIfOwned(by: self)
        }
    }

    private func onMain(_ body: @escaping () -> Void) {
        if Thread.isMainThread {
            body()
        } else {
            DispatchQueue.main.async(execute: body)
        }
    }

    /// `eventHandlerRegistered` only keeps the second call site (`initFromRpc`) from re-registering
    /// what `init(messenger:)` already installed — instance state cannot guard the bridge's global
    /// slot, which is what `AFRPCBridge`'s owner tracking is for.
    private func registerEventHandler() {
        if eventHandlerRegistered {
            return
        }
        eventHandlerRegistered = true
        AFRPCBridge.setEventHandler(owner: self) { [weak self] jsonEvent in
            self?.deliverEvent(jsonEvent)
        }
    }

    // MARK: - FlutterStreamHandler (af-events)

    @objc(onListenWithArguments:eventSink:)
    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        flushPendingEvents()
        return nil
    }

    @objc(onCancelWithArguments:)
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // ============================================================================
    // Method channel entry point
    // ============================================================================

    @objc(handleMethodCall:result:)
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if "executeRpc" == call.method {
            executeRpc(call, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    /// Single RPC entry point. Initialization and the cross-promotion URL side effect require
    /// plugin orchestration; every other method is forwarded to AppsFlyerRPC as-is.
    private func executeRpc(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard !isEngineDetached else {
            // Synchronous entry after detach: complete the Dart Future with PLUGIN_DETACHED.
            // deliverFlutterResult intentionally no-ops here for async completions.
            result(FlutterError(code: kPluginDetached,
                                message: kPluginDetachedMessage,
                                details: nil))
            return
        }
        // Internal transport contract (_invokeRpc): {method, params}. Apps must not call this
        // channel directly; a malformed envelope is an integration error and is rejected by
        // parseEnvelope before dispatch (fail-fast, not FlutterError).
        let envelope = parseEnvelope(call)

        if kRpcInit == envelope.method {
            initFromRpc(envelope.params, result: result)
        } else if kRpcLogAndOpenStore == envelope.method {
            logAndOpenStoreFromRpc(envelope.params, result: result)
        } else {
            dispatchRpc(envelope.method, params: envelope.params, result: result)
        }
    }

    private struct RpcEnvelope {
        let method: String
        let params: NSDictionary
    }

    private func parseEnvelope(_ call: FlutterMethodCall) -> RpcEnvelope {
        guard let arguments = call.arguments as? NSDictionary else {
            rpcEnvelopeViolation("arguments must be Map")
        }
        guard let method = arguments["method"] as? String else {
            rpcEnvelopeViolation("method must be String")
        }
        guard let params = arguments["params"] as? NSDictionary else {
            rpcEnvelopeViolation("params must be Map")
        }
        return RpcEnvelope(method: method, params: params)
    }

    private func rpcEnvelopeViolation(_ detail: String) -> Never {
        preconditionFailure("RPC envelope contract violation: \(detail)")
    }

    // ============================================================================
    // init (SDK 7 session model). start() is forwarded generically via dispatchRpc,
    // like logEvent: its result returns on the per-call reply (params.awaitResponse).
    // ============================================================================

    private func initFromRpc(_ params: NSDictionary, result: @escaping FlutterResult) {
        registerEventHandler()

        let devKey = stringParam(params, key: "devKey")
        let appId = stringParam(params, key: "appId")

        // Ordered RPC sequence: initialize only. `handleLaunchOptions` is forwarded from
        // `application:didFinishLaunchingWithOptions:` as soon as launch options arrive — the native
        // SDK has no init dependency on that call. Listener registration is explicit in Dart.
        let sequence: [RpcCall] = [
            RpcCall(method: "initialize",
                    params: ["devKey": devKey ?? "", "appId": appId ?? ""])
        ]

        // setPluginInfo runs ahead of the sequence rather than inside it: the plugin name must
        // reach the first session payload, but it only labels reporting, so its outcome must not
        // abort initialization.
        //
        // self is captured strongly here and in runSequence: executeJson(forMethod:) already retains
        // self for the round trip, and a nil weak self would silently skip the rest of the chain,
        // leaving the Flutter result — and the Dart Future awaiting it — unresolved. No cycle is
        // possible: the closure is handed to the RPC bridge and never stored on self.
        executeJson(forMethod: kRpcSetPluginInfo,
                    params: ["plugin": "flutter", "pluginVersion": kAppsFlyerPluginVersion]) { _, _ in
            self.runSequence(sequence, index: 0) { sequenceError in
                guard !self.isEngineDetached else {
                    return
                }
                if let sequenceError = sequenceError {
                    self.deliverFlutterResult(result, sequenceError)
                    return
                }
                AppsFlyerAttribution.shared().markBridgeReady(markedBy: self)
                self.deliverFlutterResult(result, nil)
            }
        }
    }

    /// Fires the RPC sequence one entry at a time, each in the previous call's completion handler.
    private func runSequence(_ sequence: [RpcCall],
                             index: Int,
                             completion: @escaping (FlutterError?) -> Void) {
        if index >= sequence.count {
            completion(nil)
            return
        }
        let entry = sequence[index]
        executeJson(forMethod: entry.method, params: entry.params) { _, error in
            if let error = error {
                completion(error)
                return
            }
            self.runSequence(sequence, index: index + 1, completion: completion)
        }
    }

    private func logAndOpenStoreFromRpc(_ params: NSDictionary, result: @escaping FlutterResult) {
        executeJson(forMethod: kRpcLogAndOpenStore, params: params) { resultObj, error in
            guard !self.isEngineDetached else {
                return
            }
            if let error = error {
                self.deliverFlutterResult(result, error)
                return
            }
            let data = resultObj?["data"] as? [String: Any]
            var url: URL?
            if let clickURL = data?["clickURL"] as? String, !clickURL.isEmpty {
                url = URL(string: clickURL)
            }
            if let url = url {
                DispatchQueue.main.async {
                    guard !self.isEngineDetached else {
                        return
                    }
                    UIApplication.shared.open(url, options: [:]) { _ in
                        self.deliverFlutterResult(result, nil)
                    }
                }
                return
            }
            self.deliverFlutterResult(result, nil)
        }
    }

    // ============================================================================
    // Generic RPC dispatch + response unwrapping
    // ============================================================================

    private func dispatchRpc(_ method: String, params: NSDictionary, result: @escaping FlutterResult) {
        executeJson(forMethod: method, params: params) { resultObj, error in
            guard !self.isEngineDetached else {
                return
            }
            if let error = error {
                self.deliverFlutterResult(result, error)
                return
            }
            self.deliverFlutterResult(result, self.unwrapValue(forMethod: method, resultObj: resultObj))
        }
    }

    /// Invokes `FlutterResult` only while this engine instance is still attached. After detach the
    /// isolate may already be gone; skipping is safer than replying on a dead channel. The
    /// synchronous post-detach entry guard in `executeRpc` calls `result(...)` directly instead.
    private func deliverFlutterResult(_ result: @escaping FlutterResult, _ value: Any?) {
        guard !isEngineDetached else {
            return
        }
        result(value)
    }

    /// Serializes the {id?, method, params} envelope, calls the bridge, and normalizes the JSON string
    /// response into either (resultObj, nil) on success or (nil, FlutterError) on a protocol- or
    /// SDK-level failure — matching the (value / error) contract the Android dispatcher exposes.
    private func executeJson(forMethod method: String,
                             params: NSDictionary,
                             completion: @escaping (_ resultObj: [String: Any]?, _ error: FlutterError?) -> Void) {
        guard let json = jsonEnvelope(forMethod: method, params: params) else {
            completion(nil, FlutterError(code: "SERIALIZATION_ERROR",
                                         message: "Failed to serialize RPC request for \(method)",
                                         details: nil))
            return
        }
        AFRPCBridge.executeJson(json) { response in
            guard !self.isEngineDetached else {
                return
            }
            var parseError: Error?
            guard let parsed = self.dictionary(fromJson: response, error: &parseError) else {
                completion(nil, FlutterError(code: "RPC_PARSE_ERROR",
                                             message: parseError?.localizedDescription ?? "Failed to parse RPC response",
                                             details: response))
                return
            }
            // Protocol-level error (bad JSON, unknown method, missing params).
            if let envelopeError = parsed["error"] as? [String: Any] {
                let code = envelopeError["code"].map { self.objcDescription($0) } ?? "RPC_ERROR"
                completion(nil, FlutterError(code: code,
                                             message: envelopeError["message"].map { self.objcDescription($0) },
                                             details: envelopeError))
                return
            }
            guard let resultObj = parsed["result"] as? [String: Any] else {
                completion([:], nil)
                return
            }
            // Application-level failure is wrapped in the success envelope with success == false.
            let success = (resultObj["success"] as? NSNumber)?.boolValue ?? true
            if !success {
                let message = (resultObj["error"] ?? resultObj["message"]).map { self.objcDescription($0) }
                let code = resultObj["errorCode"].map { self.objcDescription($0) } ?? "SDK_ERROR"
                completion(nil, FlutterError(code: code,
                                             message: message ?? "RPC operation failed",
                                             details: resultObj))
                return
            }
            completion(resultObj, nil)
        }
    }

    /// Extracts the primitive/map value Dart expects from the RPC `result` object. The iOS RPC returns
    /// data under nested keys (e.g. {data:{version}}); Android returns the bare value, so we unwrap here
    /// to keep the Dart return shape identical across platforms. Setters/void calls return nil.
    private func unwrapValue(forMethod method: String, resultObj: [String: Any]?) -> Any? {
        let data = resultObj?["data"] as? [String: Any]
        switch method {
        case "getSdkVersion":
            return data?["version"]
        case "getAppsFlyerUID":
            return data?["uid"]
        case "isSessionReady":
            return data?["isSessionReady"]
        case "validateAndLogInAppPurchase":
            return data ?? [:]
        case "generateInviteLink":
            return data?["url"]
        default:
            // Void setters have no `data` and correctly return nil. Unlisted getters that return a
            // map payload surface it here instead of silently nil — scalar getters with named-key
            // nesting still need explicit cases until the RPC envelope matches Android's flat shape.
            return data
        }
    }

    // ============================================================================
    // Event forwarding (bridge -> af-events stream)
    // ============================================================================

    // Forwards the native AppsFlyerRPC envelope to the af-events stream without changing event names
    // or payloads, or buffers it until Dart subscribes (onListen). `AFRPCBridge.setEventHandler`
    // always enqueues here through `DispatchQueue.main.async` so delivery order matches Android's
    // always-post model; this method assumes it is already on the main thread when called.
    //
    // The buffer keeps the newest `kMaxPendingEvents` events: dropping the oldest bounds worst-case
    // memory while still replaying the events a late subscriber is most likely to act on.
    private func deliverEvent(_ argsJson: String) {
        if let eventSink = eventSink {
            eventSink(argsJson)
            return
        }
        pendingEvents.append(argsJson)
        if pendingEvents.count > kMaxPendingEvents {
            let dropped = pendingEvents.count - kMaxPendingEvents
            pendingEvents.removeFirst(dropped)
            NSLog(
                "AppsFlyer_FlutterPlugin: pending event buffer dropped %d oldest event(s); buffer cap is %d",
                dropped,
                kMaxPendingEvents
            )
        }
    }

    private func flushPendingEvents() {
        guard !pendingEvents.isEmpty, let eventSink = eventSink else {
            return
        }
        let pending = pendingEvents
        pendingEvents.removeAll()
        for args in pending {
            eventSink(args)
        }
    }

    // ============================================================================
    // JSON helpers
    // ============================================================================

    private func jsonEnvelope(forMethod method: String, params: NSDictionary?) -> String? {
        return jsonString(from: ["method": method, "params": params ?? NSDictionary()])
    }

    private func jsonString(from object: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func dictionary(fromJson json: String, error: inout Error?) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch let jsonError {
            error = jsonError
            return nil
        }
    }

    private func stringParam(_ params: NSDictionary, key: String) -> String? {
        return params[key] as? String
    }

    /// Reproduces `[NSString stringWithFormat:@"%@", value]` for values coming out of JSON, so that
    /// numeric RPC error codes keep the exact spelling the Objective-C implementation produced.
    private func objcDescription(_ value: Any) -> String {
        if let string = value as? String {
            return string
        }
        return String(describing: value as AnyObject)
    }

}

// ============================================================================
// Lifecycle forwarding (AppDelegate + UIScene). AppsFlyerAttribution queues early links and sends
// them through AppsFlyerRPC after initialize completes.
//
// Every selector below is spelled out explicitly: Swift would otherwise derive `application:open:…`
// style selectors from the Swift names, which UIKit and Flutter never call. The parameter types
// stay Objective-C shaped (`[AnyHashable: Any]`, optional where the caller may pass nil) so option
// dictionaries keep their NSString keys and reach AppsFlyerAttribution unchanged.
// ============================================================================

extension AppsflyerSdkPlugin {

    @objc(application:didFinishLaunchingWithOptions:)
    public func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any]) -> Bool {
        guard !launchOptions.isEmpty else {
            return false
        }
        let jsonSafeOptions = NSMutableDictionary()
        for (key, value) in launchOptions {
            let stringKey = String(describing: key as AnyObject)
            if let url = value as? URL {
                jsonSafeOptions[stringKey] = url.absoluteString
            } else if JSONSerialization.isValidJSONObject([value]) {
                jsonSafeOptions[stringKey] = value
            }
        }
        // Fire-and-forget: native `handleLaunchOptions:` only sets a pending-deeplink flag and has
        // no dependency on `initialize`. It must run before `registerSessionReadyListener`, which
        // Dart registers after `init()` — forwarding here satisfies that earlier than caching did.
        executeJson(forMethod: "handleLaunchOptions",
                    params: ["launchOptions": jsonSafeOptions]) { _, _ in }
        return false
    }

    // Spelled with the protocol's own Swift name (`open:`) because Objective-C selector
    // `application:openURL:options:` may only be provided by the declaration that satisfies the
    // `FlutterApplicationLifeCycleDelegate` requirement. The typed option keys are unwrapped back to
    // their raw strings so the payload matches the NSDictionary the Objective-C code forwarded.
    public func application(_ application: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        var rawOptions: [AnyHashable: Any] = [:]
        for (key, value) in options {
            rawOptions[key.rawValue] = value
        }
        AppsFlyerAttribution.shared().handleOpenUrl(url, options: rawOptions)
        return false
    }

    @objc(application:openURL:sourceApplication:annotation:)
    public func application(_ application: UIApplication,
                            openURL url: URL,
                            sourceApplication: String?,
                            annotation: Any?) -> Bool {
        AppsFlyerAttribution.shared().handleOpenUrl(url,
                                                    sourceApplication: sourceApplication,
                                                    annotation: annotation)
        return false
    }

    // UIApplicationDelegate requires restorationHandler; attribution only forwards webpageURL to RPC
    // (AppsFlyer SDK ignores the handler too). Handoff/UI restoration stays with the host app.
    // Uses the protocol's Swift name (`continue:`) for the same reason as `open:` above.
    public func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        AppsFlyerAttribution.shared().continueUserActivity(userActivity)
        return false
    }
}

// MARK: - FlutterSceneLifeCycleDelegate

// Registered through `addSceneDelegate:` when the host Flutter version provides it — see
// `addSceneDelegateIfSupported`. Flutter dispatches these by selector, never by conformance.
extension AppsflyerSdkPlugin {

    // UIScene-based URI-scheme deep links (iOS 13+, Flutter 3.41+ UIScene migration)
    @available(iOS 13.0, *)
    @objc(scene:openURLContexts:)
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        for context in URLContexts {
            forwardSceneOpenURLContext(context)
        }
        return false
    }

    // Cold-start deep links delivered via UISceneConnectionOptions (iOS 13+)
    @available(iOS 13.0, *)
    @objc(scene:willConnectToSession:options:)
    public func scene(_ scene: UIScene,
                      willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        for context in connectionOptions?.urlContexts ?? [] {
            forwardSceneOpenURLContext(context)
        }
        for activity in connectionOptions?.userActivities ?? [] {
            if activity.activityType == NSUserActivityTypeBrowsingWeb {
                AppsFlyerAttribution.shared().continueUserActivity(activity)
            }
        }
        return false
    }

    // UIScene-based Universal Links (iOS 13+)
    @available(iOS 13.0, *)
    @objc(scene:continueUserActivity:)
    public func scene(_ scene: UIScene, continueUserActivity userActivity: NSUserActivity) -> Bool {
        AppsFlyerAttribution.shared().continueUserActivity(userActivity)
        return false
    }

    @available(iOS 13.0, *)
    private func forwardSceneOpenURLContext(_ context: UIOpenURLContext) {
        var opts: [AnyHashable: Any] = [:]
        if let sourceApplication = context.options.sourceApplication {
            opts = [UIApplication.OpenURLOptionsKey.sourceApplication.rawValue: sourceApplication]
        }
        AppsFlyerAttribution.shared().handleOpenUrl(context.url, options: opts)
    }
}
