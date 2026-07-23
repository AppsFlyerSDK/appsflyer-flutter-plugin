---
id: F-016
name: Update vs. Fresh-Install Flag
type: sdkCore
platform: android
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Attribution logic needs to distinguish "this session came from a brand-new install" versus "this session came from an app that was just updated" — misclassifying updates as new installs would corrupt install-attribution counts and inflate campaign performance numbers. `setIsUpdate` lets the app tell the native SDK explicitly that the current launch follows an update (e.g. detected by comparing a stored app-version marker against the running version), which the SDK factors into its session/attribution logic on Android.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app at startup, after the app has itself determined (typically by comparing a persisted last-known app version against the current one) that this launch follows an update rather than a fresh install.

---

## Call Chain
```
AppsflyerSdk.setIsUpdate(isUpdate)                                       [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setIsUpdate", {'isUpdate': isUpdate})
    → Android: AppsflyerSdkPlugin.onMethodCall("setIsUpdate") → setIsUpdate(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setIsUpdate(isUpdate)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setIsUpdate") → (no-op)                      [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setIsUpdate(bool)` — platform-agnostic Dart API (no `Platform.isAndroid` guard) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setIsUpdate` native handler — forwards to `AppsFlyerLib.getInstance().setIsUpdate(isUpdate)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `handleMethodCall:` contains an empty `else if([@"setIsUpdate" isEqualToString:call.method]){ }` branch — matched but intentionally does nothing |

---

## Input / Output
| | |
|--|--|
| **Input** | `isUpdate` (bool) |
| **Output** | Android: `void`, fire-and-forget, and `result.success(null)` is called so the Dart-side `Future` (if awaited) would resolve normally. iOS: the method-call branch matches but never calls `result(...)` at all. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setIsUpdate call` (line 136) asserts the mocked channel receives `setIsUpdate` with `isUpdate: true`, exercising only the Dart-to-channel dispatch (the mock test harness cannot and does not distinguish Android's real handling from iOS's no-op).

---

## Known Limitations
- **iOS is a documented no-op**: in `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m`'s `handleMethodCall:`, the `"setIsUpdate"` branch is matched (`if([@"setIsUpdate" isEqualToString:call.method]){ }`) but its body is empty — no native AppsFlyer API is called, and critically, `result(...)` is never invoked either. Since this branch matches inside an `if/else if` chain, control does not fall through to the trailing `result(FlutterMethodNotImplemented)` — the platform channel's pending reply for `setIsUpdate` on iOS is simply never resolved. Dart's `setIsUpdate()` is `void` and does not await the result, so this is silent to the caller today, but the update-vs-install distinction this API is meant to convey has **no effect whatsoever on iOS** — only Android attribution logic actually receives it.
- The Dart API has no platform guard and gives no compile-time or runtime signal that calling `setIsUpdate` on iOS is a no-op; an integrator relying on it cross-platform would reasonably but incorrectly assume parity with Android.
- No enforced ordering relative to `initSdk()` — the native SDK's own documentation-level expectation (call before init so the flag is available for the very first session) is not validated by either native handler.

---

## Dependencies
```mermaid
flowchart LR
    F016["F-016 · Update vs. Fresh-Install Flag"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
