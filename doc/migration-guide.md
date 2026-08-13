# Migrating the AppsFlyer Flutter plugin from v6 to v7

<img src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png" width="400">

This release is a major API cleanup. It replaces callback flags, callback slots,
and SDK-6 names with an explicit SDK-7 lifecycle, typed callbacks, correlated
`Future` results, and platform-aware models.

Plugin `7.0.1` migrates to **AppsFlyer SDK 7** (Android and iOS `7.0.1`). This
is a major release with intentional breaking changes. Purchase Connector
dependency changes are described later in this guide.

The minimum supported toolchain is Flutter `3.24.0` and Dart `3.5.0` (and
earlier than Dart `4.0.0`). Android requires API 21 or later, and iOS requires
version 13.0 or later.

This guide is scoped to the **Flutter plugin**. For the underlying native behavior, read
the official SDK 7 migration guides — they are the source of truth for what changed:

- Android: <https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7>
- iOS: <https://dev.appsflyer.com/hc/docs/migrate-ios-sdk-to-v7>

---

## API Removal Rule

> **Preserve SDK 7 behavior — not SDK 6 APIs.**

If a public API has been **removed from the native AppsFlyer SDK 7, it is also removed from
the Flutter plugin.** The plugin does not preserve or emulate APIs that no longer exist in
the native SDK unless there is a strong technical or business justification.

Because this is a major version migration (SDK 6 → SDK 7), breaking API changes are expected
and acceptable when they align the plugin with the native SDKs. Obsolete SDK 6 APIs are **not**
kept for backward compatibility. Instead, for every migration the plugin:

- **Removes** APIs that were removed from the native SDK.
- **Redesigns** the Flutter API to follow the new SDK 7 architecture.
- **Documents** every removed or changed API in this guide and in the [CHANGELOG](../CHANGELOG.md).
- **Explains** the replacement API or the new SDK 7 workflow, when one exists.

The plugin stays a thin, platform-consistent abstraction over the native Android and iOS
SDKs rather than maintaining legacy concepts that no longer exist in SDK 7.

---

## Session model and lifecycle

The biggest behavioral change in SDK 7 is that **you control when a session (Launch) is
sent**. `init()` only initializes the SDK; nothing is reported until you call `start()`,
and `start()` must be called **once per foreground cycle** (the native SDK resets its
"started" flag on every background).

| v6 API or limitation | v7 replacement |
| --- | --- |
| `AppsflyerSdk` | `AppsFlyerSdk` |
| Map-based constructor and `AppsFlyerOptions` | `AppsFlyerSdk.instance` |
| `initSdk(...)` | `init(devKey:, appId:)`; `appId` is required on iOS and optional on Android |
| `void startSDK({onSuccess, onError})` | `Future<void> start({bool awaitResponse = false})`; await the Future and catch `AppsFlyerException` when requesting the native result |
| `registerConversionDataCallback` init flag | `registerConversionListener(onSuccess:, onFailure:)` |
| `registerOnDeepLinkingCallback` init flag | `registerDeepLinkListener(onDeepLink)` |
| No session-readiness public API | `registerSessionReadyListener(onReady)`, `unregisterSessionReadyListener()`, and `isSessionReady()` |

Use `AppsFlyerSdk.instance`, register the deep-link listener if your app handles
deep links, initialize it with the developer key and, on iOS, the Apple app ID,
apply runtime configuration through explicit setters, register the remaining
native listeners you need, and call `start()` from the session-ready callback:

```dart
final appsflyer = AppsFlyerSdk.instance;

await appsflyer.enableDebug(true);
// Before init(): Android skips deferred deep-link resolution, permanently for
// that install, when no listener is registered while init() runs.
await appsflyer.registerDeepLinkListener((result) { /* route the user */ });
await appsflyer.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);
await appsflyer.registerSessionReadyListener(() async {
  await appsflyer.start();
});
```

Gate the first session (consent, Customer User ID, ATT) by deferring the `start()` call
inside the callback. Apply any configuration setters (e.g.
`setCustomerUserId`, `setCurrencyCode`, `setConsentData`) **before** `start()`.

