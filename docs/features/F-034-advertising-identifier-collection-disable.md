---
id: F-034
name: Advertising Identifier Collection Disable
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Privacy regulations (GDPR, CCPA) and platform policy changes increasingly require apps to be able to fully opt out of collecting device advertising identifiers (GAID/AAID/OAID on Android, IDFA on iOS) rather than just anonymizing individual users. `setDisableAdvertisingIdentifiers` gives the host app a single cross-platform switch for this, usable both as a one-time init-time option and as a runtime toggle. Without it, an app could not comply with a user's advertising-ID opt-out request without disabling the SDK entirely (F-017).

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Two distinct trigger points exist: (1) at SDK init time, via the `disableAdvertisingIdentifier` field on `AppsFlyerOptions`/init map, applied once during `initSdk()`; (2) at any later point, via the standalone `setDisableAdvertisingIdentifiers(bool)` runtime method.

---

## Call Chain
```
# Init-time path
AppsflyerSdk._validateAFOptions / _validateMapOptions                 [lib/src/appsflyer_sdk.dart]
  → validatedOptions[DISABLE_ADVERTISING_IDENTIFIER] = options.disableAdvertisingIdentifier ?? false
  → _methodChannel.invokeMethod("initSdk", validatedOptions)
    → Android: AppsflyerSdkPlugin.initSdk(call, result)               [android/.../AppsflyerSdkPlugin.java]
      → if (advertiserIdDisabled) instance.setDisableAdvertisingIdentifiers(true)   [only applies `true`; never explicitly re-enables]
    → iOS: AppsflyerSdkPlugin.initSdkWithCall:result:                 [ios/Classes/AppsflyerSdkPlugin.m]
      → resolves selector `setDisableAdvertisingIdentifier:` via objc_msgSend runtime dispatch, only if disableAdvertisingIdentifier == true

# Runtime path
AppsflyerSdk.setDisableAdvertisingIdentifiers(isEnabled)               [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setDisableAdvertisingIdentifiers", isEnabled)
    → Android: AppsflyerSdkPlugin.onMethodCall("setDisableAdvertisingIdentifiers") → setDisableAdvertisingIdentifiers(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setDisableAdvertisingIdentifiers(isEnabled)   [handles both true and false explicitly]
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setDisableAdvertisingIdentifiers") → setDisableAdvertisingIdentifiers:result:            [ios/Classes/AppsflyerSdkPlugin.m]
      → [AppsFlyerLib shared] setDisableAdvertisingIdentifier:_isAdvertiserIdEnabled]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableAdvertisingIdentifiers(bool)` runtime API; `_validateAFOptions`/`_validateMapOptions` init-time option handling |
| `lib/src/appsflyer_options.dart` | `disableAdvertisingIdentifier` field on `AppsFlyerOptions` |
| `lib/src/appsflyer_constants.dart` | `DISABLE_ADVERTISING_IDENTIFIER` string key |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initSdk` (init-time, line 1072), `setDisableAdvertisingIdentifiers(call, result)` (runtime, line 564) |
| `ios/Classes/AppsflyerSdkPlugin.m` | `initSdkWithCall:result:` (init-time, uses `objc_msgSend` runtime dispatch to `setDisableAdvertisingIdentifier:`, line ~841-855), `setDisableAdvertisingIdentifiers:result:` (runtime, line 380) |
| `doc/BasicIntegration.md` | Documents the field as "Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA." |

---

## Input / Output
| | |
|--|--|
| **Input** | Init-time: `disableAdvertisingIdentifier` (bool?, defaults to `false` if unset). Runtime: `isEnabled` (bool) — `true` disables collection of GAID/AAID/OAID (Android) or IDFA (iOS). |
| **Output** | `void` — fire-and-forget in both paths; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setDisableAdvertisingIdentifiers call` (line 355) asserts the mocked channel receives `'setDisableAdvertisingIdentifiers'` with `capturedArguments == true`. The init-time option path (`disableAdvertisingIdentifier` inside `initSdk`) is not separately asserted — the `check initSdk call` test only checks that `'initSdk'` was invoked, not the validated map's contents.

---

## Known Limitations
- **Init-time and runtime paths are asymmetric on Android.** The `initSdk` handler only calls `setDisableAdvertisingIdentifiers(true)` if the flag is `true`; if it's `false` (the default), it does nothing (relies on native SDK default rather than explicitly calling `setDisableAdvertisingIdentifiers(false)`). The standalone runtime method, by contrast, always calls the native API with the exact boolean passed (both `true` and `false` explicitly).
- **iOS init-time path uses Objective-C runtime dispatch (`objc_msgSend` via `NSSelectorFromString`)** instead of calling the SDK method directly, apparently to guard against an SDK version where the selector might not exist (`respondsToSelector:` check). This is inconsistent with the runtime-toggle path (`setDisableAdvertisingIdentifiers:result:`), which calls `[AppsFlyerLib shared] setDisableAdvertisingIdentifier:]` directly — a version mismatch between the two could cause the init-time flag to silently no-op while the runtime toggle continues to work (or vice versa).
- No getter exists to read back the current disabled state from Dart.

---

## Dependencies
```mermaid
flowchart LR
    F034["F-034 · Advertising Identifier Collection Disable"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
