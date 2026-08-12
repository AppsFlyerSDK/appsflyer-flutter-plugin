# API

<img  src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400"  >

## Types
- [AppsFlyerSdk](#appsflyer-options)
- [AFMediationNetwork](#AFMediationNetwork)
- [AFLogLevel](#AFLogLevel)
- [AFPurchaseDetails](#AFPurchaseDetails)
- [AFAndroidPurchaseDetails](#AFAndroidPurchaseDetails)
- [AFIOSPurchaseDetails](#AFIOSPurchaseDetails)
- [AFPurchaseType](#AFPurchaseType)
- [AppsFlyerInviteLinkParams](#AppsFlyerInviteLinkParams)
- [DeepLinkResult](#DeepLinkResult)
- [DeepLinkStatus](#DeepLinkStatus)
- [DeepLinkFailure](#DeepLinkFailure)
- [DeepLink](#DeepLink)
- [AppsFlyerException](#AppsFlyerException)

## Methods
- [init](#init)
- [enableDebug](#enableDebug)
- [setLogLevel](#setLogLevel)
- [start](#start)
- [registerConversionListener](#registerConversionListener)
- [unregisterConversionListener](#unregisterConversionListener)
- [registerDeepLinkListener](#registerDeepLinkListener)
- [unregisterDeeplinkListener](#unregisterDeeplinkListener)
- [registerSessionReadyListener](#registerSessionReadyListener)
- [unregisterSessionReadyListener](#unregisterSessionReadyListener)
- [isSessionReady](#isSessionReady)
- [onSessionReady](#onSessionReady)
- [onConversionDataSuccess](#onConversionDataSuccess)
- [onConversionDataFailure](#onConversionDataFailure)
- [onDeepLinkReceived](#onDeepLinkReceived)
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
- [setCollectAndroidID](#setCollectAndroidID)
- [setHost](#setHost)
- [getHostName](#getHostName)
- [getHostPrefix](#getHostPrefix)
- [updateServerUninstallToken](#updateServerUninstallToken)
- [Validate Purchase](#validatePurchase)
- [validateAndLogInAppPurchase](#validateAndLogInAppPurchase)
- [setUseReceiptValidationSandbox](#setUseReceiptValidationSandbox)
- [setUseUninstallSandbox](#setUseUninstallSandbox)
- [sendPushNotificationData](#sendPushNotificationData)
- [handlePushNotification](#handlePushNotification)
- [addPushNotificationDeepLinkPath](#addPushNotificationDeepLinkPath)
- [User Invite](#userInvite)
- [setAppInviteOneLink](#setAppInviteOneLink)
- [generateInviteLink](#generateInviteLink)
- [enableFacebookDeferredApplinks](#enableFacebookDeferredApplinks)
- [setFacebookDeferredAppLink](#setFacebookDeferredAppLink)
- [enableTCFDataCollection](#enableTCFDataCollection)
- [setConsentData](#setConsentData)
- [setDisableSKAdNetwork](#setDisableSKAdNetwork)
- [setDisableAppleAdsAttribution](#setDisableAppleAdsAttribution)
- [setDisableIDFVCollection](#setDisableIDFVCollection)
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
- [setDisableCollectASA](#setDisableCollectASA)
- [setPartnerData](#setPartnerData)
- [setResolveDeepLinkURLs](#setResolveDeepLinkURLs)
- [setOutOfStore](#setOutOfStore)
- [getOutOfStore](#getOutOfStore)
- [setDisableNetworkData](#setDisableNetworkData)
- [disableAppSetId](#disableAppSetId)
- [performDeepLinking](#performDeepLinking)
- [appendParametersToDeepLinkingURL](#appendParametersToDeepLinkingURL)
- [setDeepLinkTimeout](#setDeepLinkTimeout)
- [Hashed PII setters](#setUserEmail)
  - [setUserPhone](#setUserPhone)
  - [setUserFirstName](#setUserFirstName)
  - [setUserLastName](#setUserLastName)
  - [setUserFbLoginId](#setUserFbLoginId)
  - [clearUserPii](#clearUserPii)
- [logInvite](#logInvite)
- [Cross promotion](#crossPromotion)
- [logCrossPromoteImpression](#logCrossPromoteImpression)
- [logAndOpenStore](#logAndOpenStore)
- [logAdRevenue](#logAdRevenue)
- [getSdkVersion](#getSdkVersion)
- [pluginVersion](#pluginVersion)


---

##### <a id="appsflyer-options"> **`AppsFlyerSdk.instance`**

`AppsFlyerSdk` is the cross-platform SDK entry point. Use its shared
`instance`; configuration is exposed through explicit methods.

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final AppsFlyerSdk appsflyerSdk = AppsFlyerSdk.instance;
```

Once the instance is obtained, call `init`.

---

##### <a id="AFMediationNetwork"> **`AFMediationNetwork`**
an enumeration that includes the supported mediation networks by AppsFlyer.

| networks |
| -------- |
| ironSource |
| applovinMax |
| googleAdMob |
| fyber |
| appodeal |
| admost |
| topon |
| tradplus |
| yandex |
| chartboost |
| unity |
| toponPte |
| customMediation |
| directMonetizationNetwork |

---

##### <a id="AFLogLevel"> **`AFLogLevel`**

An enumeration of the Android SDK logging levels: `none`, `error`, `warning`,
`info`, `debug`, and `verbose`.

---

##### <a id="DeepLinkResult"> **`DeepLinkResult`**

Contains a `DeepLinkStatus`, optional `DeepLink`, and optional
`DeepLinkFailure`. Android supplies a stable failure type; iOS supplies a
message.

##### <a id="DeepLinkStatus"> **`DeepLinkStatus`**

The deep-link resolution status: `found`, `notFound`, `error`, or `unknown`.

##### <a id="DeepLinkFailure"> **`DeepLinkFailure`**

Contains an optional Android error `type` or optional iOS error `message`.

##### <a id="DeepLink"> **`DeepLink`**

Provides the full `clickEvent` map, `getStringValue(String key)`, and typed
getters for common Unified Deep Linking values such as `deepLinkValue`,
`mediaSource`, `campaign`, `campaignId`, `afSub1` through `afSub5`, and
`isDeferred`. `isDeferred` is reliable on Android; on iOS the native SDK does
not forward an `is_deferred` flag on the click event, so it always returns
`null` there.

##### <a id="AppsFlyerException"> **`AppsFlyerException`**

Contains an optional numeric error code and message. Native failures can use
HTTP-style codes (`400`, `422`, `500`, …). When the platform supplies a
non-numeric code, `code` is `null` and `message` carries the failure text.

Calling a platform-only API on the wrong platform usually does not throw. Most
guarded APIs log a warning, skip the native call, and return a safe default —
`null` or `false` for APIs with a return value, and nothing for `void` APIs.
Seven symmetric getters and setters route through the native RPC layer instead:
`getHostName`, `getHostPrefix`, `getOutOfStore`, `isPreInstalledApp`,
`getAttributionId`, `setUseReceiptValidationSandbox`, and
`setUseUninstallSandbox`. Wrong-platform calls to those APIs surface as
`AppsFlyerException` (typically code `404` on iOS; on Android the interim RPC
dispatcher maps unknown methods to code `422`).

---


<a id="initSdk"></a>
##### <a id="init"> **`Future<void> init({required String devKey, String? appId})`**

Initializes the native SDK without sending a session. `appId` is the Apple App
ID required by the native iOS SDK. It is optional and is not sent to the native SDK on Android.

Invalid `devKey` or `appId` values are validated by the native RPC layer and
reported as `AppsFlyerException` (typically code `422`) when the RPC rejects
the request.

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

final appsflyerSdk = AppsFlyerSdk.instance;
await appsflyerSdk.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);
```

Register conversion, deep-link, and session-ready listeners explicitly with
their corresponding registration methods.

---
**<a id="enableDebug"> `Future<void> enableDebug(bool enabled)`**

Enables or disables native SDK debug logging. Enable it only for development
and troubleshooting. May be called before [`init`](#init); call before
[`start`](#start) so the first session uses the selected setting.

```dart
await appsflyerSdk.enableDebug(true);
```

---
**<a id="setLogLevel"> `Future<void> setLogLevel(AFLogLevel logLevel)`** — **Android only**

Sets the Android SDK logging level. On iOS the call is ignored with a logged
warning. Use [`enableDebug`](#enableDebug) for a cross-platform debug toggle.

```dart
await appsflyerSdk.setLogLevel(AFLogLevel.debug);
```

---
**<a id="registerConversionListener"> `Future<void> registerConversionListener()`**

Registers the native conversion-data listener. Subscribe to
`onConversionDataSuccess` and `onConversionDataFailure` first.

```dart
await appsflyerSdk.registerConversionListener();
```

---
<a id="unregisterConversionDataListener"></a>
**<a id="unregisterConversionListener"> `Future<void> unregisterConversionListener()`** — **Android only**

Unregisters the native Android conversion-data listener. Call
`registerConversionListener()` again to resume receiving conversion-data
events. On iOS the call is ignored with a logged warning.

```dart
await appsflyerSdk.unregisterConversionListener();
```

---
**<a id="registerDeepLinkListener"> `Future<void> registerDeepLinkListener()`**

Registers the native Unified Deep Linking listener. Subscribe to
`onDeepLinkReceived` first.

```dart
await appsflyerSdk.registerDeepLinkListener();
```

---
**<a id="unregisterDeeplinkListener"> `Future<void> unregisterDeeplinkListener()`** — **Android only**

Requests that Android stop forwarding Unified Deep Linking events. In the
current Android integration, subsequent events may still be delivered; do not
rely on this method to disable deep-link handling. On iOS the call is ignored
with a logged warning.

```dart
await appsflyerSdk.unregisterDeeplinkListener();
```

---
<a id="startSDK"></a>
##### <a id="start"> **`Future<void> start({bool awaitResponse = false})`**
In SDK 7, `init(...)` only initializes the SDK; it does not send a session
(Launch). Call `start()` to report one. Unlike SDK 6, there is no `manualStart`
option — initialization never triggers a session automatically.

When `awaitResponse` is `true`, the Future completes when the native request
succeeds and throws `AppsFlyerException` when it fails. A timeout does not
cancel the native request, which may still succeed later.

When `awaitResponse` is `false` (default), the Future completes when the
native SDK accepts the request. Delivery success or failure is not reported.

| parameter       | type   | description |
| --------------- | ------ | ----------- |
| `awaitResponse` | `bool` | Optional. Defaults to `false`. When `true`, wait for the native request callback. When `false`, return when the native SDK accepts the request. |

**`start()` must be called once per foreground cycle.** The native SDK resets its "started" state every time the app is backgrounded, so a single `start()` at launch reports only the first session — subsequent foregrounds send nothing. Subscribe to `onSessionReady`, which fires once per foreground cycle when the native SDK's session-readiness conditions are satisfied:
```dart
// Recommended SDK 7 pattern: start on every session-ready signal.
appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});
await appsflyerSdk.registerSessionReadyListener();
```
Gate the first session by deferring the `start()` call inside the stream
listener.
---
<a id="onInstallConversionData"></a>
#### <a id="onConversionDataSuccess"> **`Stream<Map<String, dynamic>> get onConversionDataSuccess`**

Emits successful conversion-data payloads. Subscribe before calling
`registerConversionListener()`.

_Example:_

```dart
appsflyerSdk.onConversionDataSuccess.listen((data) {
  print("conversion data: $data");
});
await appsflyerSdk.registerConversionListener();
```

**<a id="onConversionDataFailure"> `Stream<Map<String, dynamic>> get onConversionDataFailure`**
emits the raw conversion-data failure payload reported by the native SDK. This
event is independent of listener registration — `registerConversionListener()`
itself already succeeded. The payload shape differs by platform: Android
reports `{"error": String}` with no error code; iOS reports `{"error":
String, "code": int}`. Cancel the Dart stream subscription when it is no
longer needed. Android also exposes
[`unregisterConversionListener()`](#unregisterConversionListener) to remove its
native listener; iOS has no corresponding unregister operation.

**<a id="getAttributionId"> `Future<String?> getAttributionId()`** — returns the Facebook (Katana) attribution ID the SDK reads from the installed Facebook app's on-device content provider (also attached to attribution payloads automatically). Most apps never need it directly; exposed for parity with the native SDK. **Android only** — calling it on iOS throws `AppsFlyerException` when the native RPC layer reports the method as unavailable.

_Example:_
```dart
appsFlyerSdk.getAttributionId().then((id) {
  print("Facebook attribution ID: $id");
});
```

<a id="onDeepLinking"></a>
#### <a id="onDeepLinkReceived"> **`Stream<DeepLinkResult> get onDeepLinkReceived`**

Emits Unified Deep Linking results. Subscribe before calling
`registerDeepLinkListener()`.

_Example:_

```dart
appsflyerSdk.onDeepLinkReceived.listen((result) {
  print("result: $result");
});
await appsflyerSdk.registerDeepLinkListener();
```

---
##### <a id="logEvent"> **`Future<void> logEvent(String eventName, {Map<String, dynamic>? eventValues, bool awaitResponse = false})`**

- These in-app events help you to understand how loyal users discover your app, and attribute them to specific
  campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  to send ROI (Return on Investment) and LTV (Lifetime Value).
- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
- Result reporting mirrors [`start`](#start); both accept `awaitResponse` and default to fire-and-forget acceptance by the native SDK.

| parameter       | type     | description                                                                                                                                                                       |
| --------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventName`     | `String` | Use descriptive, action-based names (e.g., "purchase", "add_to_cart", "level_completed"), keep names concise but meaningful, use lowercase with underscores for consistency and avoid special characters and spaces. See the [recommended event list by business](https://support.appsflyer.com/hc/en-us/articles/115005544169-In-app-events-Overview#recommended-events-by-business-vertical). |
| `eventValues`   | `Map<String, dynamic>?` | Optional named event details |
| `awaitResponse` | `bool` | Optional named parameter. Defaults to `false`. When `true`, wait for the native request callback. When `false`, return when the native SDK accepts the request. |

_Example:_

```dart
try {
  await appsflyerSdk.logEvent(
    eventName,
    eventValues: eventValues,
    awaitResponse: true,
  );
  print("logEvent success");
} on AppsFlyerException catch (error) {
  print("logEvent error: $error");
}

// Fire-and-forget:
await appsflyerSdk.logEvent(
  eventName,
  eventValues: eventValues,
  awaitResponse: false,
);
```

---

##### <a id="logLocation"> **`Future<void> logLocation({required double latitude, required double longitude})`**

Manually logs the device location for the current user. The Future completes
when the native SDK accepts the fire-and-forget call. Supported on Android
and iOS. `latitude` must be between -90 and 90, and `longitude` must be between
-180 and 180.

```dart
await appsflyerSdk.logLocation(
  latitude: 32.0853,
  longitude: 34.7818,
);
```

---

##### <a id="logSession"> **`Future<void> logSession()`**

Manually logs a session on Android. For typical Flutter apps, use
[`start`](#start) when [`onSessionReady`](#onSessionReady) emits instead.
**Android only**; on iOS the call is ignored with a logged warning.

```dart
await appsflyerSdk.logSession();
```

---

## SDK 7 APIs

### Session readiness (SDK 7 session model)

In SDK 7 the plugin initializes on [`init`](#init); a session is sent when
the app calls [`start`](#start). Because the native SDK requires `start()` once
per foreground cycle, subscribe to `onSessionReady` before enabling the native
listener.

**<a id="registerSessionReadyListener"> `Future<void> registerSessionReadyListener()`**

Enables the native readiness event. `onSessionReady` emits **once per foreground
cycle** when the native session-readiness conditions are satisfied. These
conditions can include bounded launch deep-link processing. Call `start()` from
the stream listener so every foreground reports a session.

```dart
appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});
await appsflyerSdk.registerSessionReadyListener();
```

Platform support: Android ✓ · iOS ✓.

**<a id="onSessionReady"> `Stream<void> get onSessionReady`** — emits once per
foreground cycle when the native SDK is ready for `start()`.

**<a id="unregisterSessionReadyListener"> `Future<void> unregisterSessionReadyListener()`** — removes the native readiness listener (Android ✓ · iOS ✓).

**<a id="isSessionReady"> `Future<bool> isSessionReady()`** — returns whether all
session-readiness conditions are currently satisfied. Supported on both platforms.

```dart
appsFlyerSdk.onSessionReady.listen((_) => print("session ready"));
await appsFlyerSdk.registerSessionReadyListener();
final ready = await appsFlyerSdk.isSessionReady();
```

### Setter persistence (SDK 7)

The runtime/session configuration setters listed below are not a substitute for
persistent application configuration. Re-apply them when the application
process starts. Individual APIs can have different storage behavior; for
example, Android persists the custom value supplied through `setInstallId`.

Re-apply your configuration setters on **every cold start, before
[`start`](#start)**, so they attach to that launch event:

```dart
// Runs on every cold start (e.g. from initState), before the first start().
await appsFlyerSdk.setCustomerUserId("user-42");
await appsFlyerSdk.setCurrencyCode("EUR");
await appsFlyerSdk.setAdditionalData({"tenant": "eu"});
await appsFlyerSdk.setConsentData(
  isUserSubjectToGDPR: false,
);
```

Within a running process the values persist across background→foreground, so you
only re-apply them **once per cold start** — not on every `start()`. Setters
that follow this rule include [`setCustomerUserId`](#setCustomerUserId),
[`setCurrencyCode`](#setCurrencyCode), [`setAdditionalData`](#setAdditionalData),
[`setConsentData`](#setConsentData), [`anonymizeUser`](#anonymizeUser),
[`setSharingFilterForPartners`](#setSharingFilterForPartners),
[`setHost`](#setHost), and the [hashed-PII](#setUserEmail) setters.

### Hashed PII

The email, phone, first-name, and last-name setters normalize and hash (SHA-256)
their values on-device before sending them to AppsFlyer. The Facebook
App-Scoped ID is numeric and is not hashed. These APIs are supported on Android
and iOS.

| API | Description |
| --- | --- |
| <a id="setUserEmail"></a>`setUserEmail(String email)` | Hash the user's email |
| <a id="setUserPhone"></a>`setUserPhone(String countryCode, String phoneNumber)` | Hash the user's phone number |
| <a id="setUserFirstName"></a>`setUserFirstName(String firstName)` | Hash the user's first name |
| <a id="setUserLastName"></a>`setUserLastName(String lastName)` | Hash the user's last name |
| <a id="setUserFbLoginId"></a>`setUserFbLoginId(int fbLoginId)` | Set the numeric Facebook App-Scoped ID |
| <a id="clearUserPii"></a>`clearUserPii()` | Clear all previously set PII (hashed email/phone/name fields + the fb login id) |

```dart
await appsFlyerSdk.setUserEmail("a@a.com");
await appsFlyerSdk.setUserPhone("1", "5551234567");
await appsFlyerSdk.clearUserPii();
```

---

## Other functionalities:
**<a id="anonymizeUser"> `Future<void> anonymizeUser(bool shouldAnonymize)`**

It is possible to anonymize specific user identifiers within AppsFlyer analytics.</br>
This complies with both the latest privacy requirements (GDPR, COPPA) and Facebook's data and privacy policies. To anonymize an app user.
| parameter                   | type     | description                                                |
| ----------                  |----------|------------------                                          |
| shouldAnonymize             | boolean  | True if want Anonymize user Data (default value is false). |

_Example:_
```dart
await appsFlyerSdk.anonymizeUser(true);
```
---
**<a id="setMinTimeBetweenSessions"> `Future<void> setMinTimeBetweenSessions(int seconds)`**
You can set the minimum time between session (the default is 5 seconds)
```dart
await appsFlyerSdk.setMinTimeBetweenSessions(3);
```
---
**<a id="stop"> `Future<void> stop(bool shouldStop)`**
You can stop sending events to Appsflyer by using this method.

_Example:_
```dart
await widget.appsFlyerSdk.stop(true);
```
---
**<a id="isStopped"> `Future<bool> isStopped()`** — **Android only**

Returns whether the SDK is currently stopped (see `stop`). On iOS it logs a
warning and returns `false`.

_Example:_
```dart
final stopped = await appsFlyerSdk.isStopped();
```
---
**<a id="setCurrencyCode"> `Future<void> setCurrencyCode(String currencyCode)`**

_Example:_
```dart
await appsFlyerSdk.setCurrencyCode("USD");
```
---
**<a id="setIsUpdate"> `Future<void> setIsUpdate(bool isUpdate)`** — **Android only**

_Example:_
```dart
await appsFlyerSdk.setIsUpdate(true);
```
---
**<a id="enableTCFDataCollection"> `Future<void> enableTCFDataCollection(bool shouldCollect)`**

The `enableTCFDataCollection` method is employed to control the automatic collection of the Transparency and Consent Framework (TCF) data. By setting this flag to `true`, the system is instructed to automatically collect TCF data. Conversely, setting it to `false` prevents such data collection.

_Example:_
```dart
await appsFlyerSdk.enableTCFDataCollection(true);
```
---
<a id="setConsentDataV2"></a>
**<a id="setConsentData"> `Future<void> setConsentData({required bool isUserSubjectToGDPR, bool? hasConsentForDataUsage, bool? hasConsentForAdsPersonalization, bool? hasConsentForAdStorage})`**

### Sets user consent preferences for GDPR and ad personalization

The named parameters provide manual GDPR and DMA consent data. For a complete workflow,
see the [DMA compliance documentation](consent-dma.md).

1. Users subjected to GDPR:

```dart
await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: true,
  hasConsentForDataUsage: true,
  hasConsentForAdsPersonalization: true,
  hasConsentForAdStorage: true,
);
```

2. Users not subject to GDPR:

```dart
await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: false,
);
```

When GDPR applies, `hasConsentForDataUsage` and
`hasConsentForAdsPersonalization` are required. The optional
`hasConsentForAdStorage` value represents whether the user consented to
ad-related storage.

To reflect consent in the conversion payload, configure either
`enableTCFDataCollection` or `setConsentData` after initialization and
before the first `start()`:

```dart
final appsflyerSdk = AppsFlyerSdk.instance;
await appsflyerSdk.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);

await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: true,
  hasConsentForDataUsage: true,
  hasConsentForAdsPersonalization: true,
);

appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});
await appsflyerSdk.registerSessionReadyListener();
```

If both TCF collection and explicit consent are used, AppsFlyer backend
prioritizes the explicit data supplied through `setConsentData`.

---
**<a id="setCustomerUserId"> `Future<void> setCustomerUserId(String customerId)`**

[What is customer user id?](https://support.appsflyer.com/hc/en-us/articles/207032016-Customer-User-ID)

_Example:_
```dart
await appsFlyerSdk.setCustomerUserId("id");
```
---
**<a id="setAdditionalData"> `Future<void> setAdditionalData(Map<String, dynamic> customData)`**

`customData` must be non-null; pass an empty map to clear the data.

_Example:_
```dart
var data = {"key1": "value1", "key2": "value2"};
await appsFlyerSdk.setAdditionalData(data);
```
---
<a id="setCollectAndroidId"></a>
**<a id="setCollectAndroidID"> `Future<void> setCollectAndroidID(bool isCollect)`** — **Android only**

_Example:_
```dart
await appsFlyerSdk.setCollectAndroidID(true);
```
---
**<a id="setHost"> `Future<void> setHost(String hostPrefixName, String hostName)`**

Changes the default AppsFlyer host. Use this method only when instructed by
AppsFlyer Support.

- **Android:** `hostName` must be non-empty. `hostPrefixName` may be empty.
- **iOS:** both `hostPrefixName` and `hostName` must be non-empty.

Invalid arguments are reported as `AppsFlyerException`.

_Example:_
```dart
await appsFlyerSdk.setHost("pref", "my-host");
```
---
**<a id="getHostName"> `Future<String> getHostName()`** — **Android only**

_Example:_
```dart
appsFlyerSdk.getHostName().then((name) {
         print("Host name: ${name}");
       });
```
---
**<a id="getHostPrefix"> `Future<String> getHostPrefix()`** — **Android only**

_Example:_
```dart
appsFlyerSdk.getHostPrefix().then((name) {
         print("Host prefix: ${name}");
       });
```
---
**<a id="updateServerUninstallToken"> `Future<void> updateServerUninstallToken(String token)`**

Registers a token for uninstall measurement. Pass an FCM registration token on
Android or a hexadecimal APNs device token on iOS.

Token format differs per platform: on **Android** pass the FCM/GCM registration
token as-is; on **iOS** pass the APNs device token **hex-encoded** as an
even-length string (a non-hex string is rejected natively). On iOS,
`getAPNSToken()` already returns the token in hex form.

_Example:_
```dart
await appsFlyerSdk.updateServerUninstallToken(token);
```
---
**<a id="validatePurchase"> Validate Purchase**

***Cross-platform API:***

**<a id="validateAndLogInAppPurchase"> `Future<Map<String, dynamic>> validateAndLogInAppPurchase(AFPurchaseDetails purchase, {Map<String, String>? additionalParameters, bool awaitResponse = true})`**

The unified purchase validation API works across Android and iOS. Use the
purchase-details implementation for the current platform.

| Parameter | Type | Description |
|-----------|------|-------------|
| `purchase` | `AFPurchaseDetails` | An `AFAndroidPurchaseDetails` or `AFIOSPurchaseDetails` instance |
| `additionalParameters` | `Map<String, String>?` | Optional additional parameters |
| `awaitResponse` | `bool` | Optional. Defaults to `true`. Android honors this value; iOS always waits for completion. |

With `awaitResponse: true`, the Future waits for the native validation result.
On Android, `awaitResponse: false` starts validation without a result callback
and the Future completes with an empty map. On iOS, validation always waits for
completion and returns its result.

<a id="AFPurchaseDetails"></a>
**AFPurchaseDetails interface:**
| Property | Type | Description |
|----------|------|-------------|
| `purchaseType` | `AFPurchaseType` | Type of purchase (oneTimePurchase or subscription) |
| `productId` | `String` | Product identifier |

<a id="AFAndroidPurchaseDetails"></a>
**AFAndroidPurchaseDetails:**
| Property | Type | Description |
|----------|------|-------------|
| `purchaseType` | `AFPurchaseType` | Type of Google Play purchase |
| `purchaseToken` | `String` | Google Play purchase token |
| `productId` | `String` | Product identifier |

<a id="AFIOSPurchaseDetails"></a>
**AFIOSPurchaseDetails:**
| Property | Type | Description |
|----------|------|-------------|
| `purchaseType` | `AFPurchaseType` | Type of App Store purchase |
| `transactionId` | `String` | App Store transaction ID |
| `productId` | `String` | Product identifier |

<a id="AFPurchaseType"></a>
**AFPurchaseType:**
- `AFPurchaseType.oneTimePurchase` - For one-time in-app purchases
- `AFPurchaseType.subscription` - For subscription purchases

_Example:_
```dart
final AFPurchaseDetails purchaseDetails = Platform.isAndroid
    ? const AFAndroidPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        purchaseToken: "your_purchase_token",
        productId: "your_product_id",
      )
    : const AFIOSPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        transactionId: "your_transaction_id",
        productId: "your_product_id",
      );

// Validate purchase
try {
  Map<String, dynamic> result = await appsFlyerSdk.validateAndLogInAppPurchase(
    purchaseDetails,
    additionalParameters: {"custom_param": "value"},
    awaitResponse: true,
  );
  print("Validation successful: $result");
} on AppsFlyerException catch (error) {
  print("Validation failed: $error");
} on ArgumentError catch (error) {
  // A purchase-details object was used on the wrong platform.
  print("Invalid purchase details: $error");
}
```

**Key Benefits:**
- **Cross-platform compatibility**: Works on both Android and iOS with the same API
- **Type safety**: Uses structured data classes instead of platform-specific parameters
- **Enhanced error handling**: Provides detailed error information in structured format (including `NSError` details on iOS)
- **Future-proof**: Built on AppsFlyer's latest V2 validation infrastructure
- **Platform mapping**: Each purchase-details implementation uses the
  corresponding Android or iOS purchase-validation model

---

***Purchase validation sandbox mode for iOS:***

<a id="setUseReceiptValidationSandbox"></a>
`Future<void> setUseReceiptValidationSandbox(bool sandbox)` — **iOS only**

Enables sandbox mode for App Store receipt validation.

_Example:_
```dart
await appsFlyerSdk.setUseReceiptValidationSandbox(true);
```

<a id="setUseUninstallSandbox"></a>
`Future<void> setUseUninstallSandbox(bool sandbox)` — **iOS only**

Enables sandbox mode for uninstall-measurement validation (companion of `setUseReceiptValidationSandbox`).

_Example:_
```dart
await appsFlyerSdk.setUseUninstallSandbox(true);
```

---

<a id="validatePurchaseV2"></a>
##### **validateAndLogInAppPurchase**

See [Validate Purchase](#validatePurchase) above for the full `validateAndLogInAppPurchase` reference — signature, `AFPurchaseDetails` / `AFPurchaseType`, example, key benefits, and the iOS sandbox toggles. This anchor is kept for existing links.

---
## **<a id="sendPushNotificationData"> `Future<void> sendPushNotificationData({required String campaign, required String pid, bool isRetargeting = false, Map<String, dynamic>? additionalParameters})`** _(Android only)_

Push-notification campaigns are used to create re-engagements with existing users → [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns)

The Android API maps directly to the native `AFPushData` fields.
Calling it triggers a new Android Launch request even when the SDK already sent
a Launch in the current session.

## **<a id="handlePushNotification"> `Future<void> handlePushNotification(Map<String, dynamic> pushPayload)`** _(iOS only)_

Passes the push-notification payload to the iOS SDK. Preserve the AppsFlyer
custom-data structure from the notification; native integrations should pass
the complete APNs `userInfo` dictionary.

### Platform-Specific Requirements

🟩 **Android:**  
Call `sendPushNotificationData` with `campaign` and `pid`, plus optional
`isRetargeting` and `additionalParameters` values.

🍎 **iOS:**  
Call `handlePushNotification` with the complete notification payload.

When using `firebase_messaging`, `RemoteMessage.data` contains only the custom
data fields, not the complete APNs `userInfo` dictionary. Ensure that every
AppsFlyer attribution field is present in that custom data. If your provider
encodes a nested object as a JSON string, decode it before reading its fields.

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

**Implementation:**

```dart
Future<void> passPushToAppsFlyer(Map<String, dynamic> data) async {
  if (Platform.isAndroid) {
    final rawAf = data['af'];
    final decodedAf = rawAf is String ? jsonDecode(rawAf) : rawAf;
    final af = Map<String, dynamic>.from(decodedAf as Map);
    await appsFlyerSdk.sendPushNotificationData(
      campaign: af['c'] as String,
      pid: af['pid'] as String,
      isRetargeting: af['is_retargeting'] == true,
    );
  } else if (Platform.isIOS) {
    await appsFlyerSdk.handlePushNotification(data);
  }
}

// 1️⃣ Handle Foreground Messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  await passPushToAppsFlyer(message.data);
});

// 2️⃣ Handle Notification Taps (App in Background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
  await passPushToAppsFlyer(message.data);
});

// 3️⃣ Handle App Launch from Push (Terminated State)
Future<void> handleInitialPush() async {
  final message = await FirebaseMessaging.instance.getInitialMessage();
  if (message != null) {
    await passPushToAppsFlyer(message.data);
  }
}
```

Call `handleInitialPush()` once during app startup, after Flutter is initialized
and the AppsFlyer SDK setup has completed. `getInitialMessage()` returns the
notification that opened an app from the terminated state. A Firebase
background-message handler is a separate flow and is not required to handle a
notification tap that launches the app.

---

### Approach 2: OneLink URL in Push Payload (Recommended)

Use this approach when your push payload contains a **OneLink URL** for deep linking. This method provides a unified deep linking experience.

> ⚠️ **Important:** This approach requires calling **two different methods** depending on the platform!

#### **Step 1: Configure Deep Link Path (BOTH Platforms)**

Call `addPushNotificationDeepLinkPath` before `init()` to tell AppsFlyer where
to find the OneLink URL in your push payload.

```dart
await appsFlyerSdk.addPushNotificationDeepLinkPath(
  ["deeply", "nested", "deep_link"],
);
await appsFlyerSdk.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);
await appsFlyerSdk.registerDeepLinkListener();
```

Push configuration does not replace the SDK 7 session lifecycle. Complete the
normal [`onSessionReady` → `start()` setup](getting-started.md#6-start-sessions)
so the initial Launch and every later foreground session are reported.

#### **Step 2: Send Push Payload to SDK**

**🟩 Android:**  
On Android, calling `addPushNotificationDeepLinkPath` is **sufficient**. The SDK automatically extracts and processes the OneLink URL.

**🍎 iOS:**  
On iOS, you **MUST also call** `handlePushNotification(pushPayload)` to pass the push payload to the SDK so it can extract and process the OneLink URL.

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
Future<void> initializeAppsFlyer() async {
  // STEP 1: Subscribe before registering the corresponding native listeners.
  appsFlyerSdk.onDeepLinkReceived.listen((DeepLinkResult result) {
    if (result.status == DeepLinkStatus.found) {
      print("Deep link found: ${result.deepLink?.deepLinkValue}");
      // Handle deep-link navigation here.
    }
  });

  // Required: report a session on every foreground cycle.
  appsFlyerSdk.onSessionReady.listen((_) async {
    try {
      await appsFlyerSdk.start(awaitResponse: true);
      print("AppsFlyer session reported.");
    } on AppsFlyerException catch (error) {
      print("AppsFlyer start error: $error");
    }
  });

  // STEP 2: Configure the deep-link path before init().
  await appsFlyerSdk.addPushNotificationDeepLinkPath(
    ["deeply", "nested", "deep_link"],
  );

  // STEP 3: Initialize the SDK.
  await appsFlyerSdk.init(
    devKey: '<DEV_KEY>',
    appId: '<APP_ID>',
  );

  // STEP 4: Enable native deep-link events.
  await appsFlyerSdk.registerDeepLinkListener();

  // STEP 5: Register last because this can emit onSessionReady immediately.
  await appsFlyerSdk.registerSessionReadyListener();
}

// ========================================
// 2. Handle Push Notifications
// ========================================

// 🍎 iOS: MUST call handlePushNotification
// 🟩 Android: addPushNotificationDeepLinkPath is sufficient

// 1️⃣ Foreground Messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  // iOS: Required to process OneLink URL
  if (Platform.isIOS) {
    await appsFlyerSdk.handlePushNotification(message.data);
  }
});

// 2️⃣ Background Notification Taps (App in Background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
  // iOS: Required to process OneLink URL
  if (Platform.isIOS) {
    await appsFlyerSdk.handlePushNotification(message.data);
  }
});

// 3️⃣ App Launch from Push (Terminated State)
Future<void> handleInitialPush() async {
  final message = await FirebaseMessaging.instance.getInitialMessage();
  if (message != null) {
    // iOS: Required to process OneLink URL from terminated state
    if (Platform.isIOS) {
      await appsFlyerSdk.handlePushNotification(message.data);
    }
  }
}
```

Call `handleInitialPush()` once after `initializeAppsFlyer()` completes. On
Android, `addPushNotificationDeepLinkPath()` handles the configured OneLink path;
the explicit terminated-state forwarding above is required only on iOS.

#### **Key Differences Between Approaches:**

|| Traditional `af` Object | OneLink URL (Recommended) |
|---|---|---|
| **Android** | `sendPushNotificationData(...)` | `addPushNotificationDeepLinkPath()` (auto-handles) |
| **iOS** | `handlePushNotification(pushPayload)` | `addPushNotificationDeepLinkPath()` **+** `handlePushNotification(pushPayload)` |
| **Deep Linking** | Basic attribution only | Full deep linking with `onDeepLinkReceived` callback |
| **Use Case** | Simple re-engagement | Re-engagement + in-app navigation |

---

### Summary

- **Traditional approach**: Call Android `sendPushNotificationData(...)` or iOS `handlePushNotification(pushPayload)`
- **OneLink approach (Recommended)**:
  - ✅ **Both platforms**: Call `addPushNotificationDeepLinkPath()` before SDK init
  - ✅ **iOS only**: Also call `handlePushNotification(pushPayload)` when push is received
  - ✅ **Both platforms**: Handle deep links in `onDeepLinkReceived` callback

    
---
## **<a id="addPushNotificationDeepLinkPath"> `Future<void> addPushNotificationDeepLinkPath(List<String> deepLinkPath)`**
    
Registers a **custom key path** for resolving deep links inside **custom JSON payloads** in push notifications.

This is the recommended method of integrating AppsFlyer with push notifications. [Learn more here.](https://support.appsflyer.com/hc/en-us/articles/207364076-Measuring-Push-Notification-Re-Engagement-Campaigns) </br>
> ⚠️ Call this method before `init()`. `deepLinkPath` must not be empty. ⚠️


_Example:_
```dart
await appsFlyerSdk.addPushNotificationDeepLinkPath(
  ["deeply", "nested", "deep_link"],
);
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

**<a id="setAppInviteOneLink"> `Future<void> setAppInviteOneLink(String oneLinkId)`**

2. Set the `AppsFlyerInviteLinkParams` class to set the query params in the user invite link:

<a id="AppsFlyerInviteLinkParams"></a>

```dart
class AppsFlyerInviteLinkParams {
  final String? channel;
  final String? campaign;
  final String? referrerName;
  final String? referrerImageUrl;
  final String? referrerCustomerId;
  final String? baseDeepLink;
  final String? brandDomain;
  final Map<String, String>? userParams;
}
```

3. Call the generateInviteLink API to generate the user invite link.

**<a id="generateInviteLink"> `Future<String> generateInviteLink({AppsFlyerInviteLinkParams? parameters, bool awaitResponse = true})`**

The Future completes with the generated URL. Native generation failures are
reported as `AppsFlyerException`. On Android, `awaitResponse: true` waits for
asynchronous short-link generation and `false` returns the synchronously
generated long link. On iOS, link generation always waits for the asynchronous
result.

| Parameter | Type | Description |
|-----------|------|-------------|
| `parameters` | `AppsFlyerInviteLinkParams?` | Optional OneLink generation parameters |
| `awaitResponse` | `bool` | Optional. Defaults to `true`. Android honors this value; iOS always waits for completion. |

_Example:_
```dart
await appsFlyerSdk.setAppInviteOneLink('OnelinkID');

const AppsFlyerInviteLinkParams inviteLinkParams = AppsFlyerInviteLinkParams(
      channel: "",
      referrerName: "",
      baseDeepLink: "",
      brandDomain: "",
      referrerCustomerId: "",
      referrerImageUrl: "",
      campaign: "",
      userParams: {"key":"value"}
);

final url = await appsFlyerSdk.generateInviteLink(
  parameters: inviteLinkParams,
  awaitResponse: true,
);
print(url);
```

4. Log the `af_invite` event when the user actually shares the invite:

**<a id="logInvite"> `Future<void> logInvite(String channel, [Map<String, String>? eventParameters])`**

Logs the `af_invite` in-app event so AppsFlyer can attribute the invite and any
downstream installs to the referring user. The returned `Future<void>` completes
after the native SDK accepts the logging call. The native API does not
provide a network-completion callback. Supported on Android and iOS.

_Example:_
```dart
await appsFlyerSdk.logInvite("facebook", {"referrerId": "user-123"});
```
---
**<a id="crossPromotion"> Cross promotion**

**<a id="logCrossPromoteImpression"> `Future<void> logCrossPromoteImpression(String appId, {String campaign = '', Map<String, String>? userParams})`**

Records an impression for a promoted app:

```dart
await appsFlyerSdk.logCrossPromoteImpression(
  "promoted.app.id",
  campaign: "summer",
  userParams: {"source": "banner"},
);
```

**<a id="logAndOpenStore"> `Future<void> logAndOpenStore(String promotedAppId, {String campaign = '', Map<String, String>? userParams})`**

Records the promotion and asks the native SDK to open the promoted app's store
page:

```dart
await appsFlyerSdk.logAndOpenStore(
  "promoted.app.id",
  campaign: "summer",
  userParams: {"source": "banner"},
);
```

Both APIs are supported on Android and iOS.

---
**<a id="enableFacebookDeferredApplinks"> `Future<void> enableFacebookDeferredApplinks(bool isEnabled)`**

Please make sure the relevant Facebook dependecies are added to the project!
Call this method before `init()`.

For more information check the following article:
https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#advanced-using-facebook-ads-appsflyer-sdks-for-deferred-deep-linking

_Example:_
```dart
await appsFlyerSdk.enableFacebookDeferredApplinks(true);
```
---
**<a id="setFacebookDeferredAppLink"> `Future<void> setFacebookDeferredAppLink(String? url)`** _(iOS only)_

Manually sets — or, with `null`, clears — the Facebook deferred app-link URL.
On Android the call is ignored with a logged warning.

Use this only when you already hold the deferred link and want to skip the Facebook SDK lookup; otherwise prefer `enableFacebookDeferredApplinks(true)`.

_Example:_
```dart
await appsFlyerSdk.setFacebookDeferredAppLink(
  "https://myapp.onelink.me/abc123",
);
```
---
<a id="disableSKAdNetwork"></a>
**<a id="setDisableSKAdNetwork"> `Future<void> setDisableSKAdNetwork(bool disable)`** — **iOS only**

Use this API in order to disable the SK Ad network (request will be sent but
the rules won't be returned). On Android the call is ignored with a logged
warning.

_Example:_
```dart
await appsFlyerSdk.setDisableSKAdNetwork(true);
```
---
<a id="disableAppleAdsAttribution"></a>
**<a id="setDisableAppleAdsAttribution"> `Future<void> setDisableAppleAdsAttribution(bool disable)`** — **iOS only**

Disables Apple Ads (Apple Search Ads) attribution via the AdServices framework
— pass `true` to stop the SDK from calling
`AAAttribution.attributionToken` (iOS 14.3+). On Android the call is ignored
with a logged warning.

_Example:_
```dart
if (Platform.isIOS) {
  await appsFlyerSdk.setDisableAppleAdsAttribution(true);
}
```
---
<a id="disableIDFVCollection"></a>
**<a id="setDisableIDFVCollection"> `Future<void> setDisableIDFVCollection(bool disable)`** — **iOS only**

Disables collection of the IDFV (Identifier for Vendor) — pass `true` to stop
the SDK from collecting it. Set it before `start()`. On Android the call is
ignored with a logged warning.

_Example:_
```dart
if (Platform.isIOS) {
  await appsFlyerSdk.setDisableIDFVCollection(true);
}
```
---
**<a id="setShouldCollectDeviceName"> `Future<void> setShouldCollectDeviceName(bool collect)`** — **iOS only**

Enables collection of the device name (e.g. `"John's iPhone"`). This is an
**opt-in** — collection is **off by default** and the device name is personal
data (PII), so only enable it if your privacy policy covers it. Pass `true` to
start collecting it. On Android the call is ignored with a logged warning.

_Example:_
```dart
if (Platform.isIOS) {
  await appsFlyerSdk.setShouldCollectDeviceName(true);
}
```
---
**<a id="getAppsFlyerUID"> `Future<String?> getAppsFlyerUID()`**

Use this API in order to get the AppsFlyer ID.

_Example:_
```dart
appsFlyerSdk.getAppsFlyerUID().then((AppsFlyerId) {
  print("AppsFlyer ID: ${AppsFlyerId}");
});
```
---
**<a id="getSdkVersion"> `Future<String> getSdkVersion()`**

Returns the native AppsFlyer SDK version.

```dart
final sdkVersion = await appsFlyerSdk.getSdkVersion();
```

---
**<a id="pluginVersion"> `String get pluginVersion`**

Returns the Flutter plugin version without invoking a native method.

```dart
print(appsFlyerSdk.pluginVersion);
```

---
**<a id="isPreInstalledApp"> `Future<bool> isPreInstalledApp()`** — **Android only**

Returns whether the app install was a device preinstall (OEM/manufacturer). On
iOS the native RPC layer reports the method as unavailable and the call throws
`AppsFlyerException`. See also `setPreinstallAttribution`.

_Example:_
```dart
final bool preinstalled = await appsFlyerSdk.isPreInstalledApp();
```
---
**<a id="setCurrentDeviceLanguage"> `Future<void> setCurrentDeviceLanguage(String language)`** — **iOS only**

Use this API in order to set the language

_Example:_
```dart
await appsFlyerSdk.setCurrentDeviceLanguage("en");
```
---
**<a id="setInstallId"> `Future<void> setInstallId(String installId)`**

Sets a unique install id for the app installation, letting you correlate the AppsFlyer install with an id you generate yourself (e.g. for server-side reconciliation). Supported on both platforms, but the call order and setup requirements differ:

- **iOS**: call this *before* `init()` (before the dev key is set). Requires `AppsFlyerAllowCustomInstallId` set to `YES` in `Info.plist`.
- **Android**: call this *after* `init()`. Requires the `<meta-data>` flag `APPSFLYER_ALLOW_CUSTOM_INSTALL_ID` set to `true` in `AndroidManifest.xml`.

On both platforms, the call is silently ignored — no error is returned — if the corresponding manifest/plist flag is missing.

_Example:_
```dart
await appsFlyerSdk.setInstallId("install-123");
```
---
**<a id="setPreinstallAttribution"> `Future<void> setPreinstallAttribution(String mediaSource, {String campaign = '', String siteId = ''})`**

Attributes the install to a device preinstall (OEM / manufacturer) deal, declaring that the app shipped preinstalled and attributing the install to the given `mediaSource`, `campaign`, and `siteId`. Call it **before** `start()`.

**Android only** — the iOS SDK does not provide this programmatic
preinstall-attribution API. On iOS the call is ignored with a logged warning.

_Example:_
```dart
await appsFlyerSdk.setPreinstallAttribution(
  "media_source",
  campaign: "campaign",
  siteId: "site_id",
);
```
---
**<a id="setAppId"> `Future<void> setAppId(String appId)`**

Overrides the app ID reported to AppsFlyer. Call it **before** `start()`. The
Android SDK rejects an empty `appId`, and the returned Future throws
`AppsFlyerException`.

**Android only** — on iOS the app ID is provided through `init()` and the
iOS SDK has no `setAppId`, so the call is ignored with a logged warning.

_Example:_
```dart
await appsFlyerSdk.setAppId("com.example.app");
```
---
**<a id="setSharingFilterForPartners"> `Future<void> setSharingFilterForPartners(List<String>? partners)`**

Used by advertisers to exclude specified networks/integrated partners from getting data. [Learn more here](https://support.appsflyer.com/hc/en-us/articles/207032126#additional-apis-exclude-partners-from-getting-data)

_Example:_
```dart
await appsFlyerSdk.setSharingFilterForPartners(['facebook_int']);
await appsFlyerSdk.setSharingFilterForPartners(
  ['facebook_int', 'googleadwords_int'],
);
```

Passing `null` or an empty list clears the filter on iOS; the plugin normalizes
both to the same native request, so the two are interchangeable.

Android does not support clearing the filter. A clear request is ignored with a
logged warning and **leaves the existing filter in place**. If you need the
filter gone on Android, you must avoid setting it in the first place.

---
**<a id="setOneLinkCustomDomain"> `Future<void> setOneLinkCustomDomain(List<String> domains)`**

Use this API in order to set branded domains. `domains` must not be empty.

Find more information in the [following article on branded domains](https://support.appsflyer.com/hc/en-us/articles/360002329137-Implementing-Branded-Links).

_Example:_
```dart
await appsFlyerSdk.setOneLinkCustomDomain(
  ["promotion.greatapp.com", "click.greatapp.com", "deals.greatapp.com"],
);
```
---
**<a id="setDisableAdvertisingIdentifiers"> `Future<void> setDisableAdvertisingIdentifiers(bool disable)`**

Disables collection of advertising identifiers (GAID / IDFA / OAID). Pass `true` to **disable** collection (enabled by default).

_Example:_
```dart
await appsFlyerSdk.setDisableAdvertisingIdentifiers(true);
```
---
**<a id="setDisableCollectASA"> `Future<void> setDisableCollectASA(bool disable)`** — **iOS only**

Controls collection of Apple Search Ads attribution data. On Android the call is
ignored with a logged warning.

```dart
if (Platform.isIOS) {
  await appsFlyerSdk.setDisableCollectASA(true);
}
```

---
**<a id="setPartnerData"> `Future<void> setPartnerData(String partnerId, Map<String, dynamic> data)`**

Allows sending custom data for partner integration purposes.

_Example:_
```dart
final partnerData = <String, dynamic>{"puid": "1234", "region": "eu"};
await appsFlyerSdk.setPartnerData("partnerId", partnerData);
```
---
**<a id="setResolveDeepLinkURLs"> `Future<void> setResolveDeepLinkURLs(List<String> urls)`**

Advertisers can wrap an AppsFlyer OneLink within another Universal Link. This Universal Link will invoke the app but any deep linking data will not propagate to AppsFlyer.

setResolveDeepLinkURLs enables you to configure the SDK to resolve the wrapped OneLink URLs, so that deep linking can occur correctly.

`urls` must not be empty.

_Example:_
```dart
await appsFlyerSdk.setResolveDeepLinkURLs(
  ["clickdomain.com", "myclickdomain.com", "anotherclickdomain.com"],
);
```
---
**<a id="setOutOfStore"> `Future<void> setOutOfStore(String sourceName)`**

**Android Only!**

Specify the alternative app store that the app is downloaded from (out-of-store
attribution). Re-apply on every cold start — SDK 7 does not persist setter values.

This API does **not** register manifest receivers. See
[Advanced features — Android Out of Store](advanced-features.md#out-of-store).

_Example:_
```dart
  if (Platform.isAndroid) {
    await appsFlyerSdk.setOutOfStore("amazon");
  }
```
---
**<a id="getOutOfStore"> `Future<String?> getOutOfStore()`**

**Android Only!**

Gets the configured alternative app-store value. If no runtime value was set,
the Android SDK may return the `AF_STORE` manifest value.

_Example:_
```dart
  if (Platform.isAndroid) {
    final store = await appsFlyerSdk.getOutOfStore();
    print(store);
  }
```
---
**<a id="setDisableNetworkData"> `Future<void> setDisableNetworkData(bool isDisable)`**

**Android Only!**

Use to opt-out of collecting the network operator name (carrier) and sim operator name from the device.

_Example:_
```dart
  if (Platform.isAndroid) {
    await appsFlyerSdk.setDisableNetworkData(true);
  }
```
---
**<a id="disableAppSetId"> `Future<void> disableAppSetId()`**

**Android Only!**

Disables the native Android SDK's automatic AppSet ID collection. Use this
method to opt out of AppSet ID collection for privacy compliance.

_Example:_
```dart
  if (Platform.isAndroid) {
    await appsFlyerSdk.disableAppSetId();
  }
```
---

**<a id="performDeepLinking"> `Future<void> performDeepLinking(String url, {bool shouldTriggerSession = false})`**

Manually triggers deep link resolution for a given `url` (full URL, OneLink, or intent-data string). Use it to resolve a deep link before the SDK starts (e.g. when delaying `start()`), or for links that don't arrive through the standard intent / Universal Link flow (e.g. Firebase Messaging).

The resolved link is delivered through the [`onDeepLinkReceived`](#onDeepLinkReceived)
UDL stream on both platforms. `shouldTriggerSession` defaults to `false`, so a
bare `performDeepLinking(url)` resolves the link without an extra Launch and
behaves identically on Android and iOS. The flag is Android-only: pass `true` to
also enqueue a Launch for re-engagement; on iOS it has no effect because the
link is always resolved without an extra managed session.

```dart
Future<void> configureAppsFlyer() async {
  final appsflyerSdk = AppsFlyerSdk.instance;

  appsflyerSdk.onConversionDataSuccess.listen((data) {
    print("conversion data: $data");
  });

  appsflyerSdk.onDeepLinkReceived.listen((DeepLinkResult result) {
    switch (result.status) {
      case DeepLinkStatus.found:
        print(result.deepLink);
        print("deep link value: ${result.deepLink?.deepLinkValue}");
        break;
      case DeepLinkStatus.notFound:
        print("deep link not found");
        break;
      case DeepLinkStatus.error:
        print("deep link error: ${result.error}");
        break;
      case DeepLinkStatus.unknown:
        print("unknown deep link status");
        break;
    }
  });

  await appsflyerSdk.init(
    devKey: '<DEV_KEY>',
    appId: '<APP_ID>',
  );
  await appsflyerSdk.registerConversionListener();
  await appsflyerSdk.registerDeepLinkListener();

  // Resolve a deep link manually.
  await appsflyerSdk.performDeepLinking(
    "https://yourapp.onelink.me/abc123",
  );
}
```

---

**<a id="appendParametersToDeepLinkingURL"> `Future<void> appendParametersToDeepLinkingURL(String contains, Map<String, String> parameters)`**

Appends `parameters` to any deep-link URL that contains the `contains` substring, before the SDK resolves / attributes it. Useful for enriching wrapped OneLinks with extra query parameters. Implemented on both Android and iOS.

Pass a non-empty `contains` and at least one entry in `parameters`. An empty
`contains` is invalid on both platforms, and an empty `parameters` map is
invalid on iOS.

```dart
await appsFlyerSdk.appendParametersToDeepLinkingURL(
  "deeplink",
  {"deep_link_sub1": "cat123", "deep_link_value": "shoes"},
);
```

---

**<a id="setDeepLinkTimeout"> `Future<void> setDeepLinkTimeout(int timeout)`**

Sets the deep-link resolution timeout, in **milliseconds**. Configure it before
`init()`. Use a positive value for a cross-platform configuration. The default
when unset differs by platform: **3000 ms on Android, 60000 ms on iOS**.

```dart
  await appsFlyerSdk.setDeepLinkTimeout(3000);
```

---

### **<a id="logAdRevenue"> `Future<void> logAdRevenue({required String monetizationNetwork, required AFMediationNetwork mediationNetwork, required String currencyIso4217Code, required double revenue, Map<String, dynamic>? additionalParameters})`**

The logAdRevenue API is designed to simplify the process of logging ad revenue events to AppsFlyer from your Flutter application. This API tracks revenue generated from advertisements, enriching your monetization analytics. Below you will find instructions on how to use this API correctly, along with detailed descriptions and examples for various input scenarios.

### **Usage:**
To use the logAdRevenue method, you must:

1. Prepare the required information about the ad revenue event.
1. Pass the values to `logAdRevenue`.

<a id="AdRevenueData"></a>
**Parameters**
The method accepts the following ad revenue values:

* `monetizationNetwork`: The source network from which the revenue was generated (e.g., AdMob, Unity Ads).
* `mediationNetwork`: The mediation platform managing the ad (use AFMediationNetwork enum for supported networks).
* `currencyIso4217Code`: The ISO 4217 currency code representing the currency of the revenue amount (e.g., "USD", "EUR").
* `revenue`: The amount of revenue generated from the ad.
* `additionalParameters`: Additional parameters related to the ad revenue event (optional).


**AFMediationNetwork Enum**
[AFMediationNetwork](#AFMediationNetwork) is an enumeration that includes the supported mediation networks by AppsFlyer. It's important to use this enum to ensure you provide a valid network identifier to the logAdRevenue API.

> **Note (behavior):** The returned Future completes after the plugin validates
> the request and invokes the native logging API. Validation and native call
> failures are surfaced as `AppsFlyerException`. The native API has no delivery
> callback, so completion does not confirm that the event was uploaded.
>
> **Cross-platform note:** The plugin maps
> `AFMediationNetwork.customMediation` and
> `AFMediationNetwork.directMonetizationNetwork` to the correct platform value
> automatically. All public enum values work on both platforms; no caller
> action is needed.

### Example:
```dart
// Log the ad revenue event.
await appsFlyerSdk.logAdRevenue(
  monetizationNetwork: "GoogleAdMob", // Replace with your actual monetization network.
  mediationNetwork: AFMediationNetwork.applovinMax, // Use the value from the enum.
  currencyIso4217Code: "USD", 
  revenue: 1.23,
  additionalParameters: {
    // Optional additional parameters can be added here. This is an example, can be discard if not needed.
    'adUnitId': 'ca-app-pub-XXXX/YYYY', 
    'ad_network_click_id': '12345'
  }
);
```

**Additional Points**
* Mediation network input must be from the provided [AFMediationNetwork](#AFMediationNetwork)
  enum to ensure proper processing by AppsFlyer. For instance, use
  `AFMediationNetwork.googleAdMob` to denote Google AdMob as the Mediation Network.
* The `additionalParameters` map is optional. Use it to pass any extra information you have regarding the ad revenue event; this information could be useful for more refined analytics.
* Make sure the `currencyIso4217Code` adheres to the appropriate standard. Misconfigured currency code may result in incorrect revenue tracking.
