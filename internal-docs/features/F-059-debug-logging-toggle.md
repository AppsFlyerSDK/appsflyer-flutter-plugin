---
id: F-059
name: Debug Logging Toggle
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
During integration and QA, developers need verbose native SDK logging (request/response payloads, session lifecycle, error detail) to diagnose why attribution or events aren't showing up as expected. `enableDebug` is the switch that turns this on. AppsFlyer explicitly warns this must not ship to production, since verbose logs can leak internal request data into device logs.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.enableDebug(true)`. This is a standalone runtime call, not an init option: it may be called before `init()`, and must be called before `start()` so the first session is logged with the selected setting. Android integrations can additionally select a granular level with `setLogLevel(AFLogLevel)`.

---

## Call Chain
```
AppsFlyerSdk.enableDebug(enabled)                                     [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('isDebug', {'isDebug': enabled})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.setDebugLog(enabled)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
  → PlatformException is converted to AppsFlyerException

AppsFlyerSdk.setLogLevel(logLevel)                                    [Android only]
  → _invokeVoidRpc('setLogLevel', {'logLevel': logLevel.rpcValue})    // "NONE".."VERBOSE"
    → AppsFlyerRpcHandler → AppsFlyerLib.setLogLevel(...)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `enableDebug(bool enabled)` — maps to the `isDebug` RPC; `setLogLevel(AFLogLevel logLevel)` — Android-only, dispatched through RPC without a Dart platform check |
| `lib/src/appsflyer_constants.dart` | `AFLogLevel` (`none`, `error`, `warning`, `info`, `debug`, `verbose`) and its uppercase `rpcValue` |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | No per-method handler — generic `executeRpc` → `dispatchRpc` forwards `isDebug` / `setLogLevel` to `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | No per-method handler — generic `executeRpc` → `dispatchRpc` forwards `isDebug` to `AppsFlyerRPCBridge` |
| `doc/getting-started.md`, `doc/api-reference.md`, `doc/testing-and-troubleshooting.md` | Document `enableDebug` / `setLogLevel` and warn against releasing to production with debug logging enabled |

---

## Input / Output
| | |
|--|--|
| **Input** | `enabled` (`bool`) sent as the `isDebug` RPC parameter. Android only: `logLevel` (`AFLogLevel`) sent as its uppercase name. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK logging setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or timeout. Off Android, `setLogLevel` is still dispatched and throws `AppsFlyerException` once the native RPC layer reports the method as unavailable. |

---

## Tests
`test/appsflyer_sdk_test.dart`:
- `enableDebug maps to the isDebug RPC method` — asserts the RPC method is `isDebug` with params `{'isDebug': true}`.
- `maps every Android-only API` — asserts `setLogLevel` dispatches `setLogLevel` with the uppercase value for every `AFLogLevel`.
- `platform-only calls are forwarded to the native RPC instead of being swallowed in Dart` — asserts `setLogLevel(AFLogLevel.debug)` on iOS still dispatches the `setLogLevel` RPC.

---

## Known Limitations
- No public Dart getter exists to read back the current debug-logging state.
- Verbosity is not identical across platforms: `enableDebug` maps to the native Android `setDebugLog`, while a granular level requires the Android-only `setLogLevel`. iOS has no log-level equivalent in the RPC layer.
- The toggle is applied when the RPC is dispatched, so anything logged before the call (including a `start()` issued earlier) uses the previous setting.

---

## Dependencies
No required feature dependency. `enableDebug` may run before `init()` and should run before the first `start()` whose diagnostics are needed.
