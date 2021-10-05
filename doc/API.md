# API

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

## Types
- [AppsFlyerOptions](#appsflyer-options)

## Methods
- [initSdk](#initSdk)
- [onAppOpenAttribution](#onAppOpenAttribution)
- [onInstallConversionData](#onInstallConversionData)
- [onDeepLinking](#onDeepLinking)
- [logEvent](#logEvent)

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
- [Validate Purchase](#validatePurchase)
- [setPushNotification](#setPushNotification)
- [User Invite](#userInvite)
- [enableFacebookDeferredApplinks](#enableFacebookDeferredApplinks)
- [disableSKAdNetwork](#disableSKAdNetwork)
- [getAppsFlyerUID](#getAppsFlyerUID)
- [setCurrentDeviceLanguage](#setCurrentDeviceLanguage)
- [setSharingFilterForPartners](#setSharingFilterForPartners)
- [setOneLinkCustomDomain](#setOneLinkCustomDomain)
---

##### <a id="appsflyer-options"> **`AppsflyerSdk(Map options)`** 

| parameter | type  | description       |
| --------- | ----- | ----------------- |
| `appsFlyerOptions` | `Map` | SDK configuration |

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

Map appsFlyerOptions = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

```

**Or you can use `AppsFlyerOptions` class instead**

##### **`AppsflyerSdk(Map options)`**

| parameter | type               | description       |
| --------- | ------------------ | ----------------- |
| `appsFlyerOptions` | `AppsFlyerOptions` | SDK configuration |

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

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk _appsflyerSdk = AppsflyerSdk({...});

_appsflyerSdk.initSdk(   
  registerConversionDataCallback: true, 
  registerOnAppOpenAttributionCallback: true, 
  registerOnDeepLinkingCallback: true)
```

---
#### <a id="onAppOpenAttribution"> **`onAppOpenAttribution(Func)`
- Trigger callback when onAppOpenAttribution is activated on the native side

_Example:_

```dart
_appsflyerSdk.onAppOpenAttribution((res) {
      print("res: " + res.toString());
    });
```

#### <a id="onInstallConversionData"> **`onInstallConversionData(Func)`
- Trigger callback when onInstallConversionData is activated on the native side

_Example:_

```dart
    _appsflyerSdk.onInstallConversionData((res) {
      print("res: " + res.toString());
    });
```

#### <a id="onDeepLinking"> **`onDeepLinking(Func)`
- Trigger callback when onDeepLinking is activated on the native side

_Example:_

```dart
    _appsflyerSdk.onDeepLinking((res) {
      print("res: " + res.toString());
    });
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
You can set this function to `true` if you don't want to log events without setting customer id first.

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
**<a id="validatePurchase"> Validate Purchase**


***Android:***

`Future<dynamic> validateAndLogInAppAndroidPurchase( 
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String> additionalParameters)`

_Example:_
```dart
appsFlyerSdk.validateAndLogInAppAndroidPurchase(
           "publicKey",
           "signature",
           "purchaseData",
           "price",
           "currency",
           {"fs": "fs"});
```

***iOS:***

**`Future<dynamic> validateAndLogInAppIosPurchase( 
      String productIdentifier,
      String price,
      String currency,
      String transactionId,
      Map<String, String> additionalParameters)`**

_Example:_
```dart
appsFlyerSdk.validateAndLogInAppIosPurchase(
           "productIdentifier",
           "price",
           "currency",
           "transactionId",
           "additionalParameters");
```

***Purchase validation sandbox mode for iOS:***

`void useReceiptValidationSandbox(bool isSandboxEnabled)`

_Example:_
```dart
appsFlyerSdk.useReceiptValidationSandbox(true);
```

***Purchase validation callback***

`void onPurchaseValidation(Function callback)`

_Example:_
```dart
appsflyerSdk.onPurchaseValidation((res){
  print("res: " + res.toString());
});
```

---
**<a id="setPushNotification"> `void setPushNotification(bool isEnabled)`**

_Example:_
```dart
appsFlyerSdk.setPushNotification(true);
```

_NOTE:_ 

For Android: Make sure to call this API inside the page of every activity that is launched after clicking the notification.

For iOS: This API can be called once at the initalization phase.

Please check the following guide in order to understand the relevant payload needed for AppsFlyer to attribute the push notification:

https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-push-notification-re-engagement-campaigns

---
**<a id="userInvite"> User Invite**

1. First define the Onelink ID (find it in the AppsFlyer dashboard in the onelink section:

  **`Future<void> setAppInviteOneLinkID(String oneLinkID, Function callback)`**

2. Set the AppsFlyerInviteLinkParams class to set the query params in the user invite link:

```dart
class AppsFlyerInviteLinkParams {
  final String channel;
  final String campaign;
  final String referrerName;
  final String referreImageUrl;
  final String customerID;
  final String baseDeepLink;
  final String brandDomain;
}
```

3. Call the generateInviteLink API to generate the user invite link. Use the success and error callbacks for handling.

  **`void generateInviteLink(AppsFlyerInviteLinkParams parameters, Function success, Function error)`**


_Example:_
```dart
appsFlyerSdk.setAppInviteOneLinkID('OnelinkID', 
(res){ 
  print("setAppInviteOneLinkID callback: $res"); 
});

AppsFlyerInviteLinkParams inviteLinkParams = new AppsFlyerInviteLinkParams(
      channel: "",
      referrerName: "",
      baseDeepLink: "",
      brandDomain: "",
      customerID: "",
      referreImageUrl: "",
      campaign: ""
);

appsFlyerSdk.generateInviteLink(inviteLinkParams, 
  (result){ 
    print(result); 
  }, 
  (error){ 
    print(error);
  }
);
```
---
**<a id="enableFacebookDeferredApplinks"> `void enableFacebookDeferredApplinks(bool isEnabled)`**

Please make sure the relevant Facebook dependecies are added to the project!

For more information check the following article:
https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#advanced-using-facebook-ads-appsflyer-sdks-for-deferred-deep-linking

_Example:_
```dart
appsFlyerSdk.enableFacebookDeferredApplinks(true);
```
---
**<a id="disableSKAdNetwork"> `void disableSKAdNetwork(bool isEnabled)`**

Use this API in order to disable the SK Ad network (request will be sent but the rules won't be returned).

_Example:_
```dart
appsFlyerSdk.disableSKAdNetwork(true);
```
---
**<a id="getAppsFlyerUID"> `Future<String?> getAppsFlyerUID() async`**

Use this API in order to get the AppsFlyer ID.

_Example:_
```dart
appsFlyerSdk.getAppsFlyerUID().then((AppsFlyerId) {
  print("AppsFlyer ID: ${AppsFlyerId}");
});
```
---
**<a id="setCurrentDeviceLanguage"> `void setCurrentDeviceLanguage(string language)`**

Use this API in order to set the language

_Example:_
```dart
appsFlyerSdk.setCurrentDeviceLanguage("en");
```
---
**<a id="setSharingFilterForPartners"> `void setSharingFilterForPartners(List<String> partners)`**

`setSharingFilter` & `setSharingFilterForAllPartners` APIs were deprecated! 

Use `setSharingFilterForPartners` instead.

Used by advertisers to exclude specified networks/integrated partners from getting data. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

_Example:_
```dart
appsFlyerSdk.setSharingFilterForPartners([]);                                        // Reset list (default)
appsFlyerSdk.setSharingFilterForPartners(null);                                      // Reset list (default)
appsFlyerSdk.setSharingFilterForPartners(['facebook_int']);                          // Single partner
appsFlyerSdk.setSharingFilterForPartners(['facebook_int', 'googleadwords_int']);     // Multiple partners
appsFlyerSdk.setSharingFilterForPartners(['all']);                                   // All partners
appsFlyerSdk.setSharingFilterForPartners(['googleadwords_int', 'all']);              // All partners
```

---
**<a id="setOneLinkCustomDomain"> `void setOneLinkCustomDomain(List<String> brandDomains)`**

Use this API in order to set branded domains. 

Find more information in the [following article on branded domains](https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links). 

_Example:_
```dart
appsFlyerSdk.setOneLinkCustomDomain(["promotion.greatapp.com","click.greatapp.com","deals.greatapp.com"]);
```
---