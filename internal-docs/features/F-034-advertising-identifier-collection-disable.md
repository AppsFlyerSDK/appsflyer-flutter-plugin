---
id: F-034
name: Advertising Identifier Collection Disable
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Privacy regulations (GDPR, CCPA) and platform policy changes increasingly require apps to be able to fully opt out of collecting device advertising identifiers (GAID/AAID/OAID on Android, IDFA on iOS) rather than just anonymizing individual users. `setDisableAdvertisingIdentifiers` gives the host app a single cross-platform switch for this, usable both as a one-time init-time option and as a runtime toggle. Without it, an app could not comply with a user's advertising-ID opt-out request without disabling the SDK entirely (F-017).

---

## Trigger
Two distinct trigger points exist: (1) at SDK init time, via the `disableAdvertisingIdentifier` field on `AppsFlyerOptions`/init map, applied once during the `init` orchestration; (2) at any later point, via the standalone `setDisableAdvertisingIdentifiers(bool disable)` runtime method.

---

## Call Chain
Both paths converge on the `setDisableAdvertisingIdentifiers` RPC. The Dart runtime method splits the param key per platform: Android expects `isDisable`, iOS expects `disable`.

```
# Init-time path
AppsflyerSdk._validateAFOptions / _validateMapOptions                 [lib/src/appsflyer_sdk.dart]
  → validatedOptions[DISABLE_ADVERTISING_IDENTIFIER] = options.disableAdvertisingIdentifier ?? false
  → _executeRpc('init', validatedOptions)
    → Android: AppsflyerSdkPlugin init orchestration                 [android/.../AppsflyerSdkPlugin.java]
      → if (advertiserIdDisabled) executeRpcSync('setDisableAdvertisingIdentifiers', {'isDisable': true}) before init()  [only applies `true`]
    → iOS: AppsFlyerRPCBridge applies the flag during init when disableAdvertisingIdentifier == true

# Runtime path
AppsflyerSdk.setDisableAdvertisingIdentifiers(disable)                 [lib/src/appsflyer_sdk.dart]
  → _executeRpc('setDisableAdvertisingIdentifiers', Platform.isIOS ? {'disable': disable} : {'isDisable': disable})
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'setDisableAdvertisingIdentifiers', params})
      → Android: executeRpc → dispatchRpc → AppsFlyerRpcHandler → native setDisableAdvertisingIdentifiers(disable)
      → iOS: executeRpc → AppsFlyerRPCBridge → [[AppsFlyerLib shared] setDisableAdvertisingIdentifier:disable]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableAdvertisingIdentifiers(bool disable)` runtime API (splits `isDisable`/`disable` per platform); `_validateAFOptions`/`_validateMapOptions` init-time option handling |
| `lib/src/appsflyer_options.dart` | `disableAdvertisingIdentifier` field on `AppsFlyerOptions` |
| `lib/src/appsflyer_constants.dart` | `DISABLE_ADVERTISING_IDENTIFIER` string key |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | init orchestration applies `setDisableAdvertisingIdentifiers` with `isDisable:true` before `init()`; runtime calls routed through `executeRpc` → `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | RPC bridge entry (`executeRpc`) forwarding `setDisableAdvertisingIdentifiers` to `AppsFlyerRPCBridge` |
| `doc/installation-guide.md` | Documents the field as "Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA." |

---

## Input / Output
| | |
|--|--|
| **Input** | Init-time: `disableAdvertisingIdentifier` (bool?, defaults to `false` if unset). Runtime: `disable` (bool) — `true` disables collection of GAID/AAID/OAID (Android) or IDFA (iOS). |
| **Output** | `void` — fire-and-forget in both paths; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setDisableAdvertisingIdentifiers call` asserts the mocked `af-api` channel receives `executeRpc` with method `setDisableAdvertisingIdentifiers`. The init-time option path (`disableAdvertisingIdentifier` inside `init`) is not separately asserted — the init test only checks the `init` RPC was dispatched, not the validated map's contents.

---

## Known Limitations
- **Init-time and runtime paths are asymmetric on Android.** The init orchestration only dispatches `setDisableAdvertisingIdentifiers` with `isDisable:true` when the flag is `true`; if it's `false` (the default), it does nothing (relies on the native SDK default rather than explicitly sending `false`). The standalone runtime method, by contrast, always sends the exact boolean passed (both `true` and `false`).
- The Dart runtime method sends different param keys per platform (`isDisable` on Android, `disable` on iOS); the two native bridges consume their respective keys. A future bridge change to either key would silently break one platform without a compile-time check.
- No getter exists to read back the current disabled state from Dart.

---

## Dependencies
```mermaid
flowchart LR
    F034["F-034 · Advertising Identifier Collection Disable"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
