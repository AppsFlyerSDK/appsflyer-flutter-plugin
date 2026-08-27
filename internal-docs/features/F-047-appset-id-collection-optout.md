---
id: F-047
name: AppSet ID Collection Opt-out (Android)
type: sdkCore
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Starting with SDK v6.17.0, the Android SDK automatically collects the Google Play "AppSet ID" (a privacy-friendlier alternative to the Advertising ID for app-scoped or developer-scoped device identification). Some apps need to opt out of this automatic collection entirely for privacy-compliance reasons even though it isn't as sensitive as GAID. `disableAppSetId()` is the only way to turn that automatic collection off.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.disableAppSetId()` during startup configuration on Android, before `start()`, when it needs to opt out of automatic AppSet ID collection.

---

## Call Chain
`disableAppSetId` is an awaitable Android-only RPC call. AppSet ID is a Google Play Services concept, so only Android implements it; the Dart method itself is not platform-gated, so on any other platform the RPC is still dispatched and comes back as `AppsFlyerException`.

```
AppsFlyerSdk.disableAppSetId()                                        [lib/src/appsflyer_sdk.dart]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('disableAppSetId')
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params: {}})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.getInstance().disableAppSetId()
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `disableAppSetId()` — no-argument, awaitable, dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Forwards `disableAppSetId` through the Android RPC handler |
| `doc/api-reference.md` | Documents the method as Android-only, "Disables AppSet ID collection." |

---

## Input / Output
| | |
|--|--|
| **Input** | None. The RPC is dispatched with an empty `params` map. |
| **Output** | On Android, `Future<void>` completes after RPC validation and synchronous SDK invocation, with no native completion callback or timeout. Validation or bridge failures throw `AppsFlyerException`. Called off Android it dispatches the RPC anyway and throws `AppsFlyerException` once the native layer reports the method as unavailable. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the Android-only RPC mapping test that `disableAppSetId` dispatches RPC method `disableAppSetId` with empty params. `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'` calls `disableAppSetId()` on iOS and asserts that the `disableAppSetId` RPC is still dispatched rather than short-circuited in Dart.

---

## Known Limitations
- **Android-only** by design — AppSet ID is a Google Play Services concept with no iOS equivalent. Calling the method on iOS is not a no-op: the RPC is dispatched and the iOS layer's "unknown method" answer surfaces as `AppsFlyerException`, so shared startup code must branch on `Platform.isAndroid` or catch it.
- There is no way to re-enable AppSet ID collection once disabled within the same process — the call is one-directional (opt-out only), matching the native SDK's own API shape.
- No getter to confirm whether AppSet ID collection is currently disabled.

---

## Dependencies
```mermaid
flowchart LR
    F047["F-047 · AppSet ID Collection Opt-out (Android)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
