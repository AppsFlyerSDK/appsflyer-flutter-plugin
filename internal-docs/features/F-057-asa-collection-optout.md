---
id: F-057
name: ASA (Apple Search Ads) Collection Opt-out
type: sdkCore
platform: ios
status: active
last_verified: 2026-07-15
depends_on: ["F-001"]
---

## Business Purpose
The native iOS SDK automatically queries Apple's Search Ads Attribution API (ASA) to enrich attribution data for installs originating from Apple Search Ads campaigns. Some apps — for privacy/compliance reasons, or because they don't run Apple Search Ads campaigns and want to avoid the extra API call/data collection — need to opt out of this automatic collection at init time. `disableCollectASA` is the init-time switch that turns it off before the SDK starts.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Set once by the host app as part of `AppsFlyerOptions` (or the raw options `Map`) passed to the `AppsflyerSdk` constructor, and applied during `initSdk()`/`initSdkWithCall:`, before the SDK starts. iOS only — read and applied only when `Platform.isIOS` on the Dart side, and only has a corresponding native code path on iOS.

---

## Call Chain
```
AppsFlyerOptions(disableCollectASA: true)                              [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk(...)                                          [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions(options) / _validateMapOptions(options)
      → if Platform.isIOS is NOT required here — value is copied unconditionally on both platforms:
        validatedOptions[AppsflyerConstants.DISABLE_COLLECT_ASA] = options.disableCollectASA   (line 63-66 / 125-128)
      → _methodChannel.invokeMethod("initSdk", validatedOptions)
        → iOS: AppsflyerSdkPlugin.handleMethodCall("initSdk") → initSdkWithCall:result:   [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
          → disableCollectASA = call.arguments[afDisableCollectASA] (as NSNumber → BOOL)   (line 836-840)
          → [AppsFlyerLib shared].disableCollectASA = disableCollectASA                    (line 848)
        → Android: AppsflyerSdkPlugin.initSdk(call, result) — value is never read; no `DISABLE_COLLECT_ASA`
          constant exists in `AppsFlyerConstants.java` and Apple Search Ads has no Android equivalent
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.disableCollectASA` (`bool?`, optional named constructor param) |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions` / `_validateMapOptions` — copies `disableCollectASA` into the validated options map unconditionally (no `Platform.isIOS` guard on the Dart validation side) if non-null |
| `lib/src/appsflyer_constants.dart` | `DISABLE_COLLECT_ASA = "disableCollectASA"` — shared Dart↔native key |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsflyerSdkPlugin.h` | `#define afDisableCollectASA @"disableCollectASA"` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `initSdkWithCall:result:` — parses the flag and sets `[AppsFlyerLib shared].disableCollectASA` (lines 836–848) |
| `doc/BasicIntegration.md`, `doc/API.md` | Document `disableCollectASA` as "Opt-out of the Apple Search Ads attributions" |

---

## Input / Output
| | |
|--|--|
| **Input** | `disableCollectASA` (`bool?`) via `AppsFlyerOptions` or the equivalent Map key, read at init time only |
| **Output** | `void` — sets a property on the native iOS SDK singleton before `start`; no confirmation returned to Dart. On Android the value is silently discarded. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s `check initSdk call` test only asserts that the `"initSdk"` method is invoked; it does not construct `AppsFlyerOptions` with `disableCollectASA` set, nor assert the resulting map contains the key, nor exercise the iOS-only native path (Dart `flutter test` runs on the host OS, not `Platform.isIOS`).

---

## Known Limitations
- Android-side handling doesn't exist at all: there is no `DISABLE_COLLECT_ASA` constant in `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` and the Android `initSdk(call, result)` never reads the key — this is expected (ASA is an Apple-only concept) but is not documented anywhere as an explicit no-op; a host app setting `disableCollectASA: true` gets no feedback that it had no effect on Android.
- Dart-side validation (`_validateAFOptions`) copies `disableCollectASA` into `validatedOptions` unconditionally (not gated behind `Platform.isIOS` like `timeToWaitForATTUserAuthorization` and `appId` are) — inconsistent with how the same method gates other iOS-only fields.
- No getter exists to confirm whether ASA collection is currently disabled after init.
- One-directional: once set (or left at the default `NO`/false) at init time, there is no runtime API in this plugin to toggle it after the SDK has started.

---

## Dependencies
```mermaid
flowchart LR
    F057["F-057 · ASA Collection Opt-out"]:::sdkCore -->|"applied only during"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
