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
Generic RPC with no Dart platform gate. Off Android the call is still dispatched, and the native RPC layer answers that it does not implement the method.

```
AppsFlyerSdk.setIsUpdate(bool isUpdate)                               [lib/src/appsflyer_sdk.dart]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
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
| `lib/src/appsflyer_sdk.dart` | `setIsUpdate(bool isUpdate)` — dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic `setIsUpdate` dispatch through the Android RPC handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `isUpdate` (`bool`), sent under the RPC param key `isUpdate`. |
| **Output** | On Android, `Future<void>` completes after RPC validation and the synchronous SDK setter invocation; validation or bridge failures throw `AppsFlyerException`, with no native completion callback or timeout. On any non-Android platform the call is still dispatched and throws `AppsFlyerException` once the native RPC layer reports the method as unavailable. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setIsUpdate(true)` dispatches RPC method `setIsUpdate` with params `{'isUpdate': true}` on the Android-configured instance. `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'` asserts that `setIsUpdate` on iOS still dispatches the `setIsUpdate` RPC rather than being short-circuited, and `'PlatformException becomes AppsFlyerException'` covers the shared error conversion. The tests inject the platform through `AppsFlyerSdk.private(..., platform: ...)`, so both platforms are exercisable on the Dart test host.

---

## Known Limitations
- **Android-only**: calling `setIsUpdate` on iOS is not short-circuited in Dart — the call reaches the native RPC layer, which does not implement the method, so the `Future` completes with an `AppsFlyerException`. Cross-platform call sites must branch on `Platform.isAndroid` or catch the exception.
- No enforced ordering relative to `init()`/`start()` — the SDK's expectation that the flag is set before the first session is not validated by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F016["F-016 · Update vs. Fresh-Install Flag"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
