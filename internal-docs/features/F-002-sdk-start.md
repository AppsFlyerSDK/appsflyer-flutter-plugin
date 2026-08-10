---
id: F-002
name: SDK Start (session launch)
type: sdkCore
platform: both
status: active
last_verified: 2026-08-07
depends_on: ["F-001"]
---

## Business Purpose
`AppsFlyerSdk.start` asks the native SDK 7 to send a session (Launch). The application is expected to call it after `onSessionReady` emits; neither Dart nor the RPC layer checks readiness before forwarding the call. Keeping initialization and session start separate lets the application defer a session for consent, Customer User ID, ATT, or another application condition.

---

## Trigger
The host app subscribes to `onSessionReady`, calls `registerSessionReadyListener()` after `init()`, and awaits `start()` for each session-ready stream event. Configuration setters that must affect the Launch are applied before `start()`.

---

## Call Chain
`start` forwards the public `awaitResponse` flag to the native RPC layer without calling `isSessionReady`. Default `false` is fire-and-forget; `true` waits for the native request completion callback.

```
AppsFlyerSdk.start({awaitResponse})                                   [lib/src/appsflyer_sdk.dart]
  → no Dart or RPC readiness check; the app is responsible for onSessionReady ordering
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
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `onSessionReady`, `registerSessionReadyListener`, and `start({bool awaitResponse = false})` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Forwards `start` through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Forwards `start` through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `awaitResponse` (`bool`, named, default `false`) — when `true`, wait for the native request callback; when `false`, return after the native fire-and-forget method returns and RPC reports immediate success. |
| **Output** | `Future<void>`. With the default `awaitResponse: false`, completion does not prove that a Launch was sent or delivered. With `awaitResponse: true`, completes when the native request succeeds and throws `AppsFlyerException` for native errors or RPC timeouts. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `start()` defaults to `awaitResponse: false`, and that `start(awaitResponse: true)` forwards `true`. Error tests verify that a `PlatformException` is converted into `AppsFlyerException` through the shared RPC path.

---

## Known Limitations
- The app must keep the `onSessionReady` stream subscription active and call `start()` for every emitted foreground-cycle signal.
- Neither the Flutter layer nor either RPC handler calls `isSessionReady` before forwarding `start`; correct ordering is the application's responsibility.
- Android requires both prior initialization and a registered native session-ready listener. If either is missing, the native SDK logs a warning and returns without sending a Launch. With `awaitResponse: false`, Dart still receives the RPC's immediate success; with `awaitResponse: true`, no native callback arrives and the Android RPC reports its 5-second timeout. Android also ignores repeated `start()` calls within the same native session.
- iOS `start` does not itself enforce session-ready listener registration or readiness. Its public native contract instructs callers to invoke it from the session-ready listener.
- The Flutter layer does not synthesize a session or retry a failed native request.
- When `awaitResponse` is `true`, the RPC bridge bounds its wait for the native completion callback with its own internal timeout (Android: 5s `START_TIMEOUT_MILLIS`; iOS: 10s `SDKTimeoutHelper.defaultTimeout`) — not exposed to or configurable from Dart, and not equal between platforms for the same Dart API. If the native request legitimately takes longer (e.g. a slow network), the bridge reports a timeout `AppsFlyerException` (code `500`) even though the request may still succeed natively afterward; neither the bridge nor the plugin observes or reports that later outcome.
- Both timeout values live outside this plugin (`appsflyer-android-sdk` plugin_bridge / `appsflyer.sdk.ios` AppsFlyerRPC); aligning or exposing them would require a change in those repositories.
- When `awaitResponse` is `false`, delivery success or failure is not surfaced to Dart.

---

## Dependencies
```mermaid
flowchart LR
    F002["F-002 · SDK Start"]:::sdkCore -->|"requires initialized SDK"| F001["F-001 · SDK Initialization"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
