# Versions
## 6.14.3
- Fixed mapOptions issue with manualStart
- Inherit Privacy Manifest from the native iOS SDK via Cocoapods
- Bump iOS version to 6.14.3
## 6.14.2
- Bump version to iOS v6.14.2 and Android v6.14.0
- Added Privacy Manifest to support Apple latest changes: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files 
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
- Added support for: https://support.appsflyer.com/hc/en-us/articles/207032066#additional-apis-kids-apps
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
