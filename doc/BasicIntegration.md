# 🚀 Basic integration of the SDK

Initialize the SDK to enable AppsFlyer to detect installations, sessions (app opens) and updates.
`AppsflyerSdk` receives either a Map with the defined parameters or an `AppsFlyerOptions` object.

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
        afDevKey: afDevKey,
        appId: appId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 50, // for iOS 14.5
        appInviteOneLink: oneLinkID, // Optional field
        disableAdvertisingIdentifier: false, // Optional field
        disableCollectASA: false); // Optional field

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

| Setting  | Type   | Description   |
| -------- | -------- | ------------- |
| devKey   | String | Your application's [devKey](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#retrieving-the-dev-key) provided by AppsFlyer (required)  |
| appId      | String | Your application's [App ID](https://support.appsflyer.com/hc/en-us/articles/207377436-Adding-a-new-app#available-in-the-app-store-google-play-store-windows-phone-store)  (required for iOS only) that you configured in your AppsFlyer dashboard  |
| showDebug    | bool | Debug mode - set to `true` for testing only, do not release to production with this parameter set to `true`! |
| timeToWaitForATTUserAuthorization  | double | Delays the SDK start for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out. |
| appInviteOneLink    | String | The [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) that is used to generate a User Invite, this is not a required field in the `AppsFlyerOptions`, you may choose to set it later via the appropriate API. |
| disableAdvertisingIdentifier| bool | Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA. |
| disableCollectASA | bool | Opt-out of the Apple Search Ads attributions. |

The next step is to call `initSdk` which have the optional boolean parameters `registerConversionDataCallback` and the deeplink callbacks: `registerOnAppOpenAttributionCallback` 
`registerOnDeepLinkingCallback`
Please keep in mind that registering the `registerOnDeepLinkingCallback` will override the `registerOnAppOpenAttributionCallback`, as the latter is a Legacy callback used for direct deep-linking, please read more about this in our DeepLinking guide.

After we call `initSdk` we can use all of AppsFlyer SDK features.

```dart
appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnAppOpenAttributionCallback: true,
    registerOnDeepLinkingCallback: true
);
```

| Setting  | Description   |
| -------- | ------------- |
| registerConversionDataCallback | Set a listener for the [GCD](https://dev.appsflyer.com/hc/docs/conversion-data) response, it is also the callback used for the [Legacy deferred deeplinking](https://dev.appsflyer.com/hc/docs/android-legacy-apis#deferred-deep-linking) |
| registerOnAppOpenAttributionCallback | Set a listener for the [Legacy direct deeplinking](https://dev.appsflyer.com/hc/docs/android-legacy-apis) response |
| registerOnDeepLinkingCallback | Set a listener for the [UDL](https://dev.appsflyer.com/hc/docs/unified-deep-linking-udl) response |