> **Setter values are runtime-only on both platforms.** SDK 7 aligns Android with iOS:
> setter values are no longer persisted to disk and do not survive a process restart.
> Re-apply them on every cold start, before `start()`.

---

## Events, callbacks, and errors

| Removed API | Replacement |
| --- | --- |
| `onInstallConversionData(callback)` | `registerConversionListener(onSuccess:, onFailure:)`; Android also exposes `unregisterConversionListener()` |
| `onDeepLinking(callback)` | `registerDeepLinkListener(onDeepLink)` |
| global invite-link callbacks | `await generateInviteLink(...)` |
| request success/error callbacks | `await` and catch `AppsFlyerException` |
| `Status` | `DeepLinkStatus` |
| `Error` enum | `DeepLinkFailure` with Android `type` or iOS `message` |

---

## Removed APIs and their replacements

| Removed Flutter API (v6) | Why | SDK 7 replacement / action |
| --- | --- | --- |
| Map constructor, `AppsFlyerOptions`, and `manualStart` | Configuration-object lifecycle removed | `AppsFlyerSdk.instance`, `init(...)`, then `start()` |
| `onAppOpenAttribution`, `registerOnAppOpenAttributionCallback` | OAOA removed from both native SDKs | `registerDeepLinkListener(onDeepLink)` |
| `performOnDeepLinking()` | Removed on Android (§5a), replaced on iOS | `performDeepLinking(url, {shouldTriggerSession})` |
| `validateAndLogInAppAndroidPurchase` (V1) | Native V1 purchase validation removed | `validateAndLogInAppPurchase` with `AFAndroidPurchaseDetails` |
| `validateAndLogInAppIosPurchase` (V1) | Native 6-param purchase validation removed (iOS §6) | `validateAndLogInAppPurchase` with `AFIOSPurchaseDetails` |
| `onPurchaseValidation` | Legacy validation callback removed | `validateAndLogInAppPurchase` with `awaitResponse` |
| `setPushNotification(bool)` | Removed from both native SDKs | Android: `sendPushNotificationData(...)`; iOS: `handlePushNotification(pushPayload)` |
| `enableUninstallTracking(String)` | Legacy device-token flow removed | `updateServerUninstallToken(String)` |
| `setCollectIMEI(bool)` | Removed from native SDK 7 (§9) | IMEI auto-collection removed; no replacement |
| `waitForCustomerUserId(bool)` | Removed from native SDK 7 (§9) | Call `setCustomerUserId()` before `start()` |
| `setCustomerIdAndLogSession(String)` | Removed from native SDK 7 (§9) | `setCustomerUserId()` then `start()` |
| `setSharingFilter`, `setSharingFilterForAllPartners` | Removed from both native SDKs | `setSharingFilterForPartners(["all"])` |
| `AppsFlyerOptions.timeToWaitForATTUserAuthorization` | Removed from native SDK 7 | Control the timing of `start()` in application code |
| `enableLocationCollection(bool)` | Removed in plugin `6.8.0` | No replacement |
| Callback-slot helpers | Replaced by explicit listener registration | `registerConversionListener(onSuccess:, onFailure:)` and `registerDeepLinkListener(onDeepLink)`, each taking a typed callback |

`subscribeForDeepLink(listener, timeout)` was an Android native SDK overload,
not a public Flutter v6 API. Its SDK 7 Flutter equivalent is to call
`setDeepLinkTimeout(timeout)`, then `registerDeepLinkListener(onDeepLink)` —
both before `init()`.

The following are not simulated in Dart: use Unified Deep Linking, control the
timing of `start()` in application code, and use only capabilities exposed by
the Flutter plugin's public API.

### APIs present in native SDK 7 but removed from the plugin

Some APIs still exist in the native SDKs but are not available through the
Flutter plugin. Rather than provide methods that silently do nothing, the
plugin removes them from its public API:

| Removed Flutter API (v6) | Why | SDK 7 replacement / action |
| --- | --- | --- |
| `setUserEmails(List, EmailCryptType)` | Not available in the Flutter plugin | Hashed `setUserEmail(String)` |
| `setImeiData(String)` | Not available in the Flutter plugin | No Flutter SDK 7 replacement |
| `setAndroidIdData(String)` | Not available in the Flutter plugin | No Flutter SDK 7 replacement |

