# Versions

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
