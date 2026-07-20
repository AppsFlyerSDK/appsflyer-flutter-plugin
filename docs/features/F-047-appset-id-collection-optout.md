---
id: F-047
name: AppSet ID Collection Opt-out (Android)
type: sdkCore
platform: android
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Starting with SDK v6.17.0, the Android SDK automatically collects the Google Play "AppSet ID" (a privacy-friendlier alternative to the Advertising ID for app-scoped or developer-scoped device identification). Some apps need to opt out of this automatic collection entirely for privacy-compliance reasons even though it isn't as sensitive as GAID. `disableAppSetId()` is the only way to turn that automatic collection off.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app during startup configuration, on Android only, whenever it needs to opt out of automatic AppSet ID collection.

---

## Call Chain
```
AppsflyerSdk.disableAppSetId()                                         [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("disableAppSetId")
    → Android: AppsflyerSdkPlugin.onMethodCall("disableAppSetId") → disableAppSetId(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().disableAppSetId()
```
No iOS branch exists for `"disableAppSetId"` in `ios/Classes/AppsflyerSdkPlugin.m`'s `handleMethodCall:` — the call falls through to `result(FlutterMethodNotImplemented)`. This is expected: AppSet ID is a Google Play Services / Android-only concept.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `disableAppSetId()` — no-argument, no `Platform.isAndroid` guard |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `disableAppSetId(call, result)`, line 1230 |
| `doc/API.md` | Documents the method as **"Android Only!"**, "Disables AppSet ID collection. Starting with v6.17.0, the SDK can automatically collect the AppSet ID." |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check disableAppSetId call` (line 362) asserts the mocked channel receives `'disableAppSetId'`. Test runs only through the Dart mock channel and cannot distinguish Android vs. iOS/no-op native behavior.

---

## Known Limitations
- **Android-only** (by design — AppSet ID is a Google Play Services concept with no iOS equivalent). Calling this from a Flutter app running on iOS results in a `MissingPluginException`/`FlutterMethodNotImplemented`, since the Dart API has no platform guard. Official docs correctly flag it "Android Only!" with a usage example wrapped in `if (Platform.isAndroid)`.
- There is no way to re-enable AppSet ID collection once disabled within the same process — the call is one-directional (opt-out only), matching the native SDK's own API shape.
- No getter to confirm whether AppSet ID collection is currently disabled.

---

## Dependencies
```mermaid
flowchart LR
    F047["F-047 · AppSet ID Collection Opt-out (Android)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
