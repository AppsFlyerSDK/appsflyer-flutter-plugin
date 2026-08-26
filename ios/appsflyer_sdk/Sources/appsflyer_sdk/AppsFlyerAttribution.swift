//
//  AppsFlyerAttribution.swift
//  flutter-appsflyer
//
//  Created by Amit Kremer on 11/02/2021.
//
//  Interim queue-and-forward layer for UIKit deep-link entry points. Native Swift should call the
//  typed lifecycle API in AppsFlyerRPC directly once the upstream lifecycle-callback wrapper lands;
//  this class (and its JSON round-trip through AFRPCBridge) is then expected to be removed.

import Foundation
import os

@objc(AppsFlyerAttribution)
public class AppsFlyerAttribution: NSObject {

    /// A deep-link RPC request captured before `initialize` completed. `params` holds the already
    /// JSON-safe Foundation payload that is handed to the RPC layer unchanged.
    private struct PendingRequest {
        let method: String
        let params: [String: Any]
    }

    private static let sharedInstance = AppsFlyerAttribution()
    private static let log = OSLog(subsystem: "com.appsflyer.appsflyer_sdk",
                                   category: "AppsFlyerAttribution")

    private var isBridgeReady = false
    private var pendingRequests: [PendingRequest] = []
    /// The plugin instance that last called `markBridgeReady(markedBy:)`. Used to reset queue state
    /// on engine detach without affecting a live second engine in multi-engine hosts.
    private weak var bridgeReadyOwner: AnyObject?

    @objc(shared)
    public class func shared() -> AppsFlyerAttribution {
        return sharedInstance
    }

    @objc(continueUserActivity:)
    public func continueUserActivity(_ userActivity: NSUserActivity?) {
        guard let userActivity = userActivity, let webpageURL = userActivity.webpageURL else {
            return
        }
        // UIKit annotates `activityType` as non-null, so the original `?: NSUserActivityTypeBrowsingWeb`
        // fallback survives only as an explicit Optional widening.
        let activityType = Optional(userActivity.activityType) ?? NSUserActivityTypeBrowsingWeb
        executeOrQueue(method: "continueUserActivity", params: [
            "url": webpageURL.absoluteString,
            "activityType": activityType
        ])
    }

    @objc(handleOpenUrl:options:)
    public func handleOpenUrl(_ url: URL?, options: [AnyHashable: Any]?) {
        guard let url = url else {
            return
        }
        executeOrQueue(method: "handleOpenUrl", params: [
            "url": url.absoluteString,
            "options": jsonSafeOptions(from: options)
        ])
    }

    /// Called from `AppsflyerSdkPlugin` after `init()` completes so detach can reset this singleton
    /// only for the engine that marked it ready. Not exposed on the `@objc` surface: a parameterless
    /// variant would open the gate without recording an owner and `resetBridgeStateIfOwned(by:)` could
    /// not clear stale state on engine detach.
    func markBridgeReady(markedBy owner: AnyObject) {
        onMain { [self] in
            applyBridgeReady(owner: owner)
        }
    }

    /// Clears queue state when the owning Flutter engine detaches. No-op for other engines.
    func resetBridgeStateIfOwned(by owner: AnyObject) {
        onMain { [self] in
            guard bridgeReadyOwner === owner else {
                return
            }
            bridgeReadyOwner = nil
            isBridgeReady = false
            pendingRequests.removeAll()
        }
    }

    private func applyBridgeReady(owner: AnyObject) {
        bridgeReadyOwner = owner
        isBridgeReady = true
        let requests = pendingRequests
        pendingRequests.removeAll()
        for request in requests {
            execute(method: request.method, params: request.params)
        }
    }

    private func executeOrQueue(method: String, params: [String: Any]) {
        onMain { [self] in
            if isBridgeReady {
                execute(method: method, params: params)
            } else {
                pendingRequests.append(PendingRequest(method: method, params: params))
            }
        }
    }

    /// Serializes `isBridgeReady` / `pendingRequests` on the main queue. UIKit entry points are
    /// already main-thread; `markBridgeReady` is normalized there by `AFRPCBridge`, but the public
    /// `@objc` surface must not rely on caller thread affinity. Interim until the RPC lifecycle
    /// wrapper absorbs this queue.
    private func onMain(_ body: @escaping () -> Void) {
        if Thread.isMainThread {
            body()
        } else {
            DispatchQueue.main.async(execute: body)
        }
    }

    private func jsonSafeOptions(from options: [AnyHashable: Any]?) -> [String: Any] {
        guard let options = options, !options.isEmpty else {
            return [:]
        }
        var safe: [String: Any] = [:]
        safe.reserveCapacity(options.count)
        for (key, value) in options {
            guard let stringKey = key as? String else {
                continue
            }
            if let safeValue = jsonSafeValue(value) {
                safe[stringKey] = safeValue
            }
        }
        return safe
    }

    private func jsonSafeValue(_ value: Any?) -> Any? {
        guard let value = value, !(value is NSNull) else {
            return nil
        }
        if value is String || value is NSNumber {
            return value
        }
        if value is NSDictionary || value is NSArray {
            return JSONSerialization.isValidJSONObject(value) ? value : nil
        }
        return JSONSerialization.isValidJSONObject([value]) ? value : nil
    }

    private func execute(method: String, params: [String: Any]) {
        let envelope: [String: Any] = ["method": method, "params": params]
        guard JSONSerialization.isValidJSONObject(envelope),
              let data = try? JSONSerialization.data(withJSONObject: envelope, options: []),
              let json = String(data: data, encoding: .utf8) else {
            Self.logError("Attribution RPC envelope serialization failed for method \(method)")
            return
        }
        AFRPCBridge.executeJson(json) { response in
            Self.logRpcFailureIfNeeded(method: method, response: response)
        }
    }

    private static func logRpcFailureIfNeeded(method: String, response: String) {
        guard let data = response.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logError("Attribution RPC response parse failed for method \(method)")
            return
        }
        if let envelopeError = parsed["error"] as? [String: Any] {
            let code = (envelopeError["code"] as? String) ?? "RPC_ERROR"
            let message = (envelopeError["message"] as? String) ?? "unknown"
            logError("Attribution RPC protocol error for \(method): \(code) — \(message)")
            return
        }
        guard let resultObj = parsed["result"] as? [String: Any] else {
            return
        }
        let success = (resultObj["success"] as? NSNumber)?.boolValue ?? true
        if success {
            return
        }
        let message = (resultObj["error"] as? String)
            ?? (resultObj["message"] as? String)
            ?? "SDK operation failed"
        logError("Attribution RPC SDK error for \(method): \(message)")
    }

    private static func logError(_ message: String) {
        os_log(.error, log: log, "%{public}@", message)
    }
}
