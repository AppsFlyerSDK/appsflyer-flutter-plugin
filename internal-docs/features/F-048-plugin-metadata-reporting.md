---
id: F-048
name: Plugin Metadata Reporting to Native SDK
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-001"]
---

## Business Purpose
AppsFlyer maintains multiple wrapper SDKs on top of its native Android/iOS SDKs (Flutter, React Native, Cordova, Unity, etc.). `setPluginInfo`/`setPluginInfoWith:` tells the native SDK "this install is running through the Flutter plugin, version X" so AppsFlyer's backend, support tooling, and internal dashboards can attribute traffic/bugs to the correct wrapper and version rather than treating every install as a bare native integration. This has no effect on attribution logic or app behavior — it is purely an internal identification tag with no host-app-facing API.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Runs automatically and unconditionally on every SDK initialization (`initSdk`/`initSdkWithCall:`), on both platforms. There is no Dart API, option, or flag that controls or disables it — it always fires as a side effect of `AppsflyerSdk.initSdk()`.

---

## Call Chain
```
AppsflyerSdk.initSdk(...)                                              [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("initSdk", validatedOptions)
    → Android: AppsflyerSdkPlugin.onMethodCall("initSdk") → initSdk(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → new PluginInfo(Plugin.FLUTTER, AppsFlyerConstants.PLUGIN_VERSION)           (line 1095)
        → AppsFlyerLib.getInstance().setPluginInfo(pluginInfo)                     (line 1096)
      → AppsFlyerLib.getInstance().init(afDevKey, gcdListener, mContext)            (called right after)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("initSdk") → initSdkWithCall:result: [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [[AppsFlyerLib shared] setPluginInfoWith:AFSDKPluginFlutter
                                    pluginVersion:kAppsFlyerPluginVersion
                                additionalParams:nil]                              (line 857)
      → [[AppsFlyerLib shared] start] (unless manualStart)
```

---

## Files
| File | Role |
|------|------|
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initSdk(call, result)` — builds `PluginInfo(Plugin.FLUTTER, AppsFlyerConstants.PLUGIN_VERSION)` and calls `setPluginInfo` (lines 1095–1096), immediately before `instance.init(...)` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` | `PLUGIN_VERSION = "6.18.0"` — the version string reported to the native SDK |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `initSdkWithCall:result:` — calls `setPluginInfoWith:AFSDKPluginFlutter pluginVersion:kAppsFlyerPluginVersion additionalParams:nil` (line 857) |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsflyerSdkPlugin.h` | `#define kAppsFlyerPluginVersion @"6.18.0"` — the version string reported on iOS |

`Plugin`, `PluginInfo` (Android, package `com.appsflyer.internal.platform_extension`) and `AFSDKPluginFlutter` (iOS, an enum/constant defined inside the native `AppsFlyerLib` framework) are external types supplied by the native AppsFlyer SDK dependency, not defined in this repo.

---

## Input / Output
| | |
|--|--|
| **Input** | None from the host app — no Dart parameter exists. The reported values (`Plugin.FLUTTER` / `AFSDKPluginFlutter`, and the hardcoded native `PLUGIN_VERSION` constant) are fixed by the plugin's native-layer source code. |
| **Output** | `void` — fire-and-forget call into the native SDK; nothing is returned to Dart. The metadata is transmitted internally by the native SDK to AppsFlyer's backend as part of its own request payloads. |

---

## Tests
No dedicated test found. The call is not exposed as a distinct Dart method (it is embedded inside native `initSdk`/`initSdkWithCall:` handlers), so it cannot be observed or asserted from `test/appsflyer_sdk_test.dart`'s mocked `MethodChannel`, which only sees the single `"initSdk"` method invocation and its arguments map — `setPluginInfo`/`setPluginInfoWith:` happen entirely on the native side afterward.

---

## Known Limitations
- The reported plugin version is duplicated independently in three places and has drifted: Dart's `AppsflyerConstants.PLUGIN_VERSION` (`lib/src/appsflyer_constants.dart`) is `"6.17.9"`, while Android's `AppsFlyerConstants.PLUGIN_VERSION` and iOS's `kAppsFlyerPluginVersion` are both `"6.18.0"` (matching `pubspec.yaml`). Since this feature only ever reads the **native**-side constants, the value AppsFlyer's backend actually receives is `6.18.0`, not the value `AppsflyerSdk.getVersionNumber()` (F-003) returns to the host app — there is no single source of truth tying the three together.
- No public Dart API exists to inspect, override, or disable the reported plugin metadata; it is entirely internal and always fires on init with no error handling or confirmation callback.
- On Android, `setPluginInfo` is called before `instance.init(...)`; if `init` throws or the SDK is torn down and re-initialized, there is no guard against calling `setPluginInfo` more than once with a stale instance.

---

## Dependencies
```mermaid
flowchart LR
    F048["F-048 · Plugin Metadata Reporting to Native SDK"]:::sdkCore -->|"runs inside the same native call as"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
