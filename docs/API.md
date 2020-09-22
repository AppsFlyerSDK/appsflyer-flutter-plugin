# API

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

## Types
- [AppsFlyerOptions](#appsflyer-options)

## Methods
- [initSdk](#initSdk)
- [logEvent](#logEvent)
- [conversionDataStream](#gcd)
- [appOpenAttributionStream](#oaoa)
- [setUserEmails](#setUserEmails)
- [setMinTimeBetweenSessions](#setMinTimeBetweenSessions)
- [stop](#stop)
- [setCurrencyCode](#setCurrencyCode)
- [setIsUpdate](#setIsUpdate)
- [enableUninstallTracking](#enableUninstallTracking)
- [setImeiData](#setImeiData)
- [setAndroidIdData](#setAndroidIdData)
- [enableLocationCollection](#enableLocationCollection)
- [setCustomerUserId](#setCustomerUserId)
- [waitForCustomerUserId](#waitForCustomerUserId)
- [setAdditionalData](#setAdditionalData)
- [setCollectAndroidId](#setCollectAndroidId)
- [setCollectIMEI](#setCollectIMEI)
- [setHost](#setHost)
- [getHostName](#getHostName)
- [getHostPrefix](#getHostPrefix)
- [updateServerUninstallToken](#updateServerUninstallToken)
- [validateAndTrackInAppPurchase](#validateAndTrackInAppPurchase)

---

##### <a id="appsflyer-options"> **`AppsflyerSdk(Map options)`** 

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

---

##### <a id="initSdk"> **`initSdk({bool registerConversionDataCallback, bool registerOnAppOpenAttributionCallback}) async` (Changed in 1.2.2)**

initialize the SDK, using the options initialized from the constructor|
Return response object with the field `status`
The user can access `conversionDataStream` and `appOpenAttributionStream` to listen for events (see example app)

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk _appsflyerSdk = AppsflyerSdk({...});

FutureBuilder<dynamic> ( future: _appsflyerSdk.initSdk(registerConversionDataCallback: true, registerOnAppOpenAttributionCallback: true), builder: (BuildContext context, AsyncSnapshot snapshot) {
  if (snapshot.hasData)
    return  HomeContainer(
      onData: _appsflyerSdk.conversionDataStream,
      onAttribution: _appsflyerSdk.appOpenAttributionStream,
      ...
    )
  ...

```

---
##### <a id="logEvent"> **`logEvent(String eventName, Map eventValues)`**

- These in-app events help you to understand how loyal users discover your app, and attribute them to specific
  campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  to send ROI (Return on Investment) and LTV (Lifetime Value).
- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.

| parameter     | type     | description                                                                                                                                                                       |
| ------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventName`   | `String` | custom event name, is presented in your dashboard. See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h) |
| `eventValues` | `Map`    | event details                                                                                                                                                                     |

_Example:_

```dart
Future<bool> logEvent(String eventName, Map eventValues) async {
    bool result;
    try {
      result = await appsflyerSdk.logEvent(eventName, eventValues);
    } on Exception catch (e) {}
      print("Result logEvent: ${result}");
  }
```

---

### **Conversion Data and on app open attribution**

##### <a id="gcd"> **conversionDataStream** (field of `AppsflyerSdk` instance)
Returns `Stream`. Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](https://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](https://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data as JSON `Map` in `Stream`.

_Example:_

```dart
StreamBuilder<dynamic>(
    stream: _appsflyerSdk.conversionDataStream?.asBroadcastStream(),
    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        ...
    }
)
```

_Example of success Organic response:_

```json
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

```json
{
  "status": "failure",
  "type": "onInstallConversionDataLoaded",
  "data": "SOME_ERROR_MESSAGE"
}
```
##### <a id="oaoa"> **appOpenAttributionStream**  (field of `AppsflyerSdk` instance)
In case you want to use [deep links](https://en.wikipedia.org/wiki/Deep_linking) in your app, you will need to use `registerOnAppOpenAttributionCallback` on the `AppsflyerSdk` instance you've created.  
_Example:_

```dart
StreamBuilder<dynamic>(
    stream: _appsflyerSdk.appOpenAttributionStream?.asBroadcastStream(),
    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        ...
    }
)
```

_Example of response on deep-link "https://flutter.demo" :_

```json
{
  "status": "success",
  "type": "onAppOpenAttribution",
  "data": {
    "link": "https://flutter.demo"
  }
}
```

---

## Other functionalities:
**<a id="setUserEmails"> `setUserEmails(List<String> emails, [EmailCryptType cryptType])`**

Set the user emails with the given encryption (`EmailCryptTypeNone, EmailCryptTypeSHA1, EmailCryptTypeMD5, EmailCryptTypeSHA256`). the default encryption is `EmailCryptTypeNone`.

_Example:_
```dart
appsFlyerSdk.setUserEmails(
       ["a@a.com", "b@b.com"], EmailCryptType.EmailCryptTypeSHA1);
```
---
**<a id="setMinTimeBetweenSessions"> `void setMinTimeBetweenSessions(int seconds)`**
You can set the minimum time between session (the default is 5 seconds)
```dart
appsFlyerSdk.setMinTimeBetweenSessions(3)
```
---
**<a id="stop"> `void stop(bool isStopped)`**
You can stop sending events to Appsflyer by using this method.

_Example:_
```dart
widget.appsFlyerSdk.stop(true);
```
---
**<a id="setCurrencyCode"> `void setCurrencyCode(String currencyCode)`**

_Example:_
```dart
appsFlyerSdk.setCurrencyCode("currencyCode");
```
---
**<a id="setIsUpdate"> `void setIsUpdate(bool isUpdate)`**

_Example:_
```dart
appsFlyerSdk.setIsUpdate(true);
```
---
**<a id="enableUninstallTracking"> `void enableUninstallTracking(String senderId)`**

_Example:_
```dart
appsFlyerSdk.enableUninstallTracking("senderId");
```
---
**<a id="setImeiData"> `void setImeiData(String imei)`**

_Example:_
```dart
appsFlyerSdk.setImeiData("imei");
```
---
**<a id="setAndroidIdData"> `void setAndroidIdData(String androidIdData)`**

_Example:_
```dart
appsFlyerSdk.setAndroidIdData("androidId");
```
---
**<a id="enableLocationCollection"> `void enableLocationCollection(bool flag)`**

_Example:_
```dart
appsFlyerSdk.enableLocationCollection(true);
```
---
**<a id="setCustomerUserId"> `void setCustomerUserId(String userId)`**
[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)

_Example:_
```dart
appsFlyerSdk.setCustomerUserId("id");
```
---
**<a id="waitForCustomerUserId"> `void waitForCustomerUserId(bool wait)`**
You can set this function to `true` if you don't want to track events without setting customer id first.

_Example:_
```dart
appsFlyerSdk.waitForCustomerUserId(true);
```
---
**<a id="setAdditionalData"> `void setAdditionalData(Map addionalData)`**

_Example:_
```dart
appsFlyerSdk.setAdditionalData({"customData": "data"});
```
---
**<a id="setCollectAndroidId"> `void setCollectAndroidId(bool isCollect)`**

_Example:_
```dart
appsFlyerSdk.setCollectAndroidId(true);
```
---
**<a id="setCollectIMEI"> `void setCollectIMEI(bool isCollect)`**  
_NOTE:_ Make sure to add `<uses-permission android:name="android.permission.READ_PHONE_STATE" />` in the AndroidManifest and request these permissions in the runtime in order for the SDK to be able to collect IMEI

_Example:_
```dart
appsFlyerSdk.setCollectIMEI(false);
```
---
**<a id="setHost"> `void setHost(String hostPrefix, String hostName)`**
You can change the default host (appsflyer) by using this function

_Example:_
```dart
appsFlyerSdk.setHost("pref", "my-host");
```
---
**<a id="getHostName"> `Future<String> getHostName()`**

_Example:_
```dart
appsFlyerSdk.getHostName().then((name) {
         print("Host name: ${name}");
       });
```
---
**<a id="getHostPrefix"> `Future<String> getHostPrefix()`**

_Example:_
```dart
appsFlyerSdk.getHostPrefix().then((name) {
         print("Host prefix: ${name}");
       });
```
---
**<a id="updateServerUninstallToken"> `void updateServerUninstallToken(String token)`**

_Example:_
```dart
appsFlyerSdk.updateServerUninstallToken("token");
```
---
**<a id="validateAndTrackInAppPurchase"> `Stream validateAndTrackInAppPurchase( String publicKey,
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
