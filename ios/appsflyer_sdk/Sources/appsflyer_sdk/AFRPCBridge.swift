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
    /// running several engines (add-to-app, `FlutterEngineGroup`, multi-scene) hands the slot to
    /// whichever instance registered last. Recording the owner lets a detaching instance tell
    /// whether the installed handler is still its own, mirroring the `this.sink === sink` guard in
    /// `AppsFlyerEventBus.detach`. Weak so a released plugin cannot keep itself alive here.
    @MainActor private static weak var eventHandlerOwner: AnyObject?

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
            eventHandlerOwner = owner
            AppsFlyerRPCBridge.shared.setEventHandler { jsonEvent in
                DispatchQueue.main.async { handler(jsonEvent) }
            }
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
