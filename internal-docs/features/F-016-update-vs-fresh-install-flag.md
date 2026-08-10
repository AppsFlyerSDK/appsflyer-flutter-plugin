---
id: F-016
name: Update vs. Fresh-Install Flag
type: sdkCore
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Attribution logic needs to distinguish "this session came from a brand-new install" from "this session came from an app that was just updated" — misclassifying updates as new installs would corrupt install-attribution counts. `setIsUpdate` tells the native SDK explicitly that the current launch follows an update, which the SDK factors into its session and attribution logic on Android.

---

## Trigger
Awaited by the host app at startup, before `start()`, after it has determined (typically by comparing a persisted last-known app version against the current one) that this launch follows an update.

---

## Call Chain
Generic RPC, Android-gated in Dart. Off Android the call is ignored with a logged warning, so no RPC is dispatched.

```
AppsFlyerSdk.setIsUpdate(bool isUpdate)                               [lib/src/appsflyer_sdk.dart]
  → not Android: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setIsUpdate', {'isUpdate': isUpdate})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.setIsUpdate(isUpdate)
  → successful reply completes Future<void>
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setIsUpdate(bool isUpdate)` — guarded by an Android platform check |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic `setIsUpdate` dispatch through the Android RPC handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `isUpdate` (`bool`), sent under the RPC param key `isUpdate`. |
| **Output** | On Android, `Future<void>` completes after RPC validation and the synchronous SDK setter invocation; validation or bridge failures throw `AppsFlyerException`, with no native completion callback or timeout. On any non-Android platform the call is ignored with a logged warning and no RPC is dispatched. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setIsUpdate(true)` dispatches RPC method `setIsUpdate` with params `{'isUpdate': true}` on the Android-configured instance. `'platform-only void calls are ignored without reaching the native RPC'` asserts that `setIsUpdate` on iOS dispatches no RPC, and `'PlatformException becomes AppsFlyerException'` covers the shared error conversion. The tests inject the platform through `AppsFlyerSdk.private(..., platform: ...)`, so both branches are exercisable on the Dart test host.

---

## Known Limitations
- **Android-only**: calling `setIsUpdate` on iOS is a logged no-op rather than a silent one — a warning is printed, no RPC is dispatched, and the `Future` completes normally.
- No enforced ordering relative to `init()`/`start()` — the SDK's expectation that the flag is set before the first session is not validated by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F016["F-016 · Update vs. Fresh-Install Flag"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
