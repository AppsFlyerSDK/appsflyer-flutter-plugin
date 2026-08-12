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

    static func executeJson(_ jsonRequest: String, completion: @escaping (String) -> Void) {
        onMainActor {
            AppsFlyerRPCBridge.shared.executeJson(jsonRequest, completion: completion)
        }
    }

    /// `handler` is always invoked on the main thread.
    ///
    /// AppsFlyerRPC hops each event onto the main actor before calling the handler, so today this
    /// resolves synchronously and preserves emission order. That hop is one line inside a vendored
    /// binary framework, though, and the emitter it wraps is `@Sendable` — the native SDK raises
    /// events from arbitrary threads. Normalizing here means a future RPC version that stops hopping
    /// degrades into an extra queue hop instead of an unsynchronized `pendingEvents` mutation and a
    /// `FlutterEventSink` call off the platform thread.
    static func setEventHandler(_ handler: @escaping (String) -> Void) {
        onMainActor {
            AppsFlyerRPCBridge.shared.setEventHandler { jsonEvent in
                onMainActor { handler(jsonEvent) }
            }
        }
    }

    static func removeEventHandler() {
        onMainActor {
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
