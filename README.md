<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="200">

# appsflyer_sdk

A Flutter plugin for AppsFlyer SDK.

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk) 
In order for us to provide optimal support, we would kindly ask you to submit any issues to support@appsflyer.com


When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , reproduction steps, logs, code snippets and any additional relevant information.



---

### Supported Platforms

- Android
- iOS 8+

### This plugin is built for

- iOS AppsFlyerSDK **v4.8.12**
- Android AppsFlyerSDK **v4.8.20**

##<a id="api-methods"> API Methods

---
## **Getting started**
In order to install the plugin, visit [this](https://pub.dartlang.org/packages/appsflyer_sdk#-installing-tab-) page.

To start using AppsFlyer you first need to create an instance of `AppsflyerSdk` before using any other of our sdk functionalities.  

##### **`AppsflyerSdk(Map options)`** 

| parameter | type  | description       |
| --------- | ----- | ----------------- |
| `options` | `Map` | SDK configuration |

**`options`**

| name       | type      | default | description                                                                                                                    |
| ---------- | --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `afDevKey` | `string`  |         | [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android)               |
| `afAppId`  | `string`  |         | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |
| `isDebug`  | `boolean` | `false` | debug mode (optional)                                                                                                          |

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

Map options = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

```

**Or you can use `AppsFlyerOptions` class instead**

##### **`AppsflyerSdk(Map options)`**

| parameter | type               | description       |
| --------- | ------------------ | ----------------- |
| `options` | `AppsFlyerOptions` | SDK configuration |

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

final AppsFlyerOptions options = AppsFlyerOptions(afDevKey: "af dev key",
                                                  showDebug: true,
                                                  appId: "123456789");
```

Once `AppsflyerSdk` object is created, you can call `initSdk` method.

##### **`static Future<dynamic> initSdk() async`**

initialize the SDK, using the options initialized from the constructor|

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk appsflyerSdk = AppsflyerSdk({...});

try {
      result = await appsflyerSdk.initSdk();
    } on Exception catch (e) {
      print("error: " + e.toString());
      return;
    }

```

---
##### **`static Future<bool> trackEvent(String eventName, Map eventValues) async`** (optional)

- These in-app events help you track how loyal users discover your app, and attribute them to specific
  campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.

| parameter     | type     | description                                                                                                                                                                       |
| ------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventName`   | `String` | custom event name, is presented in your dashboard. See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h) |
| `eventValues` | `Map`    | event details                                                                                                                                                                     |

_Example:_

```dart
Future<bool> sendEvent(String eventName, Map eventValues) async {
    bool result;
    try {
      result = await appsflyerSdk.trackEvent(eventName, eventValues);
    } on Exception catch (e) {}
      print("Result trackEvent: ${result}");
  }
```

---

##### **Conversion Data and on app open attribution**

