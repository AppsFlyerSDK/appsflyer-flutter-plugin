---
id: F-059
name: Debug Logging Toggle
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: ["F-001"]
---

## Business Purpose
During integration and QA, developers need verbose native SDK logging (request/response payloads, session lifecycle, error detail) to diagnose why attribution or events aren't showing up as expected. `showDebug` is the init-time switch that turns this on. AppsFlyer explicitly warns this must not ship to production, since verbose logs can leak internal request data into device logs.

---

## Trigger
Set once by the host app as part of `AppsFlyerOptions` (or the raw options `Map`), defaulting to `false`, and applied during the `init` orchestration on both platforms before the native SDK starts.

---

## Call Chain
```
AppsFlyerOptions(showDebug: true)                                       [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk(...)                                          [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions / _validateMapOptions
      → validatedOptions[AF_IS_DEBUG] = options.showDebug ?? false
      → _executeRpc('init', validatedOptions)
        → MethodChannel "af-api".invokeMethod('executeRpc', {method:'init', params})
          → Android: AppsflyerSdkPlugin.initFromRpc(...)               [android/.../AppsflyerSdkPlugin.java]
            → if (isDebug) executeRpcSync('setLogLevel', {logLevel:"DEBUG"})
            → executeRpcSync('setDebugLog', {isDebug})   [dispatched before the init RPC]
          → iOS: AppsFlyerRPCBridge init orchestration applies the debug flag to the native SDK   [ios/.../AppsflyerSdkPlugin.m]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.showDebug` (`bool`, defaults to `false`) |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions` / `_validateMapOptions` — always writes `AF_IS_DEBUG` into the validated options map, defaulting to `false` if unset |
| `lib/src/appsflyer_constants.dart` | `AF_IS_DEBUG = "isDebug"` — shared Dart↔native key |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initFromRpc(...)` — dispatches `setLogLevel` (DEBUG) and `setDebugLog` RPCs before `init` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` | `AF_IS_DEBUG = "isDebug"` — native Android mirror of the Dart key |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Init orchestration applies the debug flag to the native SDK via the RPC bridge |
| `doc/installation-guide.md`, `doc/api-reference.md`, `doc/testing-and-troubleshooting.md` | Document `showDebug` and warn "do not release to production with this parameter set to `true`" |

---

## Input / Output
| | |
|--|--|
| **Input** | `showDebug` (`bool`, defaults to `false`) via `AppsFlyerOptions` or the equivalent Map key |
| **Output** | `void` — toggles native SDK verbose logging as a side effect of init; no confirmation returned to Dart. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s init test uses `mapOptions: {'afDevKey': ...}` with no `isDebug` key set, so it only exercises the default-`false` path implicitly and never asserts the value of `AF_IS_DEBUG` in the resulting `init` RPC params, nor exercises the `true` branch on either platform.

---

## Known Limitations
- Android and iOS apply the flag differently: Android's init orchestration dispatches two RPCs when enabling (`setLogLevel` DEBUG **and** `setDebugLog`) but only `setDebugLog(false)` when disabling (the log level is never explicitly reset), while iOS applies a single debug flag via the bridge. This asymmetry is not tested and could produce subtly different logging verbosity between platforms if the native SDKs' internal defaults ever diverge.
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
