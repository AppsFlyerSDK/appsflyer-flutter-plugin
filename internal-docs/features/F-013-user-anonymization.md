---
id: F-013
name: User Anonymization (Opt-out logging)
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
When a specific user opts out of tracking (via an in-app privacy setting or a "do not track" requirement), the app needs to tell AppsFlyer to stop logging identifiable data for that user without tearing down the whole SDK. `anonymizeUser` flips this opt-out flag on the native SDK. Without it, the only alternative would be the much blunter `stop()` (F-017), which disables the SDK entirely.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.anonymizeUser(...)` whenever the current user's tracking-opt-out preference changes — a settings toggle, or a privacy-compliance check at login. Apply the setting before `start()` when the first session must already be anonymized.

---

## Call Chain
`anonymizeUser` is an awaitable RPC setter available on both platforms.

```
AppsFlyerSdk.anonymizeUser(shouldAnonymize)                           [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('anonymizeUser', {'shouldAnonymize': shouldAnonymize})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.anonymizeUser(shouldAnonymize)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → [AppsFlyerLib shared] anonymize flag
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `anonymizeUser(bool shouldAnonymize)` — awaitable RPC setter |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Forwards `anonymizeUser` through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Forwards `anonymizeUser` through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `shouldAnonymize` (`bool`) — `true` anonymizes logging for the current user, `false` restores normal logging. RPC param key `shouldAnonymize`. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or request timeout. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the cross-platform RPC mapping test that `anonymizeUser(true)` dispatches RPC method `anonymizeUser` with `{'shouldAnonymize': true}`. Error conversion is covered generically by the test asserting that a `PlatformException` becomes an `AppsFlyerException` on the shared RPC path.

---

## Known Limitations
- The flag is process/runtime state on the shared native SDK, not tied to a customer user ID. It remains in effect across foreground cycles until `anonymizeUser(false)` is called; the app must reapply its desired value after a cold start.
- No way to read back the current anonymization state from Dart.

---

## Dependencies
```mermaid
flowchart LR
    F013["F-013 · User Anonymization (Opt-out logging)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