> The `EmailCryptType` enum was removed together with `setUserEmails`.

---

## Renames and signature changes

| Removed or changed | Replacement |
| --- | --- |
| `AppsFlyerOptions.showDebug` | `enableDebug(bool)` |
| `AppsFlyerOptions.afDevKey` | `init(devKey: ..., appId: ...)` |
| `AppsFlyerOptions.appInviteOneLink` | `setAppInviteOneLink(...)` |
| `AppsFlyerOptions.disableAdvertisingIdentifier` | `setDisableAdvertisingIdentifiers(...)` |
| `AppsFlyerOptions.disableCollectASA` | `setDisableCollectASA(...)` (iOS only) |
| `setAppInviteOneLinkID(String oneLinkID, Function callback)` | `setAppInviteOneLink(String oneLinkId)`; the required callback was removed |
| `performOnDeepLinking()` | `performDeepLinking(String url, {bool shouldTriggerSession = false})` |
| `setSharingFilter`, `setSharingFilterForAllPartners`, and `setSharingFilterForPartners(List<String> partners)` | `setSharingFilterForPartners(List<String>? partners)` |
| `setCustomerUserId(String id)` | `setCustomerUserId(String customerId)` |
| `setHost(String hostPrefix, String hostName)` | `setHost(String hostPrefixName, String hostName)` |
| `setPartnerData(String partnerId, Map<String, Object> partnerData)` | `setPartnerData(String partnerId, Map<String, dynamic> data)` |
| `stop(bool isStopped)` | `stop(bool shouldStop)` |
| `addPushNotificationDeepLinkPath(List<String> deeplinkPath)` | `addPushNotificationDeepLinkPath(List<String> deepLinkPath)` |
| `setOneLinkCustomDomain(List<String> brandDomains)` | `setOneLinkCustomDomain(List<String> domains)` |
| `Future<String?> getSDKVersion()` | `Future<String> getSdkVersion()` |
| `String getVersionNumber()` | `String get pluginVersion` |
| `Future<bool?> logEvent(String eventName, Map? eventValues)` | `Future<void> logEvent(String eventName, {Map<String, dynamic>? eventValues, bool awaitResponse = false})` |
| `setAdditionalData(Map<String, dynamic>? customData)` | `setAdditionalData(Map<String, dynamic> customData)`; pass an empty map to clear the data |
| `setDisableAdvertisingIdentifiers(bool isEnabled)` | `setDisableAdvertisingIdentifiers(bool disable)` |
| `validateAndLogInAppPurchaseV2` | `validateAndLogInAppPurchase` |
| Concrete Android-shaped `AFPurchaseDetails(purchaseType:, purchaseToken:, productId:)` | `AFAndroidPurchaseDetails(...)` or `AFIOSPurchaseDetails(...)`, both implementing `AFPurchaseDetails` |
| string ad-mediation value | `AFMediationNetwork` |
| `logAdRevenue(AdRevenueData)` | `logAdRevenue(monetizationNetwork: ..., mediationNetwork: ..., currencyIso4217Code: ..., revenue: ..., additionalParameters: ...)` |
| `setConsentDataV2(...)` or `setConsentData(AppsFlyerConsent)` | `setConsentData(isUserSubjectToGDPR: ..., hasConsentForDataUsage: ..., hasConsentForAdsPersonalization: ..., hasConsentForAdStorage: ...)` |
| `setCollectAndroidId(bool isCollect)` | `setCollectAndroidID(bool isCollect)` |
| `setDisableNetworkData(bool disable)` | `setDisableNetworkData(bool isDisable)` |
| `disableSKAdNetwork(bool isEnabled)` | `setDisableSKAdNetwork(bool disable)` |
| `useReceiptValidationSandbox(bool isSandboxEnabled)` | `setUseReceiptValidationSandbox(bool sandbox)` |
| `enableUninstallTracking(String senderId)` | `updateServerUninstallToken(String token)` on both platforms |
| callback-based `generateInviteLink(...)` | `await generateInviteLink(parameters: ..., awaitResponse: ...)` returning `String` |
| `AppsFlyerInviteLinkParams.customerID` | `AppsFlyerInviteLinkParams.referrerCustomerId` |
| `Map<String?, String?>? AppsFlyerInviteLinkParams.customParams` | `Map<String, String>? AppsFlyerInviteLinkParams.userParams` |
| `logCrossPromotionImpression(appId, campaign, data)` | `logCrossPromoteImpression(appId, campaign: ..., userParams: ...)` |
| `logCrossPromotionAndOpenStore(appId, campaign, params)` | `logAndOpenStore(appId, campaign: ..., userParams: ...)` |
| cross-platform `sendPushNotificationData(Map? userInfo)` | Android `sendPushNotificationData(campaign: ..., pid: ..., isRetargeting: ..., additionalParameters: ...)` or iOS `handlePushNotification(Map<String, dynamic> pushPayload)` |

