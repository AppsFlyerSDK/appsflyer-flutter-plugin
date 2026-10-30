//
//  AFRPCBridge.swift
//  appsflyer_sdk
//

import Foundation
import AppsFlyerRPC

/// The plugin's single point of contact with the `@MainActor`-isolated `AppsFlyerRPCBridge`, in both
/// directions: outbound RPC calls from the non-isolated contexts this plugin runs in (Flutter channel
/// handlers, `UIApplication` and `UIScene` delegate callbacks, engine detach), and inbound events.
///
/// All of those already run on the main thread, so `MainActor.assumeIsolated` keeps each call
/// synchronous — the request reaches the bridge before the channel handler returns, and the event
/// handler is attached before `init(messenger:)` returns — while turning that assumption into a
/// checked precondition. Hopping through `Task { @MainActor in }` instead would defer every call by
/// one main-actor turn, which the event-handler registration order and the `executeRpc` round trip
/// both rely on not happening.
///
/// Engine detach is the one caller that may release the plugin off the main thread, so a queue hop
/// covers it rather than tripping the precondition.
enum AFRPCBridge {

    /// Owner of the handler currently installed in `AppsFlyerRPCBridge`'s single global slot.
    ///
    /// The slot holds one handler per process while plugin instances are per engine, so a host
    /// running several engines (add-to-app, `FlutterEngineGroup`, multi-scene, a background engine
    /// reusing `GeneratedPluginRegistrant`) needs a rule for who holds it: plugin registration only
    /// takes a free slot (`setEventHandlerIfUnowned`), and Dart `init` claims it outright
    /// (`setEventHandler`). Recording the owner also lets a detaching instance tell whether the
    /// installed handler is still its own, mirroring the `this.sink === sink` guard in
    /// `AppsFlyerEventBus.detach`. Weak so a released plugin cannot keep itself alive here.
    @MainActor private(set) static weak var eventHandlerOwner: AnyObject?

    /// `completion` is always invoked on the main thread.
    ///
    /// AppsFlyerRPC documents main-thread delivery today, but the hop is one line inside a vendored
    /// binary framework. Normalizing here means a future RPC version that resumes off the main actor
    /// degrades into an extra queue hop instead of unsynchronized mutations in plugin state (for
    /// example `markBridgeReady` / `pendingEvents`) from an RPC completion.
    static func executeJson(_ jsonRequest: String, completion: @escaping (String) -> Void) {
        onMainActor {
            AppsFlyerRPCBridge.shared.executeJson(jsonRequest) { response in
                onMainActor { completion(response) }
            }
        }
    }

    /// `handler` is always invoked on the main thread, enqueued through `DispatchQueue.main.async`
    /// even when the caller is already on the main thread.
    ///
    /// A same-thread fast path would let a main-thread emission deliver synchronously ahead of an
    /// earlier background-thread emission still queued behind it, reordering af-events callbacks.
    /// Android always posts through `uiThreadHandler` for the same reason. `Task { @MainActor in }`
    /// is the wrong tool here — GCD's async enqueue is the documented strict-FIFO contract.
    static func setEventHandler(owner: AnyObject, _ handler: @escaping (String) -> Void) {
        onMainActor {
            installEventHandler(owner: owner, handler)
        }
    }

    /// No-op while another live instance holds the slot: registering the plugin on a secondary
    /// engine must not pull attribution and deep-link events away from the engine that owns them.
    static func setEventHandlerIfUnowned(owner: AnyObject, _ handler: @escaping (String) -> Void) {
        onMainActor {
            guard eventHandlerOwner == nil else {
                return
            }
            installEventHandler(owner: owner, handler)
        }
    }

    @MainActor private static func installEventHandler(owner: AnyObject,
                                                       _ handler: @escaping (String) -> Void) {
        eventHandlerOwner = owner
        AppsFlyerRPCBridge.shared.setEventHandler { jsonEvent in
            DispatchQueue.main.async { handler(jsonEvent) }
        }
    }

    /// No-op unless `owner` still holds the global slot: an engine tearing down must not silence the
    /// events of an engine that registered after it and is still alive.
    static func removeEventHandler(owner: AnyObject) {
        onMainActor {
            guard eventHandlerOwner === owner else {
                return
            }
            eventHandlerOwner = nil
            AppsFlyerRPCBridge.shared.removeEventHandler()
        }
    }

    private static func onMainActor(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated(body)
            }
        }
    }
}