Returns `Stream`. Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](http://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](http://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data as JSON `Map` in `Stream`.

##### **`static Stream<dynamic> registerConversionDataCallback()`**

_Example:_

```dart
appsflyerSdk.registerConversionDataCallback().listen((data) {
      //print("GCD: " + data.toString());
      //....
    }).onError((handleError) {
      print("error");
    });
```

_Example of success Organic response:_

```
{
  "status": "success",
  "type": "onInstallConversionDataLoaded",
  "data": {
    "af_status": "Organic",
    "af_message": "organic install",
    "is_first_launch": "false"
  }
}
```

_Example of failure response:_

```
{
  "status": "failure",
  "type": "onInstallConversionDataLoaded",
  "data": "SOME_ERROR_MESSAGE"
}
```
#### Deep Link
In case you want to use [deep links](https://en.wikipedia.org/wiki/Deep_linking) in your app, you will need to use `registerOnAppOpenAttributionCallback` on the `AppsflyerSdk` instance you've created. 
##### **`static Stream<dynamic> registerOnAppOpenAttributionCallback()`**

_Example:_

```dart
appsflyerSdk.registerOnAppOpenAttributionCallback().listen((data) {
      //print("OnAppOpenAttribution: " + data.toString());
      //....
    }).onError((handleError) {
      print("error");
    });
```

_Example of response on deep-link "https://flutter.demo" :_

```
{
  "status": "success",
  "type": "onAppOpenAttribution",
  "data": {
    "link": "https://flutter.demo"
  }
}
```

---
#### Other functionalities:
**`void setUserEmails(List<String> emails, [EmailCryptType cryptType]`**
Set the user emails with the given encryption (`EmailCryptTypeNone, EmailCryptTypeSHA1, EmailCryptTypeMD5, EmailCryptTypeSHA256`). the default encryption is `EmailCryptTypeNone`.
_Example:_
```dart
appsFlyerSdk.setUserEmails(
       ["a@a.com", "b@b.com"], EmailCryptType.EmailCryptTypeSHA1);
```
**`void setMinTimeBetweenSessions(int seconds)`**
You can set the minimum time between session (the default is 5 seconds)
```dart
appsFlyerSdk.setMinTimeBetweenSessions(3)
```
**`void stopTracking(bool isTrackingStopped)`**
You can stop sending events to Appsflyer by using this method.
_Example:_
```dart
widget.appsFlyerSdk.stopTracking(true);
```
**`void setCurrencyCode(String currencyCode)`**
_Example:_
```dart
appsFlyerSdk.setCurrencyCode("currencyCode");
```
**`void setIsUpdate(bool isUpdate)`**
_Example:_
```dart
appsFlyerSdk.setIsUpdate(true);
```
**`void enableUninstallTracking(String senderId)`**
_Example:_
```dart
appsFlyerSdk.enableUninstallTracking("senderId");
```
**`void setImeiData(String imei)`**
_Example:_
```dart
appsFlyerSdk.setImeiData("imei");
```
**`void setAndroidIdData(String androidIdData)`**
_Example:_
```dart
appsFlyerSdk.setAndroidIdData("androidId");
```
**`void enableLocationCollection(bool flag)`**
_Example:_
```dart
appsFlyerSdk.enableLocationCollection(true);
```
**`void setCustomerUserId(String userId)`**
[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)
_Example:_
```dart
appsFlyerSdk.setCustomerUserId("id");
```
**`void waitForCustomerUserId(bool wait)`**
You can set this function to `true` if you don't want to track events without setting customer id first.
_Example:_
```dart
appsFlyerSdk.waitForCustomerUserId(true);
```
**`void setAdditionalData(Map addionalData)`**
_Example:_
```dart
appsFlyerSdk.setAdditionalData({"customData": "data"});
```
**`void setCollectAndroidId(bool isCollect)`**
_Example:_
```dart
appsFlyerSdk.setCollectAndroidId(true);
```
**`void setCollectIMEI(bool isCollect)`**
_Example:_
```dart
appsFlyerSdk.setCollectIMEI(false);
```
**`void setHost(String hostPrefix, String hostName)`**
You can change the default host (appsflyer) by using this function
_Example:_
```dart
appsFlyerSdk.setHost("pref", "my-host");
```
**`Future<String> getHostName()`**
_Example:_
```dart
appsFlyerSdk.getHostName().then((name) {
         print("Host name: ${name}");
       });
```
**`Future<String> getHostPrefix()`**
_Example:_
```dart
appsFlyerSdk.getHostPrefix().then((name) {
         print("Host prefix: ${name}");
       });
```
**`void updateServerUninstallToken(String token)`**
_Example:_
```dart
appsFlyerSdk.updateServerUninstallToken("token");
```
**`Stream validateAndTrackInAppPurchase( String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String> additionalParameters)`**
_Example:_
```dart
appsFlyerSdk.validateAndTrackInAppPurchase(
           "publicKey",
           "signature",
           "purchaseData",
           "price",
           "currency",
           {"fs": "fs"}).listen((data) {
         print(data);
       }).onError((error) {
         print(error);
       });
```