---

## Added in SDK 7

The following APIs did not exist in the Flutter `6.18.1` public API.

Session model and deep linking:

| API | Purpose |
| --- | --- |
| `registerSessionReadyListener`, `unregisterSessionReadyListener`, `isSessionReady` | SDK 7 session-ready model |
| `performDeepLinking(url, {shouldTriggerSession})` | Manual deep link resolution |
| `setDeepLinkTimeout(timeout)` | Deep link resolution timeout |
| `appendParametersToDeepLinkingURL(contains, parameters)` | Enrich matching deep-link URLs before resolution (Android + iOS) |
| `setFacebookDeferredAppLink(url)` | Manually set/clear the Facebook deferred app-link URL (**iOS only**) |

User identity & PII:

| API | Purpose |
| --- | --- |
| `setUserEmail`, `setUserPhone`, `setUserFirstName`, `setUserLastName` | The native SDK normalizes and hashes these values with SHA-256 |
| `setUserFbLoginId` | Set the numeric Facebook App-Scoped ID without hashing |
| `clearUserPii` | Clear the email, phone, first name, last name, and Facebook Login ID values set through these APIs |

New parity APIs exposed in the plugin (already present in the native SDK 7):

| API | Purpose | Platforms |
| --- | --- | --- |
| `logInvite(channel, [eventParameters])` | Log the `af_invite` in-app event | Android + iOS |
| `logLocation(latitude: ..., longitude: ...)` | Manually log the device location | Android + iOS |
| `logSession()` | Manually log a session on Android | Android only; use `start()` for typical Flutter apps |
| `setLogLevel(level)` | Set native log verbosity | Android only |
| `setInstallId(installId)` | Correlate the install with your own id | Android + iOS |
| `isStopped()` | Query whether the SDK is stopped | Android only |
| `isPreInstalledApp()` | Query whether the install was an OEM preinstall | Android only |
| `getAttributionId()` | Read the Facebook (Katana) attribution id | Android only |
| `setPreinstallAttribution(mediaSource, {campaign, siteId})` | Attribute an OEM preinstall | Android only |
| `setAppId(appId)` | Override the reported app id | Android only |
| `unregisterConversionListener()` | Unregister the conversion-data listener | Android only |
| `unregisterDeeplinkListener()` | Unregister the deep-link listener | Android only |
| `setDisableAppleAdsAttribution(disable)` | Disable Apple Ads (ASA) attribution via AdServices | iOS only |
| `setDisableIDFVCollection(disable)` | Disable IDFV collection | iOS only |
| `setShouldCollectDeviceName(collect)` | Opt in to device-name collection | iOS only |
| `setUseUninstallSandbox(enabled)` | Sandbox mode for uninstall-measurement validation | iOS only |

`setInstallId()` has platform-specific ordering and opt-in requirements. On
iOS, call it before `init()` and set `AppsFlyerAllowCustomInstallId` to `YES` in
`Info.plist`. On Android, call it after `init()` and set
`APPSFLYER_ALLOW_CUSTOM_INSTALL_ID` to `true` as `<meta-data>` in
`AndroidManifest.xml`. Without the corresponding flag, the native SDK silently
ignores the call.

