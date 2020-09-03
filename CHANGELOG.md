# Versions

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
