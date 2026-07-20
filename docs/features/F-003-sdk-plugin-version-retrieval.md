---
id: F-003
name: SDK/Plugin Version Retrieval
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Support and QA need a reliable way to answer "which native AppsFlyer SDK build, and which Flutter plugin build, is actually running in this app?" `getSDKVersion()` surfaces the native SDK's own version string (useful for diagnosing SDK-side bugs against AppsFlyer's release notes), while `getVersionNumber()` surfaces the Flutter plugin wrapper's own version. Without these, bug reports and support tickets would rely on the app's `pubspec.yaml`/podspec pin, which does not confirm what was actually compiled into the running binary.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called on demand by host app code — typically diagnostic/support tooling, debug menus, or logging at startup.

---

## Call Chain
```
AppsflyerSdk.getSDKVersion()                                          [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("getSDKVersion")
    → Android: AppsflyerSdkPlugin.onMethodCall("getSDKVersion") → getSdkVersion(result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().getSdkVersion()
    → iOS: AppsflyerSdkPlugin.handleMethodCall("getSDKVersion") → getSDKVersion:result:   [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [[AppsFlyerLib shared] getSDKVersion]

AppsflyerSdk.getVersionNumber()                                       [lib/src/appsflyer_sdk.dart]
  → returns AppsflyerConstants.PLUGIN_VERSION (pure Dart constant, no channel call)   [lib/src/appsflyer_constants.dart]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `getSDKVersion()` (async, native round-trip), `getVersionNumber()` (sync, local constant) |
| `lib/src/appsflyer_constants.dart` | `PLUGIN_VERSION` constant returned by `getVersionNumber()` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `getSdkVersion(result)` — proxies `AppsFlyerLib.getInstance().getSdkVersion()` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `getSDKVersion:result:` — proxies `[AppsFlyerLib shared] getSDKVersion]` |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `getSDKVersion()` → `Future<String?>` — the native AppsFlyer SDK's own version string. `getVersionNumber()` → `String` — the Flutter plugin's hardcoded version constant (synchronous, no native call). |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check getSDKVersion call` (line 192) asserts the mocked channel receives `getSDKVersion`. No test exists for `getVersionNumber()` (trivial, but untested).

---

## Known Limitations
- `AppsflyerConstants.PLUGIN_VERSION` in Dart (`lib/src/appsflyer_constants.dart`) is hardcoded to `"6.17.9"`, while `pubspec.yaml`'s package version, Android's `AppsFlyerConstants.PLUGIN_VERSION`, and iOS's `kAppsFlyerPluginVersion` are all `"6.18.0"`. `getVersionNumber()` therefore returns a stale value one release behind the actual plugin version and the value the native layer reports upstream to AppsFlyer via `setPluginInfo`/`setPluginInfoWith:` (see F-001). This is a manual-bump constant with no single source of truth or CI check tying it to `pubspec.yaml`.
- `getVersionNumber()` reports the *plugin's* version, not the native SDK's version — the naming similarity to `getSDKVersion()` is a common source of confusion for integrators.

---

## Dependencies
```mermaid
flowchart LR
    F003["F-003 · SDK/Plugin Version Retrieval"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
