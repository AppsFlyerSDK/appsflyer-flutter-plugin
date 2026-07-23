---
id: F-059
name: Debug Logging Toggle
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-001"]
---

## Business Purpose
During integration and QA, developers need verbose native SDK logging (request/response payloads, session lifecycle, error detail) to diagnose why attribution or events aren't showing up as expected. `showDebug` is the init-time switch that turns this on. AppsFlyer explicitly warns this must not ship to production, since verbose logs can leak internal request data into device logs.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Set once by the host app as part of `AppsFlyerOptions` (or the raw options `Map`), defaulting to `false`, and applied during `initSdk()`/`initSdkWithCall:` on both platforms before the native SDK starts.

---

## Call Chain
```
AppsFlyerOptions(showDebug: true)                                       [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk(...)                                          [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions(options) / _validateMapOptions(options)
      → validatedOptions[AF_IS_DEBUG] = options.showDebug ?? false      (line 94-96 / 158-161)
      → _methodChannel.invokeMethod("initSdk", validatedOptions)
        → Android: AppsflyerSdkPlugin.onMethodCall("initSdk") → initSdk(call, result)   [android/.../AppsflyerSdkPlugin.java]
          → isDebug = call.argument(AF_IS_DEBUG)                                    (line 1087)
          → if (isDebug) { instance.setLogLevel(AFLogger.LogLevel.DEBUG);
                            instance.setDebugLog(true); }
            else { instance.setDebugLog(false); }                                   (lines 1088-1093)
        → iOS: AppsflyerSdkPlugin.handleMethodCall("initSdk") → initSdkWithCall:result:  [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
          → isDebugValue = call.arguments[afIsDebug]                                (line 805)
          → [AppsFlyerLib shared].isDebug = isDebug                                 (line 813)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.showDebug` (`bool`, defaults to `false`) |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions` / `_validateMapOptions` — always writes `AF_IS_DEBUG` into the validated options map, defaulting to `false` if unset |
| `lib/src/appsflyer_constants.dart` | `AF_IS_DEBUG = "isDebug"` — shared Dart↔native key |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initSdk(call, result)` — toggles `AppsFlyerLib.getInstance().setLogLevel(...)` and `.setDebugLog(...)` (lines 1087-1093) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` | `AF_IS_DEBUG = "isDebug"` — native Android mirror of the Dart key |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsflyerSdkPlugin.h` | `#define afIsDebug @"isDebug"` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `initSdkWithCall:result:` — sets `[AppsFlyerLib shared].isDebug` directly (lines 805, 813) |
| `doc/BasicIntegration.md`, `doc/API.md`, `doc/Testing.md` | Document `showDebug` and warn "do not release to production with this parameter set to `true`" |

---

## Input / Output
| | |
|--|--|
| **Input** | `showDebug` (`bool`, defaults to `false`) via `AppsFlyerOptions` or the equivalent Map key |
| **Output** | `void` — toggles native SDK verbose logging as a side effect of init; no confirmation returned to Dart. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s `check initSdk call` test uses `mapOptions: {'afDevKey': ...}` with no `isDebug` key set, so it only exercises the default-`false` path implicitly and never asserts the value of `AF_IS_DEBUG` in the resulting arguments map, nor exercises the `true` branch on either platform.

---

## Known Limitations
- Android and iOS implement the flag differently: Android makes two separate native calls when enabling (`setLogLevel(AFLogger.LogLevel.DEBUG)` **and** `setDebugLog(true)`) but only one call when disabling (`setDebugLog(false)` — the log level is never explicitly reset), while iOS sets a single `isDebug` property that presumably controls both internally. This asymmetry is not tested and could produce subtly different logging verbosity between platforms if the native SDKs' internal defaults ever diverge.
- No public Dart getter exists to read back the current debug-logging state after init.
- The Dart-side null-coalescing comment (`// ignore: unnecessary_null_comparison`) on `options.showDebug != null` in `_validateAFOptions` suggests this check is dead code, since `showDebug` is a non-nullable `bool` with a default value in `AppsFlyerOptions` and can never be `null` at that call site.
- This is an init-time-only toggle — there is no runtime API in this plugin to turn debug logging on/off after `initSdk()` has already run.

---

## Dependencies
```mermaid
flowchart LR
    F059["F-059 · Debug Logging Toggle"]:::sdkCore -->|"applied only during"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
