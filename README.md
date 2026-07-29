# appsflyer-flutter-plugin

![AppsFlyer Logo](https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png)

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk)
![Coverage](https://raw.githubusercontent.com/AppsFlyerSDK/appsflyer-flutter-plugin/master/coverage_badge.svg)

🛠 In order for us to provide optimal support, please contact AppsFlyer support through the Customer Assistant Chatbot for assistance with troubleshooting issues or product guidance. </br>
To do so, please follow [this article](https://support.appsflyer.com/hc/en-us/articles/23583984402193-Using-the-Customer-Assistant-Chatbot)


## SDK Versions

- Android AppsFlyer SDK **v7.0.1**
- iOS AppsFlyer SDK **v7.0.1**

### Purchase Connector versions

- Android 2.2.0
- iOS 7.0.1

## ❗❗ Breaking changes when updating to v7.x.x❗❗

Version `7.0.0` migrates the plugin to **AppsFlyer SDK 7** (Android & iOS `7.0.1`) using the new RPC architecture. If you are upgrading from `6.x`, follow the [**v6 → v7 migration guide**](/doc/migration-guide.md) and review the changes below and the [full migration notes in the CHANGELOG](/CHANGELOG.md).

> **API Removal Rule — _Preserve SDK 7 behavior, not SDK 6 APIs._** Any public API removed from the native AppsFlyer SDK 7 is also removed from this plugin; obsolete SDK 6 APIs are not kept for backward compatibility. See the [migration guide](/doc/migration-guide.md) for the full removed/changed API mapping.

- **iOS minimum deployment target is now `13.0`.**

- **`manualStart` was removed from `AppsFlyerOptions`.** In SDK 7 `initSdk()` only initializes the SDK; a session (Launch) is sent only when you call [`startSDK()`](/doc/api-reference.md#startSDK).

- **`startSDK()` must be called once per foreground cycle** — the native SDK resets its "started" state on every background. Call it from inside [`registerSessionReadyListener`](/doc/api-reference.md#registerSessionReadyListener), which fires once per foreground cycle (after any launch deep link resolves):

```dart
appsflyerSdk.registerSessionReadyListener((_) => appsflyerSdk.startSDK());
```

- **Setter values are now runtime-only on both platforms.** Android no longer persists setter values (`setCustomerUserId`, `setCurrencyCode`, `setAdditionalData`, `setConsentData`, `anonymizeUser`, …) across process restarts — re-apply them on every cold start, **before** `startSDK()`.

- **`onAppOpenAttribution` (OAOA) and the `registerOnAppOpenAttributionCallback` flag were removed.** Use [`onDeepLinking`](/doc/api-reference.md#onDeepLinking) with `registerOnDeepLinkingCallback: true` (Unified Deep Linking) instead.

- **`performOnDeepLinking()` was replaced by [`performDeepLinking(url, {shouldTriggerSession})`](/doc/api-reference.md#performDeepLinking).**

- **APIs removed from the native SDK 7 were removed from the plugin:** `validateAndLogInAppIosPurchase` / `validateAndLogInAppAndroidPurchase` (V1) → use [`validateAndLogInAppPurchaseV2`](/doc/api-reference.md#validatePurchaseV2); `setPushNotification` → use [`sendPushNotificationData`](/doc/api-reference.md#sendPushNotificationData); `enableUninstallTracking` → use [`updateServerUninstallToken`](/doc/api-reference.md#updateServerUninstallToken).

- **`setUserEmails`, `setImeiData`, and `setAndroidIdData` were removed.** They still exist in the native SDK 7 but are not reachable through the SDK 7 RPC bridges. For emails, use the hashed [`setUserEmail`](/doc/api-reference.md#setUserEmail) setter.

## ❗❗ Breaking changes when updating to v6.x.x❗❗

If you have used one of the removed/changed APIs, please check the integration guide for the updated instructions.

- From version `6.11.2`, the `setPushNotification` will not work in iOS. [Please use our new API `sendPushNotificationData` when receiving a notification on flutter side](/doc/api-reference.md#sendPushNotificationData).

- From version `6.8.0`, the `enableLocationCollection` has been removed from the plugin.

- From version `6.4.0`, UDL (Unified deep link) now as a dedicated class with getters for handling the deeplink result.
[Check the full UDL guide](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/deep-linking.md).
`setSharingFilter` & `setSharingFilterForAllPartners` APIs are deprecated.
Instead use the [new API `setSharingFilterForPartners`](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/api-reference.md#setSharingFilterForPartners).

- From version `6.3.5+2`, Remove stream from the plugin (no change is needed if you use callbacks for handling deeplink).

- From version `6.2.3+2`, Flutter 2 is supported, including null safety.
`6.2.4-flutterv1` will use iOS SDK 6.2.4 with Flutter V1.

- From version `6.0.0`, we have renamed the following APIs:

|Before v6                      | v6                          |
|-------------------------------|-----------------------------|
| trackEvent                    | logEvent                    |
| stopTracking                  | stop                        |
| validateAndTrackInAppPurchase | validateAndLogInAppPurchase |

- From version `6.1.2+4`, we have renamed the following APIs:

|Before v6.1.2+4                | v6.1.2+4                    |
|-------------------------------|-----------------------------|
| validateAndLogInAppPurchase | validateAndLogInAppIosPurchase/validateAndLogInAppAndroidPurchase |

### Important notice

- Switch `ConversionData` and `OnAppOpenAttribution` to be based on callbacks instead of streams from plugin version `6.0.5+2`.

## AD_ID permission for Android

In v6.8.0 of the AppsFlyer SDK, we added the normal permission `com.google.android.gms.permission.AD_ID` to the SDK's AndroidManifest,
to allow the SDK to collect the Android Advertising ID on apps targeting API 33.
If your app is targeting children, you need to revoke this permission to comply with Google's Data policy.
You can read more about it in the [Android SDK installation guide](https://dev.appsflyer.com/hc/docs/install-android-sdk#the-ad_id-permission).

## 📖 Guides

- [Documentation index](/doc/README.md)
- [Migrating from v6 to v7](/doc/migration-guide.md) <- **New addition**
- [Adding the SDK to your project](/doc/installation-guide.md)
- [Getting started (init & session)](/doc/getting-started.md)
- [In-app events & ad revenue](/doc/in-app-events.md)
- [Deep linking](/doc/deep-linking.md)
- [Advanced features](/doc/advanced-features.md)
- [Consent & DMA compliance](/doc/consent-dma.md)
- [Testing & troubleshooting](/doc/testing-and-troubleshooting.md)
- [Purchase Connector](/doc/purchase-connector.md) <- **New addition**
- [API reference](/doc/api-reference.md)
- [Sample App](/example)
