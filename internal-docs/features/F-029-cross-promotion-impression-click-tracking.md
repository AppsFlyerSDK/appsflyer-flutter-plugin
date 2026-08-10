---
id: F-029
name: Cross-Promotion Impression/Click Tracking
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Advertisers who own multiple apps often promote one app from within another (cross-promotion). To measure whether these in-house house-ads actually drive installs, AppsFlyer needs to see both the impression (ad shown) and the click-to-store-open event, attributed to the promoted app's own AppsFlyer app ID and campaign. `logCrossPromoteImpression` and `logAndOpenStore` wrap the native cross-promotion APIs so this measurement and the store-open action can be triggered from Dart. Without this, cross-promotion campaigns between an advertiser's own apps would have no attribution signal distinguishing them from ordinary organic or paid installs.

---

## Trigger
- `logCrossPromoteImpression`: awaited by the host app whenever a house-ad for another of the advertiser's apps is displayed to the user.
- `logAndOpenStore`: awaited by the host app when the user taps that house-ad, to log the click and send the user to the promoted app's store listing.

---

## Call Chain
Both are awaitable RPC calls over the single `executeRpc` entry point. `logAndOpenStore` is the one method that iOS orchestrates plugin-side: it reads the click URL out of the RPC result and opens it with `UIApplication`.

```
AppsFlyerSdk.logCrossPromoteImpression(appId, campaign: ..., userParams: ...)   [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('logCrossPromoteImpression', {appId, campaign, userParams})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → LogCrossPromoteImpressionRequest  // init: require(appId.isNotEmpty())
        → CrossPromotionHelper.logCrossPromoteImpression(context, appId, campaign, userParams)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge

AppsFlyerSdk.logAndOpenStore(promotedAppId, campaign: ..., userParams: ...)     [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('logAndOpenStore', {promotedAppId, campaign, userParams})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → LogAndOpenStoreRequest  // init: require(promotedAppId.isNotEmpty())
        → CrossPromotionHelper.logAndOpenStore(context, promotedAppId, campaign, userParams)
      → iOS: AppsflyerSdkPlugin.logAndOpenStoreFromRpc:params:result:      [ios/.../AppsflyerSdkPlugin.m]
        → AppsFlyerRPCBridge executeJson → result.data.clickURL → UIApplication openURL:options:completionHandler:
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `logCrossPromoteImpression(String appId, {String campaign, Map<String, String>? userParams})` and `logAndOpenStore(String promotedAppId, {String campaign, Map<String, String>? userParams})` — both return `Future<void>` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | No per-method handler — both methods go through the generic `executeRpc` → `dispatchRpc` path to the native RPC bridge |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `logAndOpenStoreFromRpc:params:result:` — plugin-orchestrated: reads `data.clickURL` from the RPC result and opens it with `UIApplication`. `logCrossPromoteImpression` uses the generic dispatch. |

---

## Input / Output
| | |
|--|--|
| **Input** | `logCrossPromoteImpression`: `appId` (required positional) plus optional `campaign` (defaults to `''`) and `userParams`, sent as `{appId, campaign, userParams}`. `logAndOpenStore`: `promotedAppId` (required positional) plus the same optional named arguments, sent as `{promotedAppId, campaign, userParams}`. |
| **Output** | `Future<void>` for both. `logCrossPromoteImpression` completes after validation and synchronous SDK invocation. On Android, `logAndOpenStore` also returns after synchronous invocation; on iOS it awaits click-URL generation (10-second RPC timeout), then completes after `UIApplication.open` calls its completion handler. RPC/native failures are exposed as `AppsFlyerException`; the click URL is not returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `maps deep-link, sharing, push, and uninstall APIs` asserts that `logCrossPromoteImpression('promoted', campaign: 'campaign', userParams: {...})` dispatches RPC `logCrossPromoteImpression` with `{appId, campaign, userParams}`, and that `logAndOpenStore('promoted', ...)` dispatches RPC `logAndOpenStore` with `{promotedAppId, campaign, userParams}`. Neither test exercises native behavior or the iOS store-open side effect.

---

## Known Limitations
- **iOS store-open is plugin-orchestrated**: the iOS RPC layer has no "log and open store" action, so `logAndOpenStoreFromRpc` opens the store by reading `clickURL` from the RPC result and calling `UIApplication openURL:options:completionHandler:`. If the bridge returns no `clickURL`, the Future still completes successfully but nothing opens.
- An iOS cross-promotion timeout fails the Dart Future but does not cancel native work; a late native completion can still occur after the caller has received `AppsFlyerException`.
- No validation in Dart of `appId`/`promotedAppId`/`campaign`. Android rejects an empty app ID in the RPC request (`require(...isNotEmpty())`), which surfaces to the caller as `AppsFlyerException`.
- The generated click URL is not exposed to Dart, so an app cannot intercept or rewrite it before the store page opens.

---

## Dependencies
No required feature dependency. The iOS native implementation reuses a URL-generator helper, but the public cross-promotion APIs do not require F-027 invite-link generation or F-028 invite configuration.
