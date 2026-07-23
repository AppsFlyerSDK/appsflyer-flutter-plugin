---
id: F-029
name: Cross-Promotion Impression/Click Tracking
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-027"]
---

## Business Purpose
Advertisers who own multiple apps often promote one app from within another (cross-promotion). To measure whether these in-house house-ads actually drive installs, AppsFlyer needs to see both the impression (ad shown) and the click-to-store-open event, attributed to the promoted app's own AppsFlyer app ID and campaign. `logCrossPromotionImpression` and `logCrossPromotionAndOpenStore` wrap the native `CrossPromotionHelper` / `AppsFlyerCrossPromotionHelper` APIs so this measurement and (on Android) the store-open action can be triggered from Dart. Without this, cross-promotion campaigns between an advertiser's own apps would have no attribution signal distinguishing them from ordinary organic or paid installs.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
- `logCrossPromotionImpression`: called by the host app whenever a house-ad for another of the advertiser's apps is displayed to the user.
- `logCrossPromotionAndOpenStore`: called by the host app when the user taps/clicks that house-ad, to log the click and send the user to the promoted app's store listing.

---

## Call Chain
```
AppsflyerSdk.logCrossPromotionImpression(appId, campaign, data)                          [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("logCrossPromotionImpression", {...})
    → Android: AppsflyerSdkPlugin.onMethodCall("logCrossPromotionImpression") → logCrossPromotionImpression(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → CrossPromotionHelper.logCrossPromoteImpression(mContext, appId, campaign, data) → result.success(null)              (native AppsFlyer Android SDK)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("logCrossPromotionImpression") → logCrossPromotionImpression:result:         [ios/Classes/AppsflyerSdkPlugin.m]
      → [AppsFlyerCrossPromotionHelper logCrossPromoteImpression:appId campaign:campaign parameters:parameters]             (native AppsFlyer iOS SDK)

AppsflyerSdk.logCrossPromotionAndOpenStore(appId, campaign, params)                       [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("logCrossPromotionAndOpenStore", {...})
    → Android: AppsflyerSdkPlugin.onMethodCall("logCrossPromotionAndOpenStore") → logCrossPromotionAndOpenStore(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → CrossPromotionHelper.logAndOpenStore(mContext, appId, campaign, data) → result.success(null)                        (native AppsFlyer Android SDK)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("logCrossPromotionAndOpenStore") → logCrossPromotionAndOpenStore:result:     [ios/Classes/AppsflyerSdkPlugin.m]
      → AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:completionHandler: → [[UIApplication sharedApplication] openURL:...]   (see Known Limitations)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `logCrossPromotionImpression()` and `logCrossPromotionAndOpenStore()` — public API, both `void`/fire-and-forget |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `logCrossPromotionImpression(call, result)` and `logCrossPromotionAndOpenStore(call, result)` — forward to native `CrossPromotionHelper`, guarded by a non-empty `appId` check, always call `result.success(null)` |
| `ios/Classes/AppsflyerSdkPlugin.m` | `logCrossPromotionImpression:result:` and `logCrossPromotionAndOpenStore:result:` — see Known Limitations for behavioral divergence from Android |

---

## Input / Output
| | |
|--|--|
| **Input** | `logCrossPromotionImpression(String appId, String campaign, Map? data)`; `logCrossPromotionAndOpenStore(String appId, String campaign, Map? params)` |
| **Output** | Android: `void`, always resolves the method-channel `Future` via `result.success(null)`. iOS: `void`, but see Known Limitations — the channel `Future` is never resolved. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check logCrossPromotionAndOpenStore call` (line 165) asserts `appId`/`campaign`/`params` are passed through to the channel correctly; `check logCrossPromotionImpression call` (line 174) only asserts the method name is dispatched. Neither test exercises native behavior or the iOS/Android divergence described below.

---

## Known Limitations
- **iOS `logCrossPromotionImpression:result:` and `logCrossPromotionAndOpenStore:result:` never call `result(...)`**: unlike every other handler in `ios/Classes/AppsflyerSdkPlugin.m`, these two methods have no `result(nil)` (or any `result` call) at the end. The Dart-side `Future` returned by `_methodChannel.invokeMethod` for these calls is therefore never resolved on iOS — callers awaiting it (if any were added later) would hang indefinitely; today both Dart methods are `void` and don't await, so this is currently silent but latent.
- **iOS `logCrossPromotionAndOpenStore:result:` does not use the native cross-promotion "open store" API at all**: instead of calling an equivalent to Android's `CrossPromotionHelper.logAndOpenStore`, it generates a plain invite link via `AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:` (setting only `campaign` and custom params — `appId` is read from `call.arguments` on Android but is **never read** on iOS) and then opens that URL with `UIApplication openURL:options:completionHandler:`. This means the promoted app's ID is not passed to the underlying attribution call on iOS, unlike Android.
- Android's `logCrossPromotionImpression`/`logCrossPromotionAndOpenStore` silently skip the native call entirely (but still return success) if `appId` is `null` or `""`.

---

## Dependencies
```mermaid
flowchart LR
    F029["F-029 · Cross-Promotion Impression/Click Tracking"]:::oneLinkAndGrowth
    F027["F-027 · User Invite Link Generation (OneLink)"]:::oneLinkAndGrowth
    F029 -->|"iOS: reuses same invite-URL generator helper as"| F027
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
