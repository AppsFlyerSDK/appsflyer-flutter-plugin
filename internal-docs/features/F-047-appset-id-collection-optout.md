---
id: F-047
name: AppSet ID Collection Opt-out (Android)
type: sdkCore
platform: android
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Starting with SDK v6.17.0, the Android SDK automatically collects the Google Play "AppSet ID" (a privacy-friendlier alternative to the Advertising ID for app-scoped or developer-scoped device identification). Some apps need to opt out of this automatic collection entirely for privacy-compliance reasons even though it isn't as sensitive as GAID. `disableAppSetId()` is the only way to turn that automatic collection off.

---

## Trigger
Called by the host app during startup configuration, on Android only, whenever it needs to opt out of automatic AppSet ID collection.

---

## Call Chain
The Dart method is guarded by `Platform.isAndroid`, so it is a no-op on iOS (no RPC is dispatched). AppSet ID is a Google Play Services / Android-only concept.

```
AppsflyerSdk.disableAppSetId()                                         [lib/src/appsflyer_sdk.dart]
  → if (Platform.isAndroid) _executeRpc('disableAppSetId')
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'disableAppSetId', params:{}})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler   [android/.../AppsflyerSdkPlugin.java]
        → AppsFlyerLib.getInstance().disableAppSetId()
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `disableAppSetId()` — no-argument, guarded by `Platform.isAndroid` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | RPC bridge entry (`executeRpc`) routing `disableAppSetId` to `AppsFlyerRpcHandler` |
| `doc/api-reference.md` | Documents the method as **"Android Only!"**, "Disables AppSet ID collection." |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check disableAppSetId call` asserts the mocked `af-api` channel receives `executeRpc` with method `disableAppSetId` (host tests exercise the Android branch).

---

## Known Limitations
- **Android-only** (by design — AppSet ID is a Google Play Services concept with no iOS equivalent). The Dart method is guarded by `Platform.isAndroid`, so on iOS it silently does nothing.
- There is no way to re-enable AppSet ID collection once disabled within the same process — the call is one-directional (opt-out only), matching the native SDK's own API shape.
- No getter to confirm whether AppSet ID collection is currently disabled.

---

## Dependencies
```mermaid
flowchart LR
    F047["F-047 · AppSet ID Collection Opt-out (Android)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
