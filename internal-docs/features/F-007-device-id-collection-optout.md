---
id: F-007
name: Android ID Collection Opt-out
type: sdkCore
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`setCollectAndroidID` controls whether the Android SDK may collect Android ID as a fallback identifier. Apps must choose the value that matches their distribution context, consent basis, privacy disclosures, and current Google Play policy rather than assuming the identifier is always appropriate.

---

## Trigger
Called by the host app during startup configuration, before `start()`, when it needs to declare its Android ID collection posture (typically apps shipping with Google Play Services present). Dart and RPC do not enforce this ordering.

---

## Call Chain
`setCollectAndroidID` is a generic RPC, Android-gated in Dart (Android ID is an Android-only identifier, so on iOS the call is ignored with a logged warning).

```
AppsFlyerSdk.setCollectAndroidID(isCollect)                           [lib/src/appsflyer_sdk.dart]
  → not Android: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setCollectAndroidID', {isCollect})
    → af-api "executeRpc" {method:'setCollectAndroidID', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setCollectAndroidID(isCollect)  [android/.../AppsflyerSdkPlugin.kt]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCollectAndroidID(bool)` — guarded by an Android platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | generic `setCollectAndroidID` RPC dispatch over `AppsFlyerRpcHandler` |

---

## Input / Output
| | |
|--|--|
| **Input** | `isCollect` (`bool`) — `true` enables Android ID collection and `false` opts out. The native SDK's stored opt-in flag defaults to `false`. RPC param key `isCollect`. |
| **Output** | `Future<void>` — on Android, completes after RPC handling and the synchronous native setter invocation; it does not confirm that an Android ID was subsequently collected. RPC or bridge failures are exposed as `AppsFlyerException`. On iOS the call is ignored with a logged warning and never reaches the channel. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setCollectAndroidID(true)` dispatches RPC method `setCollectAndroidID` with `{'isCollect': true}`. `'platform-only void calls are ignored without reaching the native RPC'` asserts that calling it on iOS dispatches no RPC. The Flutter tests do not verify whether the native SDK subsequently collects an Android ID.

---

## Known Limitations
- **Android-only** and Dart-guarded: calling it on iOS is a logged no-op rather than a silent one — a warning is printed and no RPC is dispatched.
- Calling the API before `start()` is recommended configuration ordering but is not enforced by Dart or RPC.

---

## Dependencies
```mermaid
flowchart LR
    F007["F-007 · Android ID Collection Opt-out"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
