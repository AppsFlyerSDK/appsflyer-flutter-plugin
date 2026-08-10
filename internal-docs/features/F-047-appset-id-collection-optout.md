---
id: F-047
name: AppSet ID Collection Opt-out (Android)
type: sdkCore
platform: android
status: active
last_verified: 2026-08-05
depends_on: []
---

## Business Purpose
Starting with SDK v6.17.0, the Android SDK automatically collects the Google Play "AppSet ID" (a privacy-friendlier alternative to the Advertising ID for app-scoped or developer-scoped device identification). Some apps need to opt out of this automatic collection entirely for privacy-compliance reasons even though it isn't as sensitive as GAID. `disableAppSetId()` is the only way to turn that automatic collection off.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.disableAppSetId()` during startup configuration on Android, before `start()`, when it needs to opt out of automatic AppSet ID collection.

---

## Call Chain
`disableAppSetId` is an awaitable Android-only RPC call. AppSet ID is a Google Play Services concept, so the Dart method is Android-only: on any other platform the call is ignored with a logged warning instead of dispatching an RPC.

```
AppsFlyerSdk.disableAppSetId()                                        [lib/src/appsflyer_sdk.dart]
  → not Android: log warning, return (no RPC dispatched)
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
| `lib/src/appsflyer_sdk.dart` | `disableAppSetId()` — no-argument, awaitable, guarded by an Android platform check |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Forwards `disableAppSetId` through the Android RPC handler |
| `doc/api-reference.md` | Documents the method as Android-only, "Disables AppSet ID collection." |

---

## Input / Output
| | |
|--|--|
| **Input** | None. The RPC is dispatched with an empty `params` map. |
| **Output** | `Future<void>` completes when the native request succeeds and throws `AppsFlyerException` for native errors. Called off Android it completes without throwing: the call is ignored with a logged warning and no RPC is dispatched. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the Android-only RPC mapping test that `disableAppSetId` dispatches RPC method `disableAppSetId` with empty params. `'platform-only void calls are ignored without reaching the native RPC'` calls `disableAppSetId()` on iOS and asserts that no RPC method is dispatched.

---

## Known Limitations
- **Android-only** by design — AppSet ID is a Google Play Services concept with no iOS equivalent. Calling the method on iOS is a no-op, but a logged one — the plugin emits a `debugPrint` warning and dispatches no RPC.
- There is no way to re-enable AppSet ID collection once disabled within the same process — the call is one-directional (opt-out only), matching the native SDK's own API shape.
- No getter to confirm whether AppSet ID collection is currently disabled.

---

## Dependencies
```mermaid
flowchart LR
    F047["F-047 · AppSet ID Collection Opt-out (Android)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
