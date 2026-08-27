---
id: F-002
name: SDK Start (session launch)
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: ["F-001"]
---

## Business Purpose
`AppsFlyerSdk.start` asks the native SDK 7 to send a session (Launch). The application is expected to call it from the callback registered with `registerSessionReadyListener`; neither Dart nor the RPC layer checks readiness before forwarding the call. Keeping initialization and session start separate lets the application defer a session for consent, Customer User ID, ATT, or another application condition.

---

## Trigger
The host app calls `registerSessionReadyListener(onReady)` after `init()` and awaits `start()` for each invocation of that callback. Configuration setters that must affect the Launch are applied before `start()`.

---

## Call Chain
`start` forwards the public `awaitResponse` flag to the native RPC layer without calling `isSessionReady`. Default `false` is fire-and-forget; `true` waits for the native request completion callback.

```
AppsFlyerSdk.registerSessionReadyListener(onReady)
  → _ensureEventsSubscribed() + _listeners.on('onSessionReady', …)
      (one callback slot, replaced on re-registration)
  → RPC 'registerSessionReadyListener'
    → native listener retained across foreground cycles
      → after configuration and launch deep-link processing complete or time out
        → native event 'onSessionReady' → EventChannel('af-events')
          → _AppsFlyerListenerRegistry.dispatch → onReady()

AppsFlyerSdk.isSessionReady()
  → RPC 'isSessionReady' → current native readiness boolean; unexpected null throws AppsFlyerException

AppsFlyerSdk.start({awaitResponse})                                   [lib/src/appsflyer_sdk.dart]
  → no Dart or RPC readiness check; the app is responsible for session-ready ordering
  → _invokeVoidRpc('start', {'awaitResponse': awaitResponse})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → awaitResponse true:  AppsFlyerLib.start(requestListener), bounded by the bridge's own 5s wait
          (awaitCallback / START_TIMEOUT_MILLIS)
        → awaitResponse false: AppsFlyerLib.start() with no request listener; RPC returns immediate success
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → awaitResponse true:  AppsFlyerLib.startWithCompletionHandler, bounded by the bridge's own 10s wait
          (SDKTimeoutHelper.defaultTimeout)
        → awaitResponse false: start without waiting for the completion handler
  → awaitResponse true: successful per-call reply completes Future<void>; PlatformException → AppsFlyerException
  → awaitResponse false: Future completes after native start returns and RPC reports immediate success

AppsFlyerSdk.unregisterSessionReadyListener()
  → RPC 'unregisterSessionReadyListener' → removes the native listener on both platforms
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `registerSessionReadyListener(onReady)`, the `OnSessionReady` typedef, and `start({bool awaitResponse = false})` |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Forwards `start` through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Forwards `start` through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | Listener registration/unregistration and readiness query take no arguments. `start` takes `awaitResponse` (`bool`, named, default `false`) — when `true`, wait for the native request callback; when `false`, return after the native fire-and-forget method returns and RPC reports immediate success. |
| **Output** | `registerSessionReadyListener()` and `unregisterSessionReadyListener()` return `Future<void>` after synchronous native registration state changes. `isSessionReady()` returns `Future<bool>`; an unexpected native null reply throws `AppsFlyerException` instead of being reported as `false`. The registered `onReady` callback is invoked once per foreground cycle. For `start()`, the default fire-and-forget completion does not prove a Launch was sent; `awaitResponse: true` completes on the native request callback or throws `AppsFlyerException` for native errors/timeouts. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies registration/unregistration RPC names, the `isSessionReady` return value, delivery of a payload-free `onSessionReady` event to the registered callback, that re-registering replaces the callback rather than adding a second one (so `start()` cannot be issued twice for one readiness event), that unregistering drops it, the default `start()` payload, and explicit `awaitResponse: true`. Error tests verify shared `PlatformException` to `AppsFlyerException` conversion. Native session-readiness lifecycle tests live in the Android and iOS SDK repositories; no Flutter device test covers a full background-to-foreground cycle.

---

## Known Limitations
- The app must keep a session-ready listener registered and call `start()` for every invocation of its callback.
- The plugin holds one session-ready callback, replaced on re-registration; there is no public stream, so two parts of an app cannot each trigger `start()` for the same readiness event. A readiness event arriving before `registerSessionReadyListener()` has run is held by `_AppsFlyerListenerRegistry` and replayed when the listener registers. After the listener has been registered once, a readiness event arriving while it is unregistered is logged and dropped instead.
- `isSessionReady()` is a snapshot, not a substitute for the per-cycle callback. The native readiness state resets when the app backgrounds, while the registered listener is retained until explicitly unregistered or the native state is torn down. On Android the listener outlives the Flutter engine, because the `AppsFlyerRpcHandler` holding it is process-scoped (`AppsFlyerRpcBridge`); the Dart callback does not, so a recreated engine must call `registerSessionReadyListener()` again.
- Neither the Flutter layer nor either RPC handler calls `isSessionReady` before forwarding `start`; correct ordering is the application's responsibility.
- Android requires both prior initialization and a registered native session-ready listener. If either is missing, the native SDK logs a warning and returns without sending a Launch. With `awaitResponse: false`, Dart still receives the RPC's immediate success; with `awaitResponse: true`, no native callback arrives and the Android RPC reports its 5-second timeout. Android also ignores repeated `start()` calls within the same native session.
- iOS `start` does not itself enforce session-ready listener registration or readiness. Its public native contract instructs callers to invoke it from the session-ready listener.
- The Flutter layer does not synthesize a session or retry a failed native request.
- When `awaitResponse` is `true`, the RPC bridge bounds its wait for the native completion callback with its own internal timeout (Android: 5s `START_TIMEOUT_MILLIS`; iOS: 10s `SDKTimeoutHelper.defaultTimeout`) — not exposed to or configurable from Dart, and not equal between platforms for the same Dart API. If the native request legitimately takes longer, the bridge reports a timeout `AppsFlyerException` even though the request may still succeed natively afterward; neither bridge reports that later outcome. Error codes are native-bridge-owned and are not identical across platforms.
- Both timeout values live outside this plugin (`appsflyer-android-sdk` plugin_bridge / `appsflyer.sdk.ios` AppsFlyerRPC); aligning or exposing them would require a change in those repositories.
- When `awaitResponse` is `false`, delivery success or failure is not surfaced to Dart.

---

## Dependencies
```mermaid
flowchart LR
    F002["F-002 · SDK Start"]:::sdkCore -->|"requires initialized SDK"| F001["F-001 · SDK Initialization"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
