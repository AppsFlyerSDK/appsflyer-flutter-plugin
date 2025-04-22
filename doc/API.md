# API

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

## Types
- [AppsFlyerOptions](#appsflyer-options)
- [AdRevenueData](#AdRevenueData)
- [AFMediationNetwork](#AFMediationNetwork)

## Methods
- [initSdk](#initSdk)
- [startSDK](#startSDK)
- [onAppOpenAttribution](#onAppOpenAttribution)
- [onInstallConversionData](#onInstallConversionData)
- [onDeepLinking](#onDeepLinking)
- [logEvent](#logEvent)
- [anonymizeUser](#anonymizeUser)
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
- [sendPushNotificationData](#sendPushNotificationData)
- [addPushNotificationDeepLinkPath](#addPushNotificationDeepLinkPath)
- [User Invite](#userInvite)
- [enableFacebookDeferredApplinks](#enableFacebookDeferredApplinks)
- [enableTCFDataCollection](#enableTCFDataCollection)  <!-- New addition -->
- [setConsentData](#setConsentData) - [DEPRECATED]
- [setConsentDataV2](#setConsentDataV2)
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
- [performOnDeepLinking](#performondeeplinking)
- [logAdRevenue](#logAdRevenue)  - Since 6.15.1


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
| showDebug   | bool | Debug mode - set to `true` for testing only, do not release to production with this parameter set to `true`! |
| timeToWaitForATTUserAuthorization | double | Delays the SDK start for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out. |
| appInviteOneLink | String | The [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) that is used to generate a User Invite, this is not a required field in the `AppsFlyerOptions`, you may choose to set it later via the appropriate API. |
| disableAdvertisingIdentifier| bool | Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA. |
| disableCollectASA | bool | Opt-out of the Apple Search Ads attributions. |
| manualStart | bool | Prevents from the SDK from sending the launch request after using appsFlyer.initSdk(...). When using this property, the apps needs to manually trigger the appsFlyer.startSdk() API to report the app launch.|




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

##### <a id="AdRevenueData"> **`AdRevenueData`**

| parameter | type                | description       |
| --------- | ------------------ | ----------------- |
| `monetizationNetwork` | `String` |  |    
| `mediationNetwork` | `String` | value must be taken from `AFMediationNetwork` |    
| `currencyIso4217Code` | `String` |  |    
| `revenue` | `double` |  | 
| `additionalParameters` | `Map<String, dynamic>?` |  |    
    
---

##### <a id="AFMediationNetwork"> **`AFMediationNetwork`**
an enumeration that includes the supported mediation networks by AppsFlyer.


| networks | 
| -------- |
| ironSource
applovinMax
googleAdMob
fyber
appodeal
admost
topon
tradplus
yandex
chartboost
unity
toponPte
customMediation
directMonetizationNetwork     |

---


##### <a id="initSdk"> **`initSdk({bool registerConversionDataCallback, bool registerOnAppOpenAttributionCallback}) async` (Changed in 1.2.2)**

initialize the SDK, using the options initialized from the constructor|
Return response object with the field `status`

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk _appsflyerSdk = AppsflyerSdk({...});

await _appsflyerSdk.initSdk(   
  registerConversionDataCallback: true, 
  registerOnAppOpenAttributionCallback: true, 
  registerOnDeepLinkingCallback: true)
```

---
##### <a id="startSDK"> **`startSDK()` (Added in 6.13.0)**
In version 6.13.0 of the appslfyer-flutter-plugin SDK we added the option of splitting between the initialization stage and start stage. All you need to do is add the property manualStart: true to the init object, and later call appsFlyer.startSdk() whenever you decide. If this property is set to false or doesn't exist, the sdk will start after calling appsFlyer.initSdk(...).
```dart
_appsflyerSdk.startSDK();
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
**<a id="anonymizeUser"> `anonymizeUser(shouldAnonymize)`**

It is possible to anonymize specific user identifiers within AppsFlyer analytics.</br>
This complies with both the latest privacy requirements (GDPR, COPPA) and Facebook's data and privacy policies. To anonymize an app user.
| parameter                   | type     | description                                                |
| ----------                  |----------|------------------                                          |
| shouldAnonymize             | boolean  | True if want Anonymize user Data (default value is false). |

_Example:_
```dart
appsFlyerSdk.anonymizeUser(true);
```
---
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
**<a id="enableTCFDataCollection"> `enableTCFDataCollection(bool shouldCollect)`**

The `enableTCFDataCollection` method is employed to control the automatic collection of the Transparency and Consent Framework (TCF) data. By setting this flag to `true`, the system is instructed to automatically collect TCF data. Conversely, setting it to `false` prevents such data collection.

_Example:_
```dart
appsFlyerSdk.enableTCFDataCollection(true);
```
---
**<a id="setConsentData"> `setConsentData(Map<String, Object> consentData)`** *Deprecated*

The `AppsflyerConsent` object helps manage user consent settings. By using the setConsentData we able to manually collect the TCF data. You can create an instance for users subject to GDPR or otherwise:

1. Users subjected to GDPR:

```dart
var forGdpr = AppsFlyerConsent.forGDPRUser(
    hasConsentForDataUsage: true, 
    hasConsentForAdsPersonalization: true
);
_appsflyerSdk.setConsentData(forGdpr);
```

2. Users not subject to GDPR:

```dart
var nonGdpr = AppsFlyerConsent.nonGDPRUser();
_appsflyerSdk.setConsentData(nonGdpr);
```

The `_appsflyerSdk` handles consent data with `setConsentData` method, where you can pass the desired `AppsflyerConsent` instance.

---
To reflect TCF data in the conversion (first launch) payload, it's crucial to configure `enableTCFDataCollection` **or** `setConsentData` between the SDK initialization and start phase. Follow the example provided:

```dart
// Set AppsFlyerOption - make sure to set manualStart to true
final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15,
        manualStart: true);
_appsflyerSdk = AppsflyerSdk(options);

// Init the AppsFlyer SDK
_appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnAppOpenAttributionCallback: true,
    registerOnDeepLinkingCallback: true);

// Set configurations to the SDK
// Enable TCF Data Collection
_appsflyerSdk.enableTCFDataCollection(true);

// Set Consent Data
// If user is subject to GDPR
// var forGdpr = AppsFlyerConsent.forGDPRUser(hasConsentForDataUsage: true, hasConsentForAdsPersonalization: true);
// _appsflyerSdk.setConsentData(forGdpr);

// If user is not subject to GDPR
var nonGdpr = AppsFlyerConsent.nonGDPRUser();
_appsflyerSdk.setConsentData(nonGdpr);

// Here we start a session
_appsflyerSdk.startSDK(); 
```

Following this sequence ensures that the consent configurations take effect before the AppsFlyer SDK starts, providing accurate consent data in the first launch payload.
Note: You need to use either `enableTCFDataCollection` or `setConsentData` if you use both of them our backend will prioritize the provided consent data from `setConsentData`.

---
**<a id="setConsentDataV2"> `setConsentDataV2({bool? isUserSubjectToGDPR,
                                               bool? consentForDataUsage,
                                               bool? consentForAdsPersonalization,
                                               bool? hasConsentForAdStorage})`**

Sets the user's consent preferences for GDPR and ad personalization. All parameters are optional; only include the ones you need.
For more detailed information please visit [DMA compliance documentation](DMA.md).

_Example:_
```dart
appsflyerSdk.setConsentDataV2(
  isUserSubjectToGDPR: true,
  consentForDataUsage: true,
  consentForAdsPersonalization: false,
  hasConsentForAdStorage: true,
);
```
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
## **<a id="sendPushNotificationData"> `void sendPushNotificationData(Map? userInfo)`**

Push-notification campaigns are used to create re-engagements with existing users -> [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns)

🟩 **Android:**</br>
The AppsFlyer SDK **requires a** **valid Activity context** to process the push payload.
**Do NOT call this method from the background isolate** (e.g., _firebaseMessagingBackgroundHandler), as the activity is not yet created.
Instead, **delay calling this method** until the Flutter app is fully resumed and the activity is alive.

🍎 **iOS:**</br>
This method can be safely called at any point during app launch or when receiving a push notification.


_**Usage example with Firebase Cloud Messaging:**_</br>
Given the fact that push message data contains custom key called `af` that contains the attribution data you want to send to AppsFlyer in JSON format. The following attribution parameters are required: `pid`, `is_retargeting`, `c`.

📦 **Example Push Message Payload**
```json
{
 "af": {
    "c": "test_campaign",
    "is_retargeting": true,
    "pid": "push_provider_int",
  },
  "aps": {
    "alert": "Get 5000 Coins",
    "badge": "37",
    "sound": "default"
  }
}
```

1️⃣ Handle Foreground Messages
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  appsFlyerSdk.sendPushNotificationData(message.data);
});
```
2️⃣ Handle Notification Taps (App in Background)
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  appsFlyerSdk.sendPushNotificationData(message.data);
});
```
3️⃣ Handle App Launch from Push (Terminated State)
Store the payload using `_firebaseMessagingBackgroundHandler`, then pass it to AppsFlyer once the app is resumed.
```dart
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_af_push', jsonEncode(message.data));
}

// In your main() or splash screen after Flutter is initialized:
void handlePendingPush() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('pending_af_push');
  if (json != null) {
    final payload = jsonDecode(json);
    appsFlyerSdk.sendPushNotificationData(payload);
    await prefs.remove('pending_af_push');
  }
}
```
Call handlePendingPush() during app startup (e.g., in your main() or inside your splash screen after ensuring Flutter is initialized).

    
---
## **<a id="addPushNotificationDeepLinkPath"> `void addPushNotificationDeepLinkPath(List<String> deeplinkPath)`**
    
Registers a **custom key path** for resolving deep links inside **custom JSON payloads** in push notifications.

This is the recommended method of integrating AppsFlyer with push notifications. [Learn more here.](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns) </br>
> ⚠️ This method must be called BEFORE the AppsFlyer SDK is started — either before calling appsFlyerSdk.initSdk() (if using default auto-start), or before appsFlyerSdk.startSDK() (if using manual start mode). ⚠️ 


_Example:_
```dart
appsFlyerSdk.addPushNotificationDeepLinkPath(["deeply", "nested", "deep_link"]);
```

With this configuration, the SDK will extract the URL from the following push payload:

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
  final String referrerImageUrl;
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
      referrerImageUrl: "",
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

**<a id="performOnDeepLinking"> `void performOnDeepLinking()`**

**Android Only!**

Enables manual triggering of deep link resolution. This method allows apps that are delaying the call to `appsflyerSdk.startSDK()` to resolve deep links before the SDK starts.<br>
Note:<br>This API will trigger the `appsflyerSdk.onDeepLink` callback. In the following example, we check if `res.deepLinkStatus` is equal to "FOUND" inside `appsflyerSdk.onDeepLink` callback to extract the deeplink parameters.

```dart
  void afStart() async {
    // SDK Options
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15,
        manualStart: true);
    _appsflyerSdk = AppsflyerSdk(options);
    
    // Init of AppsFlyer SDK
    await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);

    // Conversion data callback
    _appsflyerSdk.onInstallConversionData((res) {
      print("onInstallConversionData res: " + res.toString());
      setState(() {
        _gcd = res;
      });
    });

    // App open attribution callback
    _appsflyerSdk.onAppOpenAttribution((res) {
      print("onAppOpenAttribution res: " + res.toString());
      setState(() {
        _deepLinkData = res;
      });
    });

    // Deep linking callback
    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          print(dp.deepLink?.toString());
          print("deep link value: ${dp.deepLink?.deepLinkValue}");
          break;
        case Status.NOT_FOUND:
          print("deep link not found");
          break;
        case Status.ERROR:
          print("deep link error: ${dp.error}");
          break;
        case Status.PARSE_ERROR:
          print("deep link status parsing error");
          break;
      }
      print("onDeepLinking res: " + dp.toString());
      setState(() {
        _deepLinkData = dp.toJson();
      });
    });

    if(Platform.isAndroid){
      _appsflyerSdk.performOnDeepLinking();
    }
    _appsflyerSdk.startSDK();
  }
```

---

### **<a id="logAdRevenue"> `void logAdRevenue(AdRevenueData adRevenueData)`**

The logAdRevenue API is designed to simplify the process of logging ad revenue events to AppsFlyer from your Flutter application. This API tracks revenue generated from advertisements, enriching your monetization analytics. Below you will find instructions on how to use this API correctly, along with detailed descriptions and examples for various input scenarios.

### **Usage:**
To use the logAdRevenue method, you must:

1. Prepare an instance of `AdRevenueData` with the required information about the ad revenue event.
1. Call `logAdRevenue` with the `AdRevenueData` instance.

**AdRevenueData Class**
[AdRevenueData](#AdRevenueData) is a data class representing all the relevant information about an ad revenue event:

* `monetizationNetwork`: The source network from which the revenue was generated (e.g., AdMob, Unity Ads).
* `mediationNetwork`: The mediation platform managing the ad (use AFMediationNetwork enum for supported networks).
* `currencyIso4217Code`: The ISO 4217 currency code representing the currency of the revenue amount (e.g., "USD", "EUR").
* `revenue`: The amount of revenue generated from the ad.
* `additionalParameters`: Additional parameters related to the ad revenue event (optional).


**AFMediationNetwork Enum**
[AFMediationNetwork](#AFMediationNetwork) is an enumeration that includes the supported mediation networks by AppsFlyer. It's important to use this enum to ensure you provide a valid network identifier to the logAdRevenue API.

### Example:
```dart
// Instantiate AdRevenueData with the ad revenue details.
AdRevenueData adRevenueData = AdRevenueData(
  monetizationNetwork: "GoogleAdMob", // Replace with your actual monetization network.
  mediationNetwork: AFMediationNetwork.applovinMax.value, // Use the value from the enum.
  currencyIso4217Code: "USD", 
  revenue: 1.23,
  additionalParameters: {
    // Optional additional parameters can be added here. This is an example, can be discard if not needed.
    'adUnitId': 'ca-app-pub-XXXX/YYYY', 
    'ad_network_click_id': '12345'
  }
);

// Log the ad revenue event.
logAdRevenue(adRevenueData);
```

**Additional Points**
* Mediation network input must be from the provided [AFMediationNetwork](#AFMediationNetwork)
  enum to ensure proper processing by AppsFlyer. For instance, use `AFMediationNetwork.googleAdMob.value` to denote Google AdMob as the Mediation Network.
* The `additionalParameters` map is optional. Use it to pass any extra information you have regarding the ad revenue event; this information could be useful for more refined analytics.
* Make sure the `currencyIso4217Code` adheres to the appropriate standard. Misconfigured currency code may result in incorrect revenue tracking.  