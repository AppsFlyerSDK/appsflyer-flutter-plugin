# API

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

## Types
- [AppsFlyerOptions](#appsflyer-options)
- [AdRevenueData](#AdRevenueData)
- [AFMediationNetwork](#AFMediationNetwork)
- [AFPurchaseDetails](#AFPurchaseDetails)
- [AFPurchaseType](#AFPurchaseType)

## Methods
- [initSdk](#initSdk)
- [startSDK](#startSDK)
- [registerSessionReadyListener](#registerSessionReadyListener)
- [unregisterSessionReadyListener](#unregisterSessionReadyListener)
- [isSessionReady](#isSessionReady)
- [onInstallConversionData](#onInstallConversionData)
- [unregisterConversionDataListener](#unregisterConversionDataListener)
- [onDeepLinking](#onDeepLinking)
- [logEvent](#logEvent)
- [logLocation](#logLocation)
- [logSession](#logSession)
- [anonymizeUser](#anonymizeUser)
- [setMinTimeBetweenSessions](#setMinTimeBetweenSessions)
- [stop](#stop)
- [setCurrencyCode](#setCurrencyCode)
- [setIsUpdate](#setIsUpdate)
- [setCustomerUserId](#setCustomerUserId)
- [setAdditionalData](#setAdditionalData)
- [setCollectAndroidId](#setCollectAndroidId)
- [setHost](#setHost)
- [getHostName](#getHostName)
- [getHostPrefix](#getHostPrefix)
- [updateServerUninstallToken](#updateServerUninstallToken)
- [Validate Purchase](#validatePurchase)
- [validateAndLogInAppPurchaseV2](#validatePurchaseV2)
- [sendPushNotificationData](#sendPushNotificationData)
- [addPushNotificationDeepLinkPath](#addPushNotificationDeepLinkPath)
- [User Invite](#userInvite)
- [enableFacebookDeferredApplinks](#enableFacebookDeferredApplinks)
- [setFacebookDeferredAppLink](#setFacebookDeferredAppLink)
- [enableTCFDataCollection](#enableTCFDataCollection)  <!-- New addition -->
- [setConsentData](#setConsentData) - [DEPRECATED]
- [setConsentDataV2](#setConsentDataV2)
- [disableSKAdNetwork](#disableSKAdNetwork)
- [disableAppleAdsAttribution](#disableAppleAdsAttribution)
- [disableIDFVCollection](#disableIDFVCollection)
- [setShouldCollectDeviceName](#setShouldCollectDeviceName)
- [isStopped](#isStopped)
- [getAppsFlyerUID](#getAppsFlyerUID)
- [isPreInstalledApp](#isPreInstalledApp)
- [getAttributionId](#getAttributionId)
- [setCurrentDeviceLanguage](#setCurrentDeviceLanguage)
- [setInstallId](#setInstallId)
- [setPreinstallAttribution](#setPreinstallAttribution)
- [setAppId](#setAppId)
- [setSharingFilterForPartners](#setSharingFilterForPartners)
- [setOneLinkCustomDomain](#setOneLinkCustomDomain)
- [setDisableAdvertisingIdentifiers](#setDisableAdvertisingIdentifiers)
- [setPartnerData](#setPartnerData)
- [setResolveDeepLinkURLs](#setResolveDeepLinkURLs)
- [setOutOfStore](#setOutOfStore)
- [getOutOfStore](#getOutOfStore)
- [setDisableNetworkData](#setDisableNetworkData)
- [disableAppSetId](#disableAppSetId)
- [performDeepLinking](#performDeepLinking)
- [appendParametersToDeepLinkingURL](#appendParametersToDeepLinkingURL)
- [setDeepLinkTimeout](#setDeepLinkTimeout)
- [Hashed PII setters](#setUserEmail) (setUserEmail / setUserPhone / setUserFirstName / setUserLastName / setUserFbLoginId / clearUserPii)
- [logInvite](#userInvite)
- [logAdRevenue](#logAdRevenue)  - Since 6.15.1


---

##### <a id="appsflyer-options"> **`AppsflyerSdk(Map options)`**

| parameter | type  | description       |
| --------- | ----- | ----------------- |
| `appsFlyerOptions` | `Map` | SDK configuration |

**`options`**

| Setting  | Type   | Description   |
| -------- | -------- | ------------- |
| devKey   | String | Your application's [devKey](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#retrieving-the-dev-key) provided by AppsFlyer (required)  |
| appId      | String | Your application's [App ID](https://support.appsflyer.com/hc/en-us/articles/207377436-Adding-a-new-app#available-in-the-app-store-google-play-store-windows-phone-store)  (required for iOS only) that you configured in your AppsFlyer dashboard  |
| showDebug   | bool | Debug mode - set to `true` for testing only, do not release to production with this parameter set to `true`! |
| timeToWaitForATTUserAuthorization | double | Delays the SDK start for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out. |
| appInviteOneLink | String | The [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) that is used to generate a User Invite, this is not a required field in the `AppsFlyerOptions`, you may choose to set it later via the appropriate API. |
| disableAdvertisingIdentifier| bool | Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA. |
| disableCollectASA | bool | Opt-out of the Apple Search Ads attributions. |




_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

// When passing a Map, the debug key is "isDebug" (the AppsFlyerOptions object uses `showDebug`).
Map appsFlyerOptions = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

```

**Or you can use `AppsFlyerOptions` class instead**

##### **`AppsflyerSdk(AppsFlyerOptions options)`**

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


##### <a id="initSdk"> **`initSdk({bool registerConversionDataCallback, bool registerOnDeepLinkingCallback}) async` (Changed in 7.0.0)**

initialize the SDK, using the options initialized from the constructor|
Return response object with the field `status`

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk _appsflyerSdk = AppsflyerSdk({...});

await _appsflyerSdk.initSdk(   
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true)
```

> **Both calls are required for callbacks.** `registerConversionDataCallback` / `registerOnDeepLinkingCallback` only enable the **native** events; they do not register a Dart handler. You must **also** register the paired listener — [`onInstallConversionData`](#onInstallConversionData) and [`onDeepLinking`](#onDeepLinking) respectively — and do so **before** calling `initSdk` so the first event is not missed. A flag without its listener drops events silently; a listener without its flag never fires.

---
##### <a id="startSDK"> **`void startSDK({RequestSuccessListener? onSuccess, RequestErrorListener? onError})`**
With AppsFlyer SDK 7 the initialization and start stages are always separate. `initSdk(...)` only initializes the SDK; a session (Launch) is sent only when you call `appsFlyer.startSDK()`.

Optionally pass `onSuccess` / `onError` to observe the start request result. `startSDK` and [`logEvent`](#logEvent) share the same request/response bridge (the native `AppsFlyerRequestListener`): the result arrives on the per-call reply — `onSuccess()` on a 200 OK, or `onError(errorCode, errorMessage)` with the SDK error otherwise. Passing no callback keeps the call fire-and-forget.

**`startSDK()` must be called once per foreground cycle.** The native SDK resets its "started" state every time the app is backgrounded, so a single `startSDK()` at launch reports only the first session — subsequent foregrounds send nothing. Call `startSDK()` from inside the [`registerSessionReadyListener`](#registerSessionReadyListener) callback, which fires once per foreground cycle (after any launch deep link has resolved), so every foreground — including background→foreground — reports a session:
```dart
// Recommended SDK 7 pattern: start on every session-ready signal.
_appsflyerSdk.registerSessionReadyListener((_) => _appsflyerSdk.startSDK());
await _appsflyerSdk.initSdk(...);
```
Gate the first session (e.g. on user consent or the Customer User ID) by deferring the `startSDK()` call inside the callback. Calling `startSDK()` more than once within the same foreground cycle is a no-op — the native SDK ignores the duplicate start.
---
#### <a id="onInstallConversionData"> **`onInstallConversionData(Func)`
- Trigger callback when onInstallConversionData is activated on the native side
- **Requires both calls:** also pass `registerConversionDataCallback: true` to [`initSdk`](#initSdk), and register this callback **before** `initSdk`. The flag alone (without this callback), or this callback alone (without the flag), delivers no data.
- The callback receives a `Map` (identical on Android and iOS): `status` is `"success"` or `"failure"`, and `payload` holds the conversion data on success (e.g. `af_status`, `media_source`, `campaign`, `is_first_launch`) or the error on failure (`payload` may be `null` when the native payload is empty). Both the success and failure native callbacks arrive here — branch on `status`.

_Example:_

```dart
    _appsflyerSdk.onInstallConversionData((res) {
      if (res['status'] == 'success') {
        final data = res['payload'] as Map?;
        print("conversion data: $data");
      } else {
        print("conversion data failed: ${res['payload']}");
      }
    });
```

**<a id="unregisterConversionDataListener"> `void unregisterConversionDataListener()`** — removes the Dart observer registered by `onInstallConversionData`. **Observer-only** (same as [`unregisterSessionReadyListener`](#unregisterSessionReadyListener)): it stops Dart-side routing but does **not** tear down the native SDK listener (that is bound to `initSdk` and iOS has no native conversion-unregister). Rarely needed — GCD is delivered once per install. (Android ✓ · iOS ✓, observer-only on both.)

**<a id="getAttributionId"> `Future<String?> getAttributionId()`** — returns the Facebook (Katana) attribution ID the SDK reads from the installed Facebook app's on-device content provider (also attached to attribution payloads automatically). Most apps never need it directly; exposed for parity with the native SDK. **Android only** — there is no iOS equivalent (no iOS SDK property or RPC), so it resolves to `null` on iOS.

_Example:_
```dart
appsFlyerSdk.getAttributionId().then((id) {
  print("Facebook attribution ID: $id");
});
```

#### <a id="onDeepLinking"> **`onDeepLinking(Func)`
- Trigger callback when onDeepLinking is activated on the native side
- **Requires both calls:** also pass `registerOnDeepLinkingCallback: true` to [`initSdk`](#initSdk), and register this callback **before** `initSdk`. The flag alone (without this callback), or this callback alone (without the flag), delivers no deep links.

_Example:_

```dart
    _appsflyerSdk.onDeepLinking((res) {
      print("res: " + res.toString());
    });
```

---
##### <a id="logEvent"> **`void logEvent(String eventName, Map? eventValues, {RequestSuccessListener? onSuccess, RequestErrorListener? onError})`**

- These in-app events help you to understand how loyal users discover your app, and attribute them to specific
  campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  to send ROI (Return on Investment) and LTV (Lifetime Value).
- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
- Result reporting mirrors [`startSDK`](#startSDK) (both are backed by the native `AppsFlyerRequestListener`).

| parameter       | type     | description                                                                                                                                                                       |
| --------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventName`     | `String` | Use descriptive, action-based names (e.g., "purchase", "add_to_cart", "level_completed"), keep names concise but meaningful, use lowercase with underscores for consistency and avoid special characters and spaces. See the [recommended event list by business](https://support.appsflyer.com/hc/en-us/articles/115005544169-In-app-events-Overview#recommended-events-by-business-vertical). |
| `eventValues`   | `Map`    | event details                                                                                                                                                                     |
| `onSuccess`     | `RequestSuccessListener?` | Optional. When provided, the native side waits for the SDK request result and invokes `onSuccess()` after the server accepts the event (HTTP 200). Passing no callback keeps the call fire-and-forget. |
| `onError`       | `RequestErrorListener?`   | Optional. Invoked with `(int errorCode, String errorMessage)` when the request fails (e.g. codes 41/42 when logged before the SDK is initialized/started). When a callback is passed the native call blocks until the request completes (up to ~10s). |

_Example:_

```dart
// Fire-and-forget.
appsflyerSdk.logEvent(eventName, eventValues);

// Observe the server request result (same pattern as startSDK).
appsflyerSdk.logEvent(
  eventName,
  eventValues,
  onSuccess: () => print("logEvent success"),
  onError: (int code, String message) => print("logEvent error $code: $message"),
);
```

---

##### <a id="logLocation"> **`void logLocation(double latitude, double longitude)`**

Manually logs the device location for the current user. `latitude` must be within −90..90 and `longitude` within −180..180 (values outside the range are rejected by the native bridge). Fire-and-forget — dispatched without awaiting, so errors are not surfaced to Dart. Supported on Android and iOS.

```dart
appsflyerSdk.logLocation(32.0853, 34.7818);
```

---

##### <a id="logSession"> **`void logSession()`**

Manually logs a session — intended for utility apps that run in the background and need to report a session explicitly. **Android only**; iOS reports sessions through [`startSDK`](#startSDK) / the SDK 7 session model, so this is a no-op on iOS.

```dart
appsflyerSdk.logSession();
```

---

## SDK 7 APIs

### Session readiness (SDK 7 session model)

In SDK 7 the plugin initializes on [`initSdk`](#initSdk); a session is sent when
the app calls [`startSDK`](#startSDK). Because the native SDK requires
`start()` once per foreground cycle, `registerSessionReadyListener` is the
recommended place to call `startSDK()`.

**<a id="registerSessionReadyListener"> `void registerSessionReadyListener(Function callback)`**

Registers a callback invoked when the SDK reports it is ready to send a new
session. It fires **once per foreground cycle**, after any launch deep link has
resolved. Call `startSDK()` inside this callback so every foreground reports a
session. The callback receives a `{status, payload}` map. Register **before**
[`initSdk`](#initSdk) so the first signal is not missed; use
[`isSessionReady`](#isSessionReady) to catch up if you register later.

```dart
_appsflyerSdk.registerSessionReadyListener((res) {
  _appsflyerSdk.startSDK();
});
```

Platform support: Android ✓ · iOS ✓.

**<a id="unregisterSessionReadyListener"> `void unregisterSessionReadyListener()`** — removes the callback above (Android ✓ · iOS ✓).

**<a id="isSessionReady"> `Future<bool> isSessionReady()`** — returns whether all
session-readiness conditions are currently satisfied. Supported on both platforms.

```dart
appsFlyerSdk.registerSessionReadyListener((res) => print("session ready: $res"));
final ready = await appsFlyerSdk.isSessionReady();
```

### Setter persistence (SDK 7)

In SDK 7 all `AppsFlyerLib` setter values are **runtime-only on both Android and
iOS**. Android no longer persists setter values across process restarts, aligning
its behavior with iOS and making the lifecycle predictable across platforms.

Re-apply your configuration setters on **every cold start, before
[`startSDK`](#startSDK)**, so they attach to that launch event:

```dart
// Runs on every cold start (e.g. from initState), before the first startSDK().
appsFlyerSdk.setCustomerUserId("user-42");
appsFlyerSdk.setCurrencyCode("EUR");
appsFlyerSdk.setAdditionalData({"tenant": "eu"});
appsFlyerSdk.setConsentDataV2(isUserSubjectToGDPR: false);
```

Within a running process the values persist across background→foreground, so you
only re-apply them **once per cold start** — not on every `startSDK()`. Setters
that follow this rule include [`setCustomerUserId`](#setCustomerUserId),
[`setCurrencyCode`](#setCurrencyCode), [`setAdditionalData`](#setAdditionalData),
[`setConsentDataV2`](#setConsentDataV2), [`anonymizeUser`](#anonymizeUser),
[`setSharingFilterForPartners`](#setSharingFilterForPartners),
[`setHost`](#setHost), and the [hashed-PII](#setUserEmail) setters.

### Hashed PII

The following setters normalize and hash (SHA-256) the value on-device before it
is sent to AppsFlyer. Supported on Android and iOS.

| API | Description |
| --- | --- |
| <a id="setUserEmail"></a>`setUserEmail(String email)` | Hash the user's email |
| `setUserPhone(String countryCode, String phoneNumber)` | Hash the user's phone number |
| `setUserFirstName(String firstName)` | Hash the user's first name |
| `setUserLastName(String lastName)` | Hash the user's last name |
| `setUserFbLoginId(String fbLoginId)` | Set the Facebook App-Scoped ID (numeric string, not hashed; non-numeric ignored; `"0"` clears it) |
| `clearUserPii()` | Clear all previously set PII (hashed email/phone/name fields + the fb login id) |

```dart
appsFlyerSdk.setUserEmail("a@a.com");
appsFlyerSdk.setUserPhone("1", "5551234567");
appsFlyerSdk.clearUserPii();
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
**<a id="isStopped"> `Future<bool?> isStopped() async`** — **Android only**

Returns whether the SDK is currently stopped (see `stop`). Returns `null` on iOS — the iOS RPC has no `isStopped` getter.

_Example:_
```dart
final stopped = await appsFlyerSdk.isStopped();
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
**<a id="enableTCFDataCollection"> `enableTCFDataCollection(bool shouldCollect)`**

The `enableTCFDataCollection` method is employed to control the automatic collection of the Transparency and Consent Framework (TCF) data. By setting this flag to `true`, the system is instructed to automatically collect TCF data. Conversely, setting it to `false` prevents such data collection.

_Example:_
```dart
appsFlyerSdk.enableTCFDataCollection(true);
```
---
**<a id="setConsentData"> `void setConsentData(AppsFlyerConsent consentData)`** *Deprecated — use [`setConsentDataV2`](#setConsentDataV2)*

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
To reflect TCF data in the conversion (first launch) payload, it's crucial to configure `enableTCFDataCollection` **or** [`setConsentDataV2`](#setConsentDataV2) between the SDK initialization and start phase. Follow the example provided:

```dart
// Set AppsFlyerOption - the SDK is always started explicitly via startSDK()
final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15);
_appsflyerSdk = AppsflyerSdk(options);

// Init the AppsFlyer SDK
_appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnDeepLinkingCallback: true);

// Set configurations to the SDK
// Enable TCF Data Collection
_appsflyerSdk.enableTCFDataCollection(true);

// Set Consent Data (recommended: setConsentDataV2)
// If user is subject to GDPR
// _appsflyerSdk.setConsentDataV2(
//   isUserSubjectToGDPR: true,
//   consentForDataUsage: true,
//   consentForAdsPersonalization: true);

// If user is not subject to GDPR
_appsflyerSdk.setConsentDataV2(isUserSubjectToGDPR: false);

// Here we start a session
_appsflyerSdk.startSDK(); 
```

Following this sequence ensures that the consent configurations take effect before the AppsFlyer SDK starts, providing accurate consent data in the first launch payload.
Note: You need to use either `enableTCFDataCollection` or `setConsentDataV2` — if you use both, our backend prioritizes the consent data provided via `setConsentDataV2`.

---
**<a id="setConsentDataV2"> `setConsentDataV2({required bool isUserSubjectToGDPR, bool? consentForDataUsage, bool? consentForAdsPersonalization, bool? hasConsentForAdStorage})`**

### Sets user consent preferences for GDPR and ad personalization

> ⚠️ This method replaces the deprecated `setConsentData` - for a complete guide, see our [DMA compliance documentation](consent-dma.md).

Use this method to provide the user's consent settings to the AppsFlyer SDK. `isUserSubjectToGDPR` is **required**. When it is `true`, both `consentForDataUsage` and `consentForAdsPersonalization` are **also required** — an `ArgumentError` is thrown if either is omitted. This mirrors the native iOS contract (which rejects a GDPR-subject consent that omits them) and keeps Android and iOS consistent. When it is `false` (non-GDPR user), the consent flags are ignored and may be omitted.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `isUserSubjectToGDPR` | `bool` (required) | Whether the user is subject to GDPR regulations |
| `consentForDataUsage` | `bool?` | Whether the user consents to data usage by AppsFlyer (required when `isUserSubjectToGDPR` is `true`) |
| `consentForAdsPersonalization` | `bool?` | Whether the user consents to personalized advertising (required when `isUserSubjectToGDPR` is `true`) |
| `hasConsentForAdStorage` | `bool?` | Whether the user consents to ad storage (optional) |

> 📝 **Note:** Provide the user's current consent on every app start, **before** `startSDK()` — the SDK does not persist consent across sessions.

_Example (GDPR user):_
```dart
appsflyerSdk.setConsentDataV2(
  isUserSubjectToGDPR: true,
  consentForDataUsage: true,
  consentForAdsPersonalization: false,
  hasConsentForAdStorage: true,
);
```

_Example (non-GDPR user):_
```dart
appsflyerSdk.setConsentDataV2(isUserSubjectToGDPR: false);
```
---
**<a id="setCustomerUserId"> `void setCustomerUserId(String userId)`**

[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)

_Example:_
```dart
appsFlyerSdk.setCustomerUserId("id");
```
---
**<a id="setAdditionalData"> `void setAdditionalData(Map<String, dynamic> customData)`**

`customData` must be non-null (the iOS RPC rejects a missing map, dropping the call there); pass an empty map to clear.

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
**<a id="setHost"> `void setHost(String hostPrefix, String hostName)`**
You can change the default host (appsflyer) by using this function. Both `hostPrefix` and `hostName` must be non-empty — the iOS RPC rejects an empty prefix, so the call is a no-op on both platforms when either value is empty.

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

Token format differs per platform: on **Android** pass the FCM/GCM registration token as-is; on **iOS** pass the APNs device token **hex-encoded** as an even-length string (a non-hex string is rejected natively). On iOS, `getAPNSToken()` already returns the token in hex form.

_Example:_
```dart
appsFlyerSdk.updateServerUninstallToken("token");
```
---
**<a id="validatePurchase"> Validate Purchase**

***Cross-Platform V2 API (Recommended - BETA):***

> ⚠️ **BETA Feature**: This API is currently in beta. While it's stable and recommended for new implementations, please test thoroughly in your environment before production use.

**`Future<Map<String, dynamic>> validateAndLogInAppPurchaseV2(AFPurchaseDetails purchaseDetails, {Map<String, String>? additionalParameters})`**

The new unified purchase validation API that works across both Android and iOS platforms. This is the recommended approach for validating in-app purchases.

| Parameter | Type | Description |
|-----------|------|-------------|
| `purchaseDetails` | `AFPurchaseDetails` | Purchase details containing type, token, and product ID |
| `additionalParameters` | `Map<String, String>?` | Optional additional parameters |

**AFPurchaseDetails:**
| Property | Type | Description |
|----------|------|-------------|
| `purchaseType` | `AFPurchaseType` | Type of purchase (oneTimePurchase or subscription) |
| `purchaseToken` | `String` | Purchase token from the app store |
| `productId` | `String` | Product identifier |

**AFPurchaseType:**
- `AFPurchaseType.oneTimePurchase` - For one-time in-app purchases
- `AFPurchaseType.subscription` - For subscription purchases

_Example:_
```dart
// Create purchase details
AFPurchaseDetails purchaseDetails = AFPurchaseDetails(
  purchaseType: AFPurchaseType.oneTimePurchase,
  purchaseToken: "your_purchase_token",
  productId: "your_product_id",
);

// Validate purchase
try {
  Map<String, dynamic> result = await appsFlyerSdk.validateAndLogInAppPurchaseV2(
    purchaseDetails,
    additionalParameters: {"custom_param": "value"}
  );
  print("Validation successful: $result");
} on PlatformException catch (e) {
  // Structured error information; on iOS `e.details` may include the NSError
  // code / domain / user info.
  print("Validation failed: ${e.code} ${e.message}");
} catch (e) {
  print("Validation failed: $e");
}
```

**Key Benefits:**
- **Cross-platform compatibility**: Works on both Android and iOS with the same API
- **Type safety**: Uses structured data classes instead of platform-specific parameters
- **Enhanced error handling**: Provides detailed error information in structured format (including `NSError` details on iOS)
- **Future-proof**: Built on AppsFlyer's latest V2 validation infrastructure
- **Automatic routing**: Automatically routes to the correct validation endpoint based on purchase type

---

***Purchase validation sandbox mode for iOS:***

`void useReceiptValidationSandbox(bool isSandboxEnabled)` — **iOS only**

Enables sandbox mode for App Store receipt validation.

_Example:_
```dart
appsFlyerSdk.useReceiptValidationSandbox(true);
```

`void useUninstallSandbox(bool isSandboxEnabled)` — **iOS only**

Enables sandbox mode for uninstall-measurement validation (companion of `useReceiptValidationSandbox`).

_Example:_
```dart
appsFlyerSdk.useUninstallSandbox(true);
```

---

<a id="validatePurchaseV2"></a>
##### **validateAndLogInAppPurchaseV2 (Recommended - BETA)**

See [Validate Purchase](#validatePurchase) above for the full `validateAndLogInAppPurchaseV2` reference — signature, `AFPurchaseDetails` / `AFPurchaseType`, example, key benefits, and the iOS sandbox toggles. This anchor is kept for existing links.

---
## **<a id="sendPushNotificationData"> `void sendPushNotificationData(Map? userInfo)`**

Push-notification campaigns are used to create re-engagements with existing users → [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns)

### Platform-Specific Requirements

🟩 **Android:**  
The AppsFlyer SDK **requires a valid Activity context** to process the push payload.
**Do NOT call this method from the background isolate** (e.g., `_firebaseMessagingBackgroundHandler`), as the activity is not yet created.
Instead, **delay calling this method** until the Flutter app is fully resumed and the activity is alive.

🍎 **iOS:**  
This method can be safely called at any point during app launch or when receiving a push notification.

---

## Integration Approaches

AppsFlyer supports two approaches for measuring push notification campaigns:

### Approach 1: Traditional Attribution Parameters (`af` object)

Use this approach when your push payload contains a custom `af` object with attribution parameters.

**Required parameters:** `pid`, `is_retargeting`, `c`

📦 **Example Push Payload with `af` Object:**
```json
{
  "af": {
    "c": "test_campaign",
    "is_retargeting": true,
    "pid": "push_provider_int"
  },
  "aps": {
    "alert": "Get 5000 Coins",
    "badge": "37",
    "sound": "default"
  }
}
```

**Implementation (Android & iOS):**

```dart
// 1️⃣ Handle Foreground Messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  appsFlyerSdk.sendPushNotificationData(message.data);
});

// 2️⃣ Handle Notification Taps (App in Background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  appsFlyerSdk.sendPushNotificationData(message.data);
});

// 3️⃣ Handle App Launch from Push (Terminated State)
// Store payload in background handler, then pass to AppsFlyer when app resumes
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

Call `handlePendingPush()` during app startup (e.g., in your `main()` or inside your splash screen after ensuring Flutter is initialized).

---

### Approach 2: OneLink URL in Push Payload (Recommended)

Use this approach when your push payload contains a **OneLink URL** for deep linking. This method provides a unified deep linking experience.

> ⚠️ **Important:** This approach requires calling **two different methods** depending on the platform!

#### **Step 1: Configure Deep Link Path (BOTH Platforms)**

Call `addPushNotificationDeepLinkPath` **BEFORE** initializing the SDK to tell AppsFlyer where to find the OneLink URL in your push payload.

```dart
// Must be called BEFORE initSdk() or startSDK()
appsFlyerSdk.addPushNotificationDeepLinkPath(["deeply", "nested", "deep_link"]);

// Then initialize the SDK
await appsFlyerSdk.initSdk(
  registerOnDeepLinkingCallback: true  // Enable deep linking callback
);
```

#### **Step 2: Send Push Payload to SDK**

**🟩 Android:**  
On Android, calling `addPushNotificationDeepLinkPath` is **sufficient**. The SDK automatically extracts and processes the OneLink URL.

**🍎 iOS:**  
On iOS, you **MUST also call** `sendPushNotificationData(userInfo)` to pass the push payload to the SDK. The SDK then internally calls `handlePushNotification` to extract and process the OneLink URL.

📦 **Example Push Payload with OneLink URL:**
```json
{
  "deeply": {
    "nested": {
      "deep_link": "https://yourapp.onelink.me/ABC/campaign123"
    }
  },
  "aps": {
    "alert": "Check out our new feature!",
    "badge": "1",
    "sound": "default"
  }
}
```

**Complete Implementation Example:**

```dart
// ========================================
// 1. Configure SDK (in main.dart or app initialization)
// ========================================
void initializeAppsFlyer() async {
  // STEP 1: Configure the deep link path BEFORE starting SDK
  appsFlyerSdk.addPushNotificationDeepLinkPath(["deeply", "nested", "deep_link"]);
  
  // STEP 2: Initialize SDK with deep linking callback
  await appsFlyerSdk.initSdk(
    registerOnDeepLinkingCallback: true
  );
  
  // STEP 3: Set up deep linking callback to handle the OneLink URL
  appsFlyerSdk.onDeepLinking((DeepLinkResult result) {
    if (result.status == Status.FOUND) {
      print("Deep link found: ${result.deepLink?.deepLinkValue}");
      // Handle deep link navigation here
    }
  });
}

// ========================================
// 2. Handle Push Notifications
// ========================================

// 🍎 iOS: MUST call sendPushNotificationData
// 🟩 Android: Optional (SDK auto-handles), but recommended for consistency

// 1️⃣ Foreground Messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // iOS: Required to process OneLink URL
  // Android: SDK processes automatically, but calling doesn't hurt
  appsFlyerSdk.sendPushNotificationData(message.data);
});

// 2️⃣ Background Notification Taps (App in Background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // iOS: Required to process OneLink URL
  appsFlyerSdk.sendPushNotificationData(message.data);
});

// 3️⃣ App Launch from Push (Terminated State)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_af_push', jsonEncode(message.data));
}

// In main() or splash screen:
void handlePendingPush() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('pending_af_push');
  if (json != null) {
    final payload = jsonDecode(json);
    // iOS: Required to process OneLink URL from terminated state
    appsFlyerSdk.sendPushNotificationData(payload);
    await prefs.remove('pending_af_push');
  }
}
```

#### **Key Differences Between Approaches:**

|| Traditional `af` Object | OneLink URL (Recommended) |
|---|---|---|
| **Android** | `sendPushNotificationData(data)` | `addPushNotificationDeepLinkPath()` (auto-handles) |
| **iOS** | `sendPushNotificationData(data)` | `addPushNotificationDeepLinkPath()` **+** `sendPushNotificationData(data)` |
| **Deep Linking** | Basic attribution only | Full deep linking with `onDeepLinking` callback |
| **Use Case** | Simple re-engagement | Re-engagement + in-app navigation |

---

### Summary

- **Traditional approach**: Always call `sendPushNotificationData(payload)` on both platforms
- **OneLink approach (Recommended)**:
  - ✅ **Both platforms**: Call `addPushNotificationDeepLinkPath()` before SDK init
  - ✅ **iOS only**: Also call `sendPushNotificationData(payload)` when push is received
  - ✅ **Both platforms**: Handle deep links in `onDeepLinking` callback

    
---
## **<a id="addPushNotificationDeepLinkPath"> `void addPushNotificationDeepLinkPath(List<String> deeplinkPath)`**
    
Registers a **custom key path** for resolving deep links inside **custom JSON payloads** in push notifications.

This is the recommended method of integrating AppsFlyer with push notifications. [Learn more here.](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns) </br>
> ⚠️ This method must be called BEFORE the AppsFlyer SDK is started — ideally before `appsFlyerSdk.initSdk()`, and at the latest before `appsFlyerSdk.startSDK()`. ⚠️ 


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

**`Future<void> setAppInviteOneLinkID(String oneLinkID, [Function? callback])`**

The `callback` is optional — `setAppInviteOneLink` is a plain native setter, so it only signals a static `"success"` (no payload). Omit it if you don't need the acknowledgement.

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

`success` receives an envelope map `{"status": "success", "payload": {"userInviteURL": "<url>"}}` — read the link via `result["payload"]["userInviteURL"]`. `error` receives a plain `String` message (on iOS a static `"The URL wasn't generated!"`; on Android the underlying error).

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

4. Log the `af_invite` event when the user actually shares the invite:

**`void logInvite(String channel, [Map? eventParameters])`**

Logs the `af_invite` in-app event so AppsFlyer can attribute the invite and any downstream installs to the referring user. Fire-and-forget; supported on Android and iOS.

_Example:_
```dart
appsFlyerSdk.logInvite("facebook", {"referrerId": "user-123"});
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
**<a id="setFacebookDeferredAppLink"> `void setFacebookDeferredAppLink(String? url)`** _(iOS only)_

Manually sets — or, with `null`, clears — the Facebook deferred app-link URL. When a URL is set, the SDK injects it directly as the Facebook deferred deep link (`fb_ddl.link`) on the first launch, bypassing the Facebook SDK fetch. Passing `null` clears the override so the SDK falls back to fetching via the Facebook SDK when [`enableFacebookDeferredApplinks`](#enableFacebookDeferredApplinks) is enabled. The native RPC rejects unsafe URL schemes (e.g. `javascript:`). No-op on Android (no native equivalent).

Use this only when you already hold the deferred link and want to skip the Facebook SDK lookup; otherwise prefer `enableFacebookDeferredApplinks(true)`.

_Example:_
```dart
appsFlyerSdk.setFacebookDeferredAppLink("https://myapp.onelink.me/abc123");
```
---
**<a id="disableSKAdNetwork"> `void disableSKAdNetwork(bool isEnabled)`**

Use this API in order to disable the SK Ad network (request will be sent but the rules won't be returned).

_Example:_
```dart
appsFlyerSdk.disableSKAdNetwork(true);
```
---
**<a id="disableAppleAdsAttribution"> `void disableAppleAdsAttribution(bool disable)`** — **iOS only**

Disables Apple Ads (Apple Search Ads) attribution via the AdServices framework — pass `true` to stop the SDK from calling `AAAttribution.attributionToken` (iOS 14.3+). This is the AdServices companion of the `disableCollectASA` init option (the legacy iAd path); the iOS SDK requires **both** to be set to fully suppress Apple Search Ads attribution. Set it before `startSDK()`. No-op on Android (AdServices is Apple-only).

_Example:_
```dart
if (Platform.isIOS) {
  appsFlyerSdk.disableAppleAdsAttribution(true);
}
```
---
**<a id="disableIDFVCollection"> `void disableIDFVCollection(bool disable)`** — **iOS only**

Disables collection of the IDFV (Identifier for Vendor) — pass `true` to stop the SDK from collecting it. Set it before `startSDK()`. No-op on Android (IDFV is Apple-only).

_Example:_
```dart
if (Platform.isIOS) {
  appsFlyerSdk.disableIDFVCollection(true);
}
```
---
**<a id="setShouldCollectDeviceName"> `void setShouldCollectDeviceName(bool collect)`** — **iOS only**

Enables collection of the device name (e.g. `"John's iPhone"`). This is an **opt-in** — collection is **off by default** and the device name is personal data (PII), so only enable it if your privacy policy covers it. Pass `true` to start collecting it. Set it before `startSDK()`. No-op on Android (Apple-only).

_Example:_
```dart
if (Platform.isIOS) {
  appsFlyerSdk.setShouldCollectDeviceName(true);
}
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
**<a id="isPreInstalledApp"> `Future<bool?> isPreInstalledApp()`** — **Android only**

Returns whether the app install was a device preinstall (OEM/manufacturer). Returns `null` on iOS (preinstall attribution relies on the Android install-referrer mechanism). See also `setPreinstallAttribution`.

_Example:_
```dart
final bool? preinstalled = await appsFlyerSdk.isPreInstalledApp();
```
---
**<a id="setCurrentDeviceLanguage"> `void setCurrentDeviceLanguage(string language)`**

Use this API in order to set the language

_Example:_
```dart
appsFlyerSdk.setCurrentDeviceLanguage("en");
```
---
**<a id="setInstallId"> `void setInstallId(String installId)`**

Sets a unique install id for the app installation, letting you correlate the AppsFlyer install with an id you generate yourself (e.g. for server-side reconciliation). Call it before `startSDK()`. Supported on both platforms.

_Example:_
```dart
appsFlyerSdk.setInstallId("install-123");
```
---
**<a id="setPreinstallAttribution"> `void setPreinstallAttribution(String mediaSource, String campaign, String siteId)`**

Attributes the install to a device preinstall (OEM / manufacturer) deal, declaring that the app shipped preinstalled and attributing the install to the given `mediaSource`, `campaign`, and `siteId`. Call it **before** `startSDK()`.

**Android only** — preinstall attribution relies on the Android install referrer mechanism; iOS has no equivalent, so this is a no-op on iOS.

_Example:_
```dart
appsFlyerSdk.setPreinstallAttribution("media_source", "campaign", "site_id");
```
---
**<a id="setAppId"> `void setAppId(String appId)`**

Overrides the app ID reported to AppsFlyer. Call it **before** `startSDK()`. An empty `appId` is ignored.

**Android only** — on iOS the app ID (`appleAppID`) is provided at init via `AppsFlyerOptions` and the iOS RPC has no `setAppId`, so this is a no-op on iOS.

_Example:_
```dart
appsFlyerSdk.setAppId("com.example.app");
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
**<a id="setDisableAdvertisingIdentifiers"> `void setDisableAdvertisingIdentifiers(bool disable)`**

Disables collection of advertising identifiers (GAID / IDFA / OAID). Pass `true` to **disable** collection (enabled by default).

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

Specify the alternative app store that the app is downloaded from (out-of-store
attribution). Re-apply on every cold start — SDK 7 does not persist setter values.

This API does **not** register manifest receivers. SDK 7 uses the Google Play Install
Referrer library instead of legacy `INSTALL_REFERRER` broadcast receivers. See
[Advanced features — Android Out of Store](advanced-features.md#out-of-store).

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
**<a id="disableAppSetId"> `void disableAppSetId()`**

**Android Only!**

Disables AppSet ID collection. Starting with v6.17.0, the SDK can automatically collect the AppSet ID. Use this method to opt-out of AppSet ID collection for privacy compliance.

_Example:_
```dart
  if(Platform.isAndroid){
    appsflyerSdk.disableAppSetId();
  }
```
---

**<a id="performDeepLinking"> `void performDeepLinking(String url, {bool shouldTriggerSession = false})`**

Manually triggers deep link resolution for a given `url` (full URL, OneLink, or intent-data string). Use it to resolve a deep link before the SDK starts (e.g. when delaying `startSDK()`), or for links that don't arrive through the standard intent / Universal Link flow (e.g. Firebase Messaging).

The resolved link is delivered to the [`onDeepLinking`](#onDeepLinking) (UDL) callback on both platforms. `shouldTriggerSession` defaults to `false`, so a bare `performDeepLinking(url)` resolves the link without an extra Launch and behaves identically on Android and iOS. The flag is Android-only: pass `true` to also enqueue a Launch for re-engagement; on iOS it has no effect (the link is always resolved without an extra managed session). This is the SDK 7 replacement for the removed `performOnDeepLinking()`.

```dart
  void afStart() async {
    // SDK Options
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15);
    _appsflyerSdk = AppsflyerSdk(options);
    
    // Init of AppsFlyer SDK
    await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: true);

    // Conversion data callback
    _appsflyerSdk.onInstallConversionData((res) {
      print("onInstallConversionData res: " + res.toString());
      setState(() {
        _gcd = res;
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

    // Resolve a deep link manually (both platforms surface it via onDeepLinking)
    _appsflyerSdk.performDeepLinking("https://yourapp.onelink.me/abc123");

    _appsflyerSdk.registerSessionReadyListener((_) => _appsflyerSdk.startSDK());
  }
```

---

**<a id="appendParametersToDeepLinkingURL"> `void appendParametersToDeepLinkingURL(String contains, Map<String, String> parameters)`**

Appends `parameters` to any deep-link URL that contains the `contains` substring, before the SDK resolves / attributes it. Useful for enriching wrapped OneLinks with extra query parameters. Implemented on both Android and iOS.

Pass a non-empty `contains` and at least one entry in `parameters`: both native RPC bridges reject an empty `contains`, and iOS additionally rejects an empty `parameters` map (Android tolerates it).

```dart
  appsFlyerSdk.appendParametersToDeepLinkingURL(
      "deeplink", {"deep_link_sub1": "cat123", "deep_link_value": "shoes"});
```

---

**<a id="setDeepLinkTimeout"> `void setDeepLinkTimeout(int timeoutMs)`**

Sets the deep-link resolution timeout, in **milliseconds**. Call it **before** `initSdk()`. The default when unset differs by platform: **3000 ms on Android, 60000 ms on iOS**.

```dart
  appsFlyerSdk.setDeepLinkTimeout(3000);
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

> **Note (behavior):** `logAdRevenue` is fire-and-forget — the native SDK logs ad revenue without a completion callback, so validation errors are not surfaced to Dart. An **unknown** `mediationNetwork` is rejected by both native bridges and the event is silently dropped, so always pass a value from the enum.
>
> **Cross-platform note:** `AFMediationNetwork.customMediation` and `AFMediationNetwork.directMonetizationNetwork` serialize to identifiers Android accepts but the iOS SDK rejects. The plugin remaps just those two to the iOS `custom` / `directmonetization` identifiers automatically, so all enum values work on both platforms — no caller action needed.

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