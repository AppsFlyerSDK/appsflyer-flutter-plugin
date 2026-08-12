# Versions

## 7.0.1

Migration to **AppsFlyer SDK 7**. This is a major release with intentional
breaking changes. See [doc/migration-guide.md](doc/migration-guide.md) for
removed APIs, renames, lifecycle changes, and upgrade instructions.

- Flutter plugin version **7.0.1**
- Minimum Flutter version **3.24.0**
- Minimum Dart version **3.5.0** (and earlier than Dart **4.0.0**)
- Android AppsFlyer SDK **7.0.1**
- iOS AppsFlyer SDK **7.0.1**
- Android Purchase Connector **2.2.0**
- iOS Purchase Connector **7.0.1**
- iOS minimum deployment target **13.0**
- Android minimum API level **21**
- Documentation remains organized under [`doc/`](doc/README.md), with the
  complete upgrade catalog in [doc/migration-guide.md](doc/migration-guide.md).

**BREAKING**

- Replaced `AppsflyerSdk(options)` and `AppsFlyerOptions` with the shared
  `AppsFlyerSdk.instance` singleton and explicit configuration methods.
- Replaced `initSdk(...)` with `init(devKey:, appId:)`. `appId` is required on
  iOS, optional on Android, and is not sent to the Android SDK.
- Replaced `startSDK(...)` with `await start()`. Initialization no longer sends
  a session. Subscribe to `onSessionReady`, call
  `registerSessionReadyListener()`, and call `start()` once for each readiness
  event.
- Replaced callback registration flags and callback slots with typed event
  streams and explicit listener registration. Conversion data uses
  `onConversionDataSuccess` / `onConversionDataFailure`; Unified Deep Linking
  uses `onDeepLinkReceived`.
- Native and plugin failures from operations that await a result are surfaced as
  `AppsFlyerException` (`int? code`, `String message`). Non-numeric platform
  codes leave `code` as `null`. `MissingPluginException` is not converted.
  Failures from fire-and-forget calls are not reported.
- `start`, `logEvent`, `generateInviteLink`, and
  `validateAndLogInAppPurchase` expose `awaitResponse` where the native SDK
  supports waiting for a completion callback. It defaults to `false` for `start`
  and `logEvent`, and to `true` for the two result-producing APIs.
- Removed OAOA callbacks and registration. Use Unified Deep Linking.
- Replaced `performOnDeepLinking()` with
  `performDeepLinking(url, {shouldTriggerSession})`.
- Replaced legacy V1 Android/iOS purchase validation and
  `validateAndLogInAppPurchaseV2(...)` with
  `validateAndLogInAppPurchase(AFPurchaseDetails, ...)`. Use
  `AFAndroidPurchaseDetails` with a Play purchase token or
  `AFIOSPurchaseDetails` with an App Store transaction ID.
- Replaced the cross-platform `sendPushNotificationData(Map)` shape with
  platform-specific Android `sendPushNotificationData(...)` and iOS
  `handlePushNotification(pushPayload)` APIs.
- Replaced `setConsentDataV2(...)` and the `AppsFlyerConsent` wrapper with the
  flat `setConsentData(...)` API and its four SDK 7 consent fields.
- Renamed platform APIs to match the final SDK 7 surface, including
  `enableDebug`, `setDisableSKAdNetwork`,
  `setDisableAppleAdsAttribution`, `setDisableIDFVCollection`,
  `setUseReceiptValidationSandbox`, and `setUseUninstallSandbox`.
- `setUserFbLoginId` now accepts an `int`; mediation values use
  `AFMediationNetwork`; invite-link fields use `referrerCustomerId` and
  `userParams`.
- Removed SDK 6 APIs that no longer exist in SDK 7 or are not exposed by the
  plugin, including `onAppOpenAttribution`, `setUserEmails`, `EmailCryptType`,
  raw IMEI and Android ID setters, V1 purchase validation, `setPushNotification`,
  `enableUninstallTracking`, `waitForCustomerUserId`, and
  `setCustomerIdAndLogSession`.
- Runtime configuration setters must be re-applied on every cold start before
  `start()`.
- Most guarded platform-only methods log and return a safe default when called
  outside their supported platform. Seven symmetric getters and setters
  (`getHostName`, `getHostPrefix`, `getOutOfStore`, `isPreInstalledApp`,
  `getAttributionId`, `setUseReceiptValidationSandbox`,
  `setUseUninstallSandbox`) route through the native RPC layer instead and throw
  `AppsFlyerException` when the method is unavailable on that platform.
- `getHostName()` and `getHostPrefix()` now return non-nullable `Future<String>`
  on Android; unexpected native null replies throw `AppsFlyerException` instead
  of surfacing as `null`.
- RPC helpers split into `_invokeNullableRpc` and `_invokeRpc<T extends Object>`;
  bool getters such as `isSessionReady`, `isStopped`, and `isPreInstalledApp`
  no longer coerce an unexpected native `null` to `false`.
- `setInstallId()` requires `AppsFlyerAllowCustomInstallId=YES` in iOS
  `Info.plist` and must be called before `init()` on iOS. Android requires
  `APPSFLYER_ALLOW_CUSTOM_INSTALL_ID=true` in `AndroidManifest.xml` and the call
  must follow `init()`.
- Android Purchase Connector `2.2.0` requires Google Play Billing Library `8.x`.
  The Flutter plugin does not add Billing Library; the app or its IAP plugin
  must provide it. iOS Purchase Connector requires CocoaPods, while Core-only
  apps can use Swift Package Manager.
- Remove legacy `SingleInstallBroadcastReceiver` and
  `MultipleInstallBroadcastReceiver` manifest entries. The plugin already
  includes Google Play Install Referrer `2.2`.

See the [v6 → v7 migration guide](doc/migration-guide.md) for the complete
replacement table.

**Added**

- Added `AppsFlyerSdk.instance`, `init(...)`, `onSessionReady`,
  `registerSessionReadyListener()`, `unregisterSessionReadyListener()`,
  `isSessionReady()`, and `start()` for the SDK 7 lifecycle.
- Added the cross-platform `enableDebug(bool)` toggle and Android-only
  `setLogLevel(AFLogLevel)`.
- Added typed event streams and `AppsFlyerException`.
- Added hashed-PII setters `setUserEmail`, `setUserPhone`,
  `setUserFirstName`, and `setUserLastName`, plus integer
  `setUserFbLoginId` and `clearUserPii`.
- Added `performDeepLinking`, `setDeepLinkTimeout`,
  `appendParametersToDeepLinkingURL`, and iOS-only
  `setFacebookDeferredAppLink`.
- Added the `AFPurchaseDetails` interface with dedicated
  `AFAndroidPurchaseDetails` and `AFIOSPurchaseDetails` implementations.
- Added Android-only `logSession`, `setPreinstallAttribution`, `setAppId`,
  `isStopped`, `isPreInstalledApp`, `getAttributionId`,
  `unregisterDeeplinkListener`, and `unregisterConversionListener` APIs.
  On Android, `unregisterDeeplinkListener` does not reliably stop subsequent
  deep-link events; do not depend on it as an effective unsubscribe.
- Added iOS-only `setDisableAppleAdsAttribution`,
  `setDisableIDFVCollection`, `setShouldCollectDeviceName`, and
  `setUseUninstallSandbox` APIs.
- Added `logInvite`, `logLocation`, `setInstallId`, and awaitable
  `generateInviteLink` support.

**Fixed**

- Purchase Connector: removed stray `[AppsFlyer_PC_Debug]` `print` logging that shipped in release builds; the callback handler now accepts both JSON-string and already-decoded `Map` payloads and logs (instead of throwing) on an unrecognized callback name.
- Purchase Connector (**Android**): subscription and in-app validation-result listeners (`setSubscriptionValidationResultListener` / `setInAppValidationResultListener`) never fired — the Dart callback-name constants used a `#` separator while the native side invokes the channel with `:`, so the handler's `switch` never matched. Aligned the Dart constants to `:`, so these result listeners now deliver.
- **Android**: native events emitted while no Flutter engine was attached were
  lost. The native SDK keeps the listener registered by a detached engine
  (`subscribeForDeepLink` and `registerConversionListener` overwrite a single
  reference, and deep links have no unsubscribe API), so a deep link or
  conversion-data callback arriving after the Activity was destroyed — for
  example a link tapped after leaving the app with the back button — was written
  into the buffer of a plugin instance Dart could no longer reach. Buffering and
  replay moved to a process-scoped relay, so those events are delivered to the
  next subscriber in the order they were published.
- Optional Android Purchase Connector state is cleared when the Flutter engine
  detaches.
- Corrected iOS ad-mediation identifiers for custom and direct monetization.
- Updated documentation and examples for the final SDK 7 API.

## 6.18.0

- Updated Android SDK from 6.17.6 to 6.18.0
- Updated iOS SDK from 6.17.9 to 6.18.0
- Updated iOS Purchase Connector from 6.17.9 to 6.18.0
- Fixed Android warm-app deep link consumption race so `DeepLinkListener` fires reliably when the app is resumed from a `VIEW` intent (forward new intents to `AppsFlyerLib` from the plugin's `onNewIntentListener` before the SDK's `onResume` auto-handler marks them `af_consumed`)
- Added Swift Package Manager (SPM) support for the Core iOS integration (`ios/appsflyer_sdk/Package.swift`), alongside continued full CocoaPods support — no behavior change for existing CocoaPods consumers. Purchase Connector remains CocoaPods-only for now, pending resolution of an upstream Flutter limitation ([flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182)) that blocks conditionally-compiled plugin features under SPM.

## 6.17.9

- Added UIScene lifecycle support for iOS deep linking (Flutter 3.41+ compatibility)
  - Adopted `FlutterSceneLifeCycleDelegate` with compile-time guard for backward compatibility
  - Added `scene:openURLContexts:` for warm-start URI-scheme deep links
  - Added `scene:willConnectToSession:options:` for cold-start URI-scheme and Universal Links
  - Added `scene:continueUserActivity:` for Universal Links via UIScene
- Fixed `getViewController` to use `UIWindowScene` lookup on iOS 13+ (replaces deprecated `UIApplication.delegate.window`)
- Updated iOS SDK from 6.17.8 to 6.17.9
- Updated iOS Purchase Connector from 6.17.8 to 6.17.9

## 6.17.8

- Updated Android SDK from 6.17.4 to 6.17.5
- Updated iOS SDK from 6.17.7 to 6.17.8
- Updated iOS Purchase Connector from 6.17.7 to 6.17.8
- Deprecated `validateAndLogInAppAndroidPurchase` (V1) - use `validateAndLogInAppPurchaseV2` instead
- Deprecated `validateAndLogInAppIosPurchase` (V1) - use `validateAndLogInAppPurchaseV2` instead
- Enhanced iOS error handling for `validateAndLogInAppPurchaseV2` with comprehensive NSError parsing (code, domain, userInfo)
- **Documentation Updates:**
  - Removed "Beta" label from `validateAndLogInAppPurchaseV2` API
  - Marked V1 purchase validation APIs as Deprecated
  - Added comprehensive `PlatformException` error handling examples for V2 API
  - Added iOS token format explanation for uninstall measurement
  - Added cross-platform Firebase Messaging example for uninstall tokens

## 6.17.7+1

- Update Android SDK version to 6.17.4

## 6.17.7

- Updated to AppsFlyer SDK v6.17.7 for iOS and Flutter plugin version
- Android AppsFlyer SDK remains at v6.17.3
- iOS AppsFlyer SDK upgraded to v6.17.7
- Android Purchase Connector module updated (to support Google Billing Library 8)
- Code cleanups
- **Documentation Updates:**
  - Enhanced push notification measurement documentation with clear separation between traditional `af` object approach and OneLink URL approach
  - Added comprehensive iOS-specific requirements for OneLink push notification integration
  - Clarified the need to call `sendPushNotificationData()` on iOS when using `addPushNotificationDeepLinkPath()`
  - Added complete code examples for both push notification integration approaches with Firebase Cloud Messaging
  - Added Flutter 3.27+ breaking change documentation for deep linking (must disable Flutter's built-in deep linking to avoid conflicts with AppsFlyer)
  - Replaced `effective_dart` with `flutter_lints` in development dependencies


## 6.17.5

- Updated to AppsFlyer SDK v6.17.5 for iOS

## 6.17.3

- Updated to AppsFlyer SDK v6.17.3 for both Android and iOS
- Added validateAndLogInAppPurchaseV2 API (Beta) for improved cross-platform purchase validation
- Unified AFPurchaseDetails data structure for type-safe purchase validation
- Enhanced error handling and consistent API across Android and iOS
- Maintains backward compatibility with existing purchase validation methods

## 6.17.1

- Android: Bug fix for users who expirienced `NullPointerExceptions`.
- Android: added a new [disableAppSetId()](https://dev.appsflyer.com/hc/docs/android-sdk-reference-appsflyerlib#disableappsetid) method for AppSet ID opting-out.
- iOS: Added support for Google Integrated Conversion ([ICM](https://support.google.com/google-ads/answer/16203286)) measurement.
- Documentation small fixes.
- Purchase Connector is rolled out to production (StoreKit2 support will be enrolled on next release).

## 6.16.21

- Bug fix for users who reported Locale issue on Android, fixed Locale issue by forcing toUpperCase(Locale.ENGLISH)
- Expanded the unit–tests

## 6.16.2

- setConsentData is now deprecated!
- setConsentDataV2 is the new and recommended way to set manual user consent.
- Added getVersionNumber, returns the plugin's version.
- Fixed typos within the code.
- Fixed and updated tests and their frameworks.
- Push notification measurment API's documentation has been updated.
- Closed a few potential memory leaks.
- Update iOS version to 6.16.2
- Update Android version to 6.16.2

## 6.15.2

- Fixed NullPointerException issue on Android that some clients had.
- Fixed Android MediationNetwork enum issue.
- Update iOS version to 6.15.3
- Update Android version to 6.15.2

## 6.15.1

- Implementation of the new logAdRevenue API for iOS and Android
- Documentation update for the new logAdRevenue API
- Update iOS version to 6.15.1
- Update Android version to 6.15.1

## 6.14.3

- Fixed mapOptions issue with manualStart
- Inherit Privacy Manifest from the native iOS SDK via Cocoapods
- Bump iOS version to 6.14.3

## 6.14.2

- Bump version to iOS v6.14.2 and Android v6.14.0
- Added Privacy Manifest to support Apple latest changes: <https://developer.apple.com/documentation/bundleresources/privacy_manifest_files>

## 6.13.2+1

- Hotfix for manualStart on iOS

## 6.13.2

- Added new APIs such as `anonymizeUser` , `performOnDeepLinking`
- Added to the `startSDK` API, `onSuccess` and `onError` callbacks
- Update to iOS SDK to v6.13.2

## 6.13.0+2

- Update to iOS SDK to v6.13.1

## 6.13.0+1

- Added enableTCFDataCollection , setConsentData with AppsFlyerConsent class
- Added new boolean option to AppsFlyerOption class , manualStart
- Added startSDK API
- Updated readme and elaborated on the new APIs

## 6.12.2

- Update to Android SDK to v6.12.2 & iOS SDK to v6.12.2
- Deprecated CreateOneLinkHttpTask updated to LinkGenerator
- Fixed Gradle 8.0 issue
- Documented API and removed unused imports

## 6.11.3

- null pointer exception fix for android, push notification bug fix & ios sdk 6.11.2

## 6.11.2

- update to Android SDK to v6.11.2

## 6.11.1

- update to Android SDK to v6.11.1

## 6.10.1

- update to Android SDK to v6.10.3 & iOS SDK to v6.10.1

## 6.9.3

- update to Android SDK to v6.9.3 & iOS SDK to v6.9.1
- Added `addPushNotificationDeepLinkPath` API
- Added `setCustomerIdAndLogSession` API for android

## 6.8.2

- update to android v6.8.2

## 6.8.0

- The API `enableLocationCollection` has been removed.
- The API `setDisableNetworkData` has been added.
- The AD_ID permission has been added to the plugin.
- Updated AppsFlyer Android SDK to v6.8.0
- Updated AppsFlyer iOS SDK to v6.8.0

## 6.5.2+2

## 6.5.2+1

- New APIs: getOutOfStore, setOutOfStore, setResolveDeepLinkURLs, setPartnerData

## 6.5.2

- Updated AppsFlyer Android SDK to v6.5.2
- Updated AppsFlyer iOS SDK to v6.5.2

## 6.4.4+2

## 6.4.0+2

## 6.4.0+1

- Added nullable in deeplink object
- Remove of local stream import

## 6.4.0

- Updated to 6.4.0 in iOS & Android SDK
- Dedicated class for UDL for handling deeplink
- New API `setSharingFilterForPartners`.`setSharingFilter` & `setSharingFilterForAllPartners` APIs were deprecated.
- setIntent is not required anymore in MainActivity (Android)
- application(_:open:sourceApplication:annotation:) is not required anymore in AppDelegate (iOS)
- application(_:open:options:) is not required anymore in AppDelegate (iOS)
- application(_:continue:restorationHandler:) is not required anymore in AppDelegate (iOS)

## 6.3.5+3

rollback to previous version

## 6.3.5+2

Removed streams from the plugin

## 6.3.5+1

Added setCurrentDeviceLanguage API

## 6.3.5

- Updated AppsFlyer iOS SDK to v6.3.5

## 6.3.3+1

- fix JNI issue

## 6.3.3-nullsafety.0

- change to local broadcast

## 6.3.2-nullsafety.0

- Update to SDK v6.3.2 and added support for disabling advertiser ID on Android

## 6.3.0-nullsafety.1

- Added effective dart package for linter rules

## 6.3.0-nullsafety.0

- Update iOS & Android to SDK v6.3.0

## 6.2.6-nullsafety.1

- Fix for deeplinking in iOS

## 6.2.6-nullsafety.0

- Update for iOS SDK V6.2.6
- Refactoring for SKAD network feature

## 6.2.4-nullsafety.5

- Added support for strict mode (kids app)
- Added support for wait for att status API

## 6.2.4+4-nullsafety

- Fix small bug with validateAndLogInAppIosPurchase API

## 6.2.4+3-nullsafety

- Small fix for enableFacebookDeferredApplinks, useReceiptValidationSandbox, disableSKAdNetwork, setPushNotification APIs in iOS

## 6.2.4+2-nullsafety

- Added disable SKAD API

## 6.2.4+1-nullsafety

- Fix for SKAD

## 6.2.4

- Update to iOS SDK v6.2.4

## 6.2.3+2

- Flutter 2.0 update including null safety support

## 6.2.3+2-beta

- Flutter 2.0 update including null safety support

## 6.2.3+1

- Added enableFacebookDeferredApplinks API

## 6.2.3

- Update to iOS SDK V6.2.3

## 6.2.1+7

- Refactor for user invite feature

## 6.2.1+6

- Added callbacks support for purchase validation API

## 6.2.1+5

- Added support for useReceiptValidationSandbox API

## 6.2.1+4

- Seperated purchase validation API to iOS/Android

## 6.2.1+3

- Fixed Unified deeplink crush on first launch

## 6.2.1+2

- Hot Fix

## 6.2.1+1

- Added support for push notification API

## 6.2.1

- Update iOS to v6.2.1
- Added support for Unified Deeplink
- Fixed deeplinks issues both for Android & iOS

## 6.2.0+2

- Revert back to version 6.2.0

## 6.2.0+1

- Added Unified Deeplinking for Android

## 6.2.0

- Update both iOS & Android to v6.2.0

## 6.0.5+3

- Fixed `FormatException` caused by iOS side

## 6.0.5+2

- Switch to callbacks for `onAppOpenAttribution` and `onConversionData`

## 6.0.5+1

- Fixed `updateServerUninstallToken` on iOS

## 6.0.5

- Update SDK version to:
  - Android: 5.4.5
  - iOS: 6.0.5
- Update Google install referrer to 2.1
- Added support for: <https://support.appsflyer.com/hc/en-us/articles/207032066#additional-apis-kids-apps>
- Fixed typo in `validateAndLogInAppPurchase`

## 6.0.3+5

- Add null check for context in Android

## 6.0.3+4

- Fixed bug with sending arguments with methodChannel

## 6.0.3+3

- Added the functions:
`logCrossPromotionAndOpenStore`
`logCrossPromotionImpression`
`setAppInviteOneLinkID`
`generateInviteLink`

## 6.0.3+2

- Removed AppTrackingTransparency framework

## 6.0.3+1

- Updated AppsFlyer iOS SDK to v6.0.3

## 6.0.2+1

- Fixed the issue in the example app on Android platform
- Updated AppsFlyer SDK to v5.4.3

## 6.0.2

- iOS sdk version is now 6.0.2 and support AppTrackingTransparency framework
- Android sdk version is 5.4.1

## 5.4.1+1

- Added documentation
- Added secured links to README

## 5.4.1

- Updated AppsFlyer SDK to v5.4.1
- Added `sharedFilter` support

## 5.2.0+3

- Add support for opt-in/ opt-out scenarios
- Fix typo in constant AF_VALIDATE_PURCHASE

## 5.2.0+2

- added default values to `initSdk` params

## 5.2.0+1

- Removed the use of RxDart
- Checked that the streams are not closed before sending events

## 5.2.0

- AppsFlyer sdk version is updated to v5.2.0
- Switched `StreamController` to `BehaviourSubject` to fix bad state related to unclosed streams

## 1.2.5

- `initSdk` now uses Future.delayed
- Fixed iOS error in `initSdk` returned String instead of Map

## 1.2.3

- Updated the README
- `initSdk` function now uses named parameters

## 1.2.2

- Updated AppsFlyer SDK version:
  - Android: v5.1.1
  - iOS: v5.1.0
- Added `getSdkVersion` to the api
- Changed `initSdk` to return a dynamic map

## 1.1.3

- Added getAppsFlyerUID function to get a device unique user id

## 1.1.2

- Updated appsflyer framework to 4.9.0

## 1.1.0

- Added the following functions:
  - `Stream validateAndTrackInAppPurchase( String publicKey, String signature, String purchaseData, String price, String currency, Map<String, String> additionalParameters)`
  - `void updateServerUninstallToken(String token)`
  - `Future<String> getHostPrefix()`
  - `Future<String> getHostName()`
  - `void setHost(String hostPrefix, String hostName)`
  - `void setCollectIMEI(bool isCollect)`
  - `void setCollectAndroidId(bool isCollect)`
  - `void setAdditionalData(Map addionalData)`
  - `void waitForCustomerUserId(bool wait)`
  - `void setCustomerUserId(String userId)`
  - `void enableLocationCollection(bool flag)`
  - `void setAndroidIdData(String androidIdData)`
  - `void setImeiData(String imei)`
  - `void enableUninstallTracking(String senderId)`
  - `void setIsUpdate(bool isUpdate)`
  - `void setCurrencyCode(String currencyCode)`
  - `void stopTracking(bool isTrackingStopped)`
  - `void setMinTimeBetweenSessions(int seconds)`
  - `void setUserEmails(List<String> emails, [EmailCryptType cryptType]`

- Fixed `onAppOpenAttribution` not being called bug

## 1.0.8

- Added `AppsFlyerOptions` to support easier options setup
- Changed plugin lib structure

## 1.0.6

- Fixed iOS app id crash

## 1.0.4

- Added dartdoc documentation.
- Changed static methods to class instance methods.

## 1.0.0

First stable version

## 0.0.5

- Changed access modifiers from public to private to class variables

## 0.0.3

Supported sdk functions:

- initSdk
- trackEvent
- registerConversionDataCallback
- registerOnAppOpenAttributionCallback

## 0.0.1

Initial release.
