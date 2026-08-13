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
`setCollectAndroidID` is a generic RPC with no Dart platform gate (Android ID is an Android-only identifier, so on iOS the native RPC layer answers that it does not implement the method and the call throws `AppsFlyerException`).

```
AppsFlyerSdk.setCollectAndroidID(isCollect)                           [lib/src/appsflyer_sdk.dart]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('setCollectAndroidID', {isCollect})
    → af-api "executeRpc" {method:'setCollectAndroidID', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setCollectAndroidID(isCollect)  [android/.../AppsflyerSdkPlugin.kt]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCollectAndroidID(bool)` — dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | generic `setCollectAndroidID` RPC dispatch over `AppsFlyerRpcHandler` |

---

## Input / Output
| | |
|--|--|
| **Input** | `isCollect` (`bool`) — `true` enables Android ID collection and `false` opts out. The native SDK's stored opt-in flag defaults to `false`. RPC param key `isCollect`. |
| **Output** | `Future<void>` — on Android, completes after RPC handling and the synchronous native setter invocation; it does not confirm that an Android ID was subsequently collected. RPC or bridge failures are exposed as `AppsFlyerException`. On iOS the call still reaches the channel and throws `AppsFlyerException`, because the iOS RPC layer does not implement the method. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setCollectAndroidID(true)` dispatches RPC method `setCollectAndroidID` with `{'isCollect': true}`. `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'` asserts that calling it on iOS still dispatches the RPC, and `'platform-only setters surface the native error'` asserts that the resulting native failure reaches the caller as `AppsFlyerException`. The Flutter tests do not verify whether the native SDK subsequently collects an Android ID.

---

## Known Limitations
- **Android-only** but not Dart-gated: calling it on iOS reaches the native RPC layer, which does not implement the method, so the call throws `AppsFlyerException` instead of quietly doing nothing.
- Calling the API before `start()` is recommended configuration ordering but is not enforced by Dart or RPC.

---

## Dependencies
```mermaid
flowchart LR
    F007["F-007 · Android ID Collection Opt-out"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
