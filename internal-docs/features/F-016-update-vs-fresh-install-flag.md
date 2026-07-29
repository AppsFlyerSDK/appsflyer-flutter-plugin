---
id: F-016
name: Update vs. Fresh-Install Flag
type: sdkCore
platform: android
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Attribution logic needs to distinguish "this session came from a brand-new install" versus "this session came from an app that was just updated" — misclassifying updates as new installs would corrupt install-attribution counts. `setIsUpdate` tells the native SDK explicitly that the current launch follows an update, which the SDK factors into its session/attribution logic on Android.

---

## Trigger
Called by the host app at startup, before `startSDK()`, after it has determined (typically by comparing a persisted last-known app version against the current one) that this launch follows an update.

---

## Call Chain
Generic RPC, Android-gated in Dart (no-op on iOS).

```
AppsflyerSdk.setIsUpdate(isUpdate)                                    [lib/src/appsflyer_sdk.dart]
  → Platform.isAndroid ? _executeRpc('setIsUpdate', {isUpdate}) : no-op
    → af-api "executeRpc" {method:'setIsUpdate', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setIsUpdate(isUpdate)  [android/.../AppsflyerSdkPlugin.java]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setIsUpdate(bool)` — `Platform.isAndroid`-guarded |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | generic `setIsUpdate` dispatch over `AppsFlyerRpcHandler` |

---

## Input / Output
| | |
|--|--|
| **Input** | `isUpdate` (bool). RPC param key `isUpdate`. |
| **Output** | `void` — fire-and-forget. No-op on iOS (Dart-guarded, no RPC dispatched). |

---

## Tests
No dedicated test in `test/appsflyer_sdk_test.dart`. The method is `Platform.isAndroid`-gated, so on the Dart test host it would be a no-op.

---

## Known Limitations
- **Android-only** and Dart-guarded: calling it on iOS dispatches nothing.
- No enforced ordering relative to `initSdk()`/`startSDK()` — the SDK's expectation (set before the first session) is not validated by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F016["F-016 · Update vs. Fresh-Install Flag"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
