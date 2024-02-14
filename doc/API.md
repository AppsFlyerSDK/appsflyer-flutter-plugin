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
- [setCustomerIdAndLogSession](#setCustomerIdAndLogSession)
- [waitForCustomerUserId](#waitForCustomerUserId)
- [setAdditionalData](#setAdditionalData)
- [setCollectAndroidId](#setCollectAndroidId)
- [setCollectIMEI](#setCollectIMEI)
- [setHost](#setHost)
- [getHostName](#getHostName)
- [getHostPrefix](#getHostPrefix)
- [updateServerUninstallToken](#updateServerUninstallToken)
- [Validate Purchase](#validatePurchase)
- [setPushNotification](#setPushNotification)[DEPRECATED]
- [sendPushNotificationData](#sendPushNotificationData)
- [addPushNotificationDeepLinkPath](#addPushNotificationDeepLinkPath)
- [User Invite](#userInvite)
- [enableFacebookDeferredApplinks](#enableFacebookDeferredApplinks)
- [enableTCFDataCollection](#enableTCFDataCollection)  <!-- New addition -->
- [setConsentData](#setConsentData)
- [disableSKAdNetwork](#disableSKAdNetwork)
- [getAppsFlyerUID](#getAppsFlyerUID)
- [setCurrentDeviceLanguage](#setCurrentDeviceLanguage)
- [setSharingFilterForPartners](#setSharingFilterForPartners)
- [setOneLinkCustomDomain](#setOneLinkCustomDomain)
- [setDisableAdvertisingIdentifiers](#setDisableAdvertisingIdentifiers)
- [setPartnerData](#setPartnerData)
- [setResolveDeepLinkURLs](#setResolveDeepLinkURLs)
- [setOutOfStore](#setOutOfStore)
- [getOutOfStore](#getOutOfStore)
- [setDisableNetworkData](#setDisableNetworkData)

---

##### <a id="appsflyer-options"> **`AppsflyerSdk(Map options)`** 

| parameter | type  | description       |
| --------- | ----- | ----------------- |
| `appsFlyerOptions` | `Map` | SDK configuration |

**`options`**

                                                                                                        |
| Setting  | Type   | Description   |
| -------- | -------- | ------------- |
| devKey   | String | Your application's [devKey](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#retrieving-the-dev-key) provided by AppsFlyer (required)  |
| appId      | String | Your application's [App ID](https://support.appsflyer.com/hc/en-us/articles/207377436-Adding-a-new-app#available-in-the-app-store-google-play-store-windows-phone-store)  (required for iOS only) that you configured in your AppsFlyer dashboard  |
| showDebug    | bool | Debug mode - set to `true` for testing only, do not release to production with this parameter set to `true`! |
| timeToWaitForATTUserAuthorization  | double | Delays the SDK start for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out. |
| appInviteOneLink    | String | The [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) that is used to generate a User Invite, this is not a required field in the `AppsFlyerOptions`, you may choose to set it later via the appropriate API. |
| disableAdvertisingIdentifier| bool | Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA. |
| disableCollectASA | bool | Opt-out of the Apple Search Ads attributions. |



_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

Map appsFlyerOptions = { "afDevKey": afDevKey,
                "afAppId": appId,
                "showDebug": true};

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
##### <a id="logEvent"> **`logEvent(String eventName, Map? eventValues)`**

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
Future<bool?> logEvent(String eventName, Map? eventValues) async {
    bool? result;
    try {
        result = await appsflyerSdk.logEvent(eventName, eventValues);
    } on Exception catch (e) {}
    print("Result logEvent: $result");
}
```

---

## Other functionalities:

**<a id="setUserEmails"> `setUserEmails(List<String> emails, [EmailCryptType cryptType])`**

Set the user emails with the given encryption (`EmailCryptTypeNone, EmailCryptTypeSHA256`). the default encryption is `EmailCryptTypeNone`.

_Example:_
```dart
appsFlyerSdk.setUserEmails(
       ["a@a.com", "b@b.com"], EmailCryptType.EmailCryptTypeSHA256);
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

**Removed as of v6.8.0**

_Example:_
```dart
appsFlyerSdk.enableLocationCollection(true);
```
---
#### `<a id="enableTCFDataCollection"> enableTCFDataCollection(bool shouldCollect)`

The `enableTCFDataCollection` method is employed to control the automatic collection of the Transparency and Consent Framework (TCF) data. By setting this flag to `true`, the system is instructed to automatically garner TCF data. Conversely, setting it to `false` prevents such data collection.

_Example:_
```dart
appsFlyerSdk.enableTCFDataCollection(true);
```
---
#### `<a id="setConsentData"> setConsentData(Map<String, Object> consentData)`

The `AppsflyerConsent` object helps manage user consent settings. By using the setConsentData we able to manually collect the TCF data. You can create an instance for users subject to GDPR or otherwise:

1. Users subjected to GDPR:

```dart
var forGdpr = _appsflyerSdk.forGDPRUser(
    hasConsentForDataUsage: true, 
    hasConsentForAdsPersonalization: true
);
_appsflyerSdk.setConsentData(forGdpr);
```

2. Users not subject to GDPR:

```dart
var nonGdpr = _appsflyerSdk.nonGDPRUser();
_appsflyerSdk.setConsentData(nonGdpr);
```

The `_appsflyerSdk` handles consent data with `setConsentData` method, where you can pass the desired `AppsflyerConsent` instance.

---
To reflect TCF data in the conversion (first launch) payload, it's crucial to configure `enableTCFDataCollection` or `setConsentData` between the SDK initialization and start phase. Follow the example provided:

```dart
// Initialize SDK
final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15);

_appsflyerSdk = AppsflyerSdk(options);

// Set configurations to the SDK
// Enable TCF Data Collection
_appsflyerSdk.enableTCFDataCollection(true);

// Set Consent Data
// If user is subject to GDPR
// var forGdpr = _appsflyerSdk.forGDPRUser(hasConsentForDataUsage: true, hasConsentForAdsPersonalization: true);
// _appsflyerSdk.setConsentData(forGdpr);

// If user is not subject to GDPR
var nonGdpr = _appsflyerSdk.nonGDPRUser();
_appsflyerSdk.setConsentData(nonGdpr);

// Start the AppsFlyer SDK
await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);
```

Following this sequence ensures that the consent configurations take effect before the AppsFlyer SDK starts, providing accurate consent data in the first launch payload.

---
**<a id="setCustomerUserId"> `void setCustomerUserId(String userId)`**

[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)

_Example:_
```dart
appsFlyerSdk.setCustomerUserId("id");
```
---
**<a id="setCustomerIdAndLogSession"> `void setCustomerIdAndLogSession(String userId)` Android only!**

[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)

_Example:_
```dart
appsFlyerSdk.setCustomerIdAndLogSession("id");
```
---
**<a id="waitForCustomerUserId"> `void waitForCustomerUserId(bool wait)` Android only**

You can set this function to `true` if you don't want to log events without setting customer id first.

_Example:_
```dart
appsFlyerSdk.waitForCustomerUserId(true);
appsFlyerSdk.setCustomerIdAndLogSession("id");
```
---
**<a id="setAdditionalData"> `void setAdditionalData(Map additionalData)`**

_Example:_
```dart
var data = {"key1": "value1", "key2": "value2"};
appsFlyerSdk.setAdditionalData(data);
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
      Map<String, String>? additionalParameters)`

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
           {"fs": "fs"});
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
**<a id="setPushNotification"> `void setPushNotification(bool isEnabled)`[DEPRECATED]**

_Example:_
```dart
appsFlyerSdk.setPushNotification(true);
```
---
**<a id="sendPushNotificationData"> `void sendPushNotificationData(Map? userInfo)`**

Push-notification campaigns are used to create fast re-engagements with existing users.

[Learn more](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns)

For Android: AppsFlyer SDK uses the activity in order to process the push payload. Make sure you call this api when the app's activity is available (NOT dead state).

_Example:_
```dart
final Map userInfo = {
            "af":{
                "c": "test_campaign",
                "is_retargeting": true,
                "pid": "push_provider_int",
            },
            "aps":{
                "alert": "Get 5000 Coins",
                "badge": "37",
                "sound": "default"
            }
        };

appsFlyerSdk.sendPushNotificationData(userInfo);
```

---
**<a id="addPushNotificationDeepLinkPath"> `void addPushNotificationDeepLinkPath(List<String> deeplinkPath)`**

_Example:_
```dart
appsFlyerSdk.addPushNotificationDeepLinkPath(["deeply", "nested", "deep_link"]);
```

This call matches the following payload structure:

```json
{
  "deeply": {
      "nested": {
          "deep_link": "https://yourdeeplink2.onelink.me"
      }
  }
}
```
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
      campaign: "",
      customParams: {"key":"value"}
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
**<a id="setDisableAdvertisingIdentifiers"> `void setDisableAdvertisingIdentifiers(bool isSetDisableAdvertisingIdentifiersEnable)`**

Manually enable or disable Advertiser ID in Android & IDFA in iOS

_Example:_
```dart
  appsFlyerSdk.setDisableAdvertisingIdentifiers(true);
```
---
**<a id="setPartnerData"> `void setPartnerData(String partnerId, Map<String, Object> partnerData)`**

Allows sending custom data for partner integration purposes.

_Example:_
```dart
  Map<String, Object> partnerData = {"puid": "1234", "puid": '5678'};
  appsflyerSdk.setPartnerData("partnerId", partnerData);
```
---
**<a id="setResolveDeepLinkURLs"> `void setResolveDeepLinkURLs(List<String> urls)`**

Advertisers can wrap an AppsFlyer OneLink within another Universal Link. This Universal Link will invoke the app but any deep linking data will not propagate to AppsFlyer.

setResolveDeepLinkURLs enables you to configure the SDK to resolve the wrapped OneLink URLs, so that deep linking can occur correctly.

_Example:_
```dart
  appsflyerSdk.setResolveDeepLinkURLs(["clickdomain.com", "myclickdomain.com", "anotherclickdomain.com"]);
```
---
**<a id="setOutOfStore"> `void setOutOfStore(String sourceName)`**

**Android Only!**

Specify the alternative app store that the app is downloaded from.

_Example:_
```dart
  if(Platform.isAndroid){
    appsflyerSdk.setOutOfStore("facebook_int");
  }
```
---
**<a id="getOutOfStore"> `Future<String?> getOutOfStore()`**

**Android Only!**

Get the third-party app store referrer value.

_Example:_
```dart
  if(Platform.isAndroid){
    Future<String> store = appsflyerSdk.getOutOfStore();
    store.then((store) {
      print(store);
    });
  }
```
---
**<a id="setDisableNetworkData"> `void setDisableNetworkData(bool disable)`**

**Android Only!**

Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device.

_Example:_
```dart
  if(Platform.isAndroid){
    appsflyerSdk.setDisableNetworkData(true);
  }
```
---
