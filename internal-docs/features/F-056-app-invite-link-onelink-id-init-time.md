---
id: F-056
name: App Invite Link OneLink ID (init-time)
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-29
depends_on: ["F-028"]
---

## Business Purpose
Apps that already know their invite-link OneLink ID at build/config time (rather than resolving it dynamically at runtime) want to configure it once, as part of the same `AppsFlyerOptions`/init-options object used to configure the dev key, app ID, and other startup flags — avoiding a separate `setAppInviteOneLinkID` (F-028) call after `initSdk()`. The `appInviteOneLink` init option sets this same underlying native OneLink ID during the init orchestration, so `generateInviteLink` (F-027) has a base link ready as soon as the SDK starts.

---

## Trigger
Runs once, during `initSdk()`, whenever the host app constructed its `AppsFlyerOptions` (or the equivalent options `Map`) with a non-null `appInviteOneLink` value.

---

## Call Chain
The `appInviteOneLink` value is validated and copied into the init options, then applied by the native init orchestration via the `setAppInviteOneLink` RPC (after the SDK is initialized, before the first session).
```
AppsFlyerOptions(appInviteOneLink: "...")                                        [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk()                                                       [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions(afOptions) / _validateMapOptions(mapOptions)            [lib/src/appsflyer_sdk.dart]
      → validatedOptions[AppsflyerConstants.APP_INVITE_ONE_LINK] = appInviteOneLink   // wire key "appInviteOneLink"
    → _executeRpc('init', validatedOptions)   // MethodChannel af-api → executeRpc
      → Android: AppsflyerSdkPlugin.executeRpc → initFromRpc(params, result)      [android/.../AppsflyerSdkPlugin.java]
        → reads appInviteOneLink → after init(), if non-empty: executeRpcSync("setAppInviteOneLink", {oneLinkId})
      → iOS: AppsflyerSdkPlugin.executeRpc → initFromRpc:params:result:           [ios/.../AppsflyerSdkPlugin.m]
        → reads afInviteOneLink → adds {method:"setAppInviteOneLink", params:{oneLinkId}} to the init RPC sequence (if non-empty)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.appInviteOneLink` — optional `String?` init-time field |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions()` / `_validateMapOptions()` copy `appInviteOneLink` into `validatedOptions` under the wire key `"appInviteOneLink"`; `initSdk()` sends it as part of the `init` RPC |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initFromRpc()` reads the value and, if non-empty, runs the `setAppInviteOneLink` RPC after `init` and before `start` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `initFromRpc:result:` appends a `setAppInviteOneLink` entry to the ordered init RPC sequence when `afInviteOneLink` is non-empty |

---

## Input / Output
| | |
|--|--|
| **Input** | `AppsFlyerOptions.appInviteOneLink` (`String?`) or `mapOptions["appInviteOneLink"]`, consumed only during `initSdk()` |
| **Output** | Sets the same underlying native OneLink ID that `setAppInviteOneLinkID` (F-028) sets at runtime, via the `setAppInviteOneLink` RPC — no dedicated success/failure callback exists for the init-time path |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s `check initSdk call` exercises the general `initSdk()` path using `mapOptions: {'afDevKey': ...}` — no test sets or asserts `appInviteOneLink`/`APP_INVITE_ONE_LINK` specifically, on either the Dart validation logic or either native handler.

---

## Known Limitations
- **Assert-only validation**: `_validateAFOptions`/`_validateMapOptions` only `assert(appInviteOneLink is String)` when non-null — `assert` is stripped in profile/release builds, so a wrong type passed via the untyped `Map` init path would not be caught outside debug mode.
- **Silently overwritten by a later runtime call**: F-056 (init-time) and F-028 (`setAppInviteOneLinkID`, runtime) both write the same native property, so calling `setAppInviteOneLinkID` after `initSdk()` silently overrides the init-time value.
- **Empty/null value is skipped**: the native init orchestration only issues the `setAppInviteOneLink` RPC when the value is non-empty; an empty string is a no-op.
- No way to detect, from Dart, whether the init-time value was actually applied (no callback/confirmation, unlike the explicit `setAppInviteOneLinkID` callback in F-028).

---

## Dependencies
```mermaid
flowchart LR
    F056["F-056 · App Invite Link OneLink ID (init-time)"]:::oneLinkAndGrowth
    F028["F-028 · App Invite OneLink ID Configuration"]:::oneLinkAndGrowth
    F056 -->|"shares same native OneLink-ID property, last write wins"| F028
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
