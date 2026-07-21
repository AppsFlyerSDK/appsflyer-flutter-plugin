---
id: F-056
name: App Invite Link OneLink ID (init-time)
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-028"]
---

## Business Purpose
Apps that already know their invite-link OneLink ID at build/config time (rather than resolving it dynamically at runtime) want to configure it once, as part of the same `AppsFlyerOptions`/init-options object used to configure the dev key, app ID, and other startup flags — avoiding a separate `setAppInviteOneLinkID` (F-028) call after `initSdk()`. The `appInviteOneLink` init option sets this same underlying native OneLink ID at SDK-initialization time, so `generateInviteLink` (F-027) has a base link ready as soon as the SDK starts.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Runs once, during `initSdk()`, whenever the host app constructed its `AppsFlyerOptions` (or the equivalent options `Map`) with a non-null `appInviteOneLink` value.

---

## Call Chain
```
AppsFlyerOptions(appInviteOneLink: "...")                                        [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk()                                                       [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions(afOptions) / _validateMapOptions(mapOptions)            [lib/src/appsflyer_sdk.dart]
      → validatedOptions[AppsflyerConstants.APP_INVITE_ONE_LINK] = appInviteOneLink
    → _methodChannel.invokeMethod("initSdk", validatedOptions)
      → Android: AppsflyerSdkPlugin.onMethodCall("initSdk") → initSdk(call, result)                          [android/.../AppsflyerSdkPlugin.java]
        → call.argument(AppsFlyerConstants.AF_APP_INVITE_ONE_LINK) → AppsFlyerLib.getInstance().setAppInviteOneLink(appInviteOneLink)   (only if non-null)
      → iOS: AppsflyerSdkPlugin.handleMethodCall("initSdk") → initSdkWithCall:result:                          [ios/Classes/AppsflyerSdkPlugin.m]
        → call.arguments[afInviteOneLink] → [AppsFlyerLib shared].appInviteOneLinkID = appInviteOneLink   (only if non-nil and not NSNull)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.appInviteOneLink` — optional `String?` init-time field |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions()` (lines ~56-61) and `_validateMapOptions()` (lines ~111-123) — copy `appInviteOneLink` into `validatedOptions[AppsflyerConstants.APP_INVITE_ONE_LINK]` under the wire key `"appInviteOneLink"`; `initSdk()` sends it as part of the `"initSdk"` method-channel call |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initSdk(call, result)` (~line 1100) reads `AppsFlyerConstants.AF_APP_INVITE_ONE_LINK` and calls `AppsFlyerLib.getInstance().setAppInviteOneLink(appInviteOneLink)` if non-null, **after** `instance.init(...)` but before `instance.start(activity)` |
| `ios/Classes/AppsflyerSdkPlugin.m` | `initSdkWithCall:result:` (~line 831) reads `afInviteOneLink` (`"appInviteOneLink"`) and sets `[AppsFlyerLib shared].appInviteOneLinkID` if non-nil and not `NSNull` |

---

## Input / Output
| | |
|--|--|
| **Input** | `AppsFlyerOptions.appInviteOneLink` (`String?`) or `mapOptions["appInviteOneLink"]`, consumed only during `initSdk()` |
| **Output** | Sets the same underlying native OneLink ID property that `setAppInviteOneLinkID` (F-028) sets at runtime (`AppsFlyerLib.getInstance()` on Android, `[AppsFlyerLib shared].appInviteOneLinkID` on iOS) — no dedicated success/failure callback exists for the init-time path |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s `check initSdk call` (line 93) exercises the general `initSdk()` path using `mapOptions: {'afDevKey': 'sdfhj2342cx'}` (set in `setUp()`, line 19) — no test sets or asserts `appInviteOneLink`/`APP_INVITE_ONE_LINK` specifically, on either the Dart validation logic or either native handler.

---

## Known Limitations
- **Assert-only validation**: both `_validateAFOptions` and `_validateMapOptions` in `lib/src/appsflyer_sdk.dart` only `assert(appInviteOneLink is String)` when non-null — `assert` is stripped in release (profile/release) Flutter builds, so a wrong type passed via the untyped `Map` init path would not be caught outside debug mode.
- **Silently overwritten by a later runtime call**: because F-056 (init-time) and F-028 (`setAppInviteOneLinkID`, runtime) both write to the exact same native property, calling `setAppInviteOneLinkID` after `initSdk()` completes silently overrides whatever was set via the `appInviteOneLink` init option, with no warning of the override.
- **Android sets it after `init()` but the codebase doesn't document why**: `AppsFlyerLib.getInstance().setAppInviteOneLink(appInviteOneLink)` is called after `instance.init(afDevKey, gcdListener, mContext)` and before `instance.start(activity)`; the ordering relative to `start()` is load-bearing for the native SDK but is not asserted or tested here.
- No way to detect, from Dart, whether the init-time `appInviteOneLink` value was actually applied by the native SDK (no callback/confirmation, unlike the explicit `setAppInviteOneLinkID` callback in F-028).

---

## Dependencies
```mermaid
flowchart LR
    F056["F-056 · App Invite Link OneLink ID (init-time)"]:::oneLinkAndGrowth
    F028["F-028 · App Invite OneLink ID Configuration"]:::oneLinkAndGrowth
    F056 -->|"shares same native OneLink-ID property, last write wins"| F028
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