---

## Future completion and error behavior

All SDK setters now return `Future<void>`. For a fire-and-forget operation, a
completed `Future` means the native SDK accepted the call; it does not confirm
network delivery.

`start({awaitResponse})`, `logEvent(..., {awaitResponse})`,
`validateAndLogInAppPurchase(..., awaitResponse: ...)`, and
`generateInviteLink(..., awaitResponse: ...)` let the app choose whether to
wait for a native result where supported. `awaitResponse` defaults to `false`
for `start` and `logEvent`, and to `true` for purchase validation and invite-link
generation. On iOS, purchase validation and invite-link generation always wait
for their result.

---

## Purchase Connector dependency changes

When Purchase Connector is enabled, plugin `7.0.1` resolves Android Purchase
Connector `2.2.0` and iOS Purchase Connector `7.0.1`.

Android Purchase Connector `2.2.0` supports Google Play Billing Library `8.x`.
The Flutter plugin does not add the Billing Library itself, so your app or IAP
plugin must provide a Billing Library `8.x` dependency and use Billing
8-compatible APIs.

iOS Purchase Connector is available through CocoaPods only. Apps that do not
use Purchase Connector can use Swift Package Manager for the Core integration;
apps that use Purchase Connector must use CocoaPods for both Core and Purchase
Connector. See [Purchase Connector](purchase-connector.md) for setup details.

---

## Android: remove legacy install-referrer receivers

SDK 7 removed `SingleInstallBroadcastReceiver` and `MultipleInstallBroadcastReceiver`.
Remove any matching `<receiver>` entries from `android/app/src/main/AndroidManifest.xml`
(together with their `com.android.vending.INSTALL_REFERRER` intent filters). Leaving them
breaks manifest merge at **build time**. The Flutter plugin already declares
Google Play Install Referrer `2.2`, so Flutter apps do not need to add that
dependency manually.

Native reference: [Migrate Android SDK to V7 — §8](https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7#8-remove-legacy-broadcast-receivers).
For Samsung / Xiaomi / Huawei store referrers, see §11 of the same guide.

> Plugin v6 docs recommended adding `SingleInstallBroadcastReceiver` for some out-of-store
> markets. That guidance is **obsolete** for SDK 7 — use the Install Referrer library,
> optional store-referrer artifacts, and `setOutOfStore`. See
> [Advanced features — Android Out of Store](advanced-features.md#out-of-store).

---

## Platform behavior

Calling a guarded platform-only method outside its supported mobile platform is
a logged no-op. The plugin prints a warning naming the API and its supported
platform, skips the native call, and returns `null`, `false`, or nothing
depending on the return type. APIs invoked on unsupported Flutter targets such
as web or desktop throw `MissingPluginException`. Native failures on Android
and iOS are surfaced as `AppsFlyerException` with an optional numeric `code`
and `message`. Existing Android/iOS call sites for platform-only APIs keep
working without platform branches; check your logs for
`AppsFlyer: <method> ignored` while migrating.

- Android purchase validation requires a Play purchase token.
- iOS purchase validation requires an App Store transaction ID.
- Android cannot clear partner-sharing filters; iOS can. A clear request on
  Android is logged and leaves the existing filter unchanged.
- Passing an empty partner list is equivalent to passing `null`.
- On Android, `unregisterDeeplinkListener()` does not reliably stop subsequent
  deep-link events. Do not rely on it to disable deep-link handling.
- `setInstallId` has different native ordering rules: iOS configures it before
  initialization and requires `AppsFlyerAllowCustomInstallId=YES` in
  `Info.plist`, while Android requires an initialized SDK and
  `APPSFLYER_ALLOW_CUSTOM_INSTALL_ID=true` in the application manifest.
- iOS uninstall tokens must be even-length hexadecimal APNs token strings.

See the [API reference](api-reference.md) for per-method platform availability
(**Android only** / **iOS only** markers on each API).

---

See the full, version-by-version history in the [CHANGELOG](../CHANGELOG.md) and the complete
method reference in [API reference](api-reference.md).
