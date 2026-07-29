# 🚀 Getting started

This guide takes you through the required setup: creating the SDK instance, initializing
it, and starting sessions with the SDK 7 session-ready model.

> **Audience:** every app integrating the plugin. Complete [Installation](installation-guide.md) first.

## Prerequisites

- The plugin added to your app — see [Installation](installation-guide.md).
- Your AppsFlyer **Dev Key** (from the AppsFlyer dashboard) and, for iOS, your **App ID**.
- **iOS:** minimum deployment target `13.0`. For ATT/IDFA, see [iOS 14 & App Tracking Transparency](#ios-14--app-tracking-transparency) below.
- **Android:** review the `AD_ID` permission note in the [README](../README.md#ad_id-permission-for-android).

## Create the SDK instance

Initialize the SDK to enable AppsFlyer to detect installations, sessions (app opens) and updates.
`AppsflyerSdk` receives either a Map with the defined parameters or an `AppsFlyerOptions` object.

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
        afDevKey: afDevKey,
        appId: appId,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 50, // for iOS 14.5
        appInviteOneLink: oneLinkID, // Optional field
        disableAdvertisingIdentifier: false, // Optional field
        disableCollectASA: false, ); //Optional field

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

| Setting                           | Type   | Description                                                                                                                                                                                                                                                                         |
|-----------------------------------| -------- |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| devKey                            | String | Your application's [devKey](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#retrieving-the-dev-key) provided by AppsFlyer (required)                                                                                                          |
| appId                             | String | Your application's [App ID](https://support.appsflyer.com/hc/en-us/articles/207377436-Adding-a-new-app#available-in-the-app-store-google-play-store-windows-phone-store)  (required for iOS only) that you configured in your AppsFlyer dashboard should be without the 'id' prefix |
| showDebug                         | bool | Debug mode - set to `true` for testing only, do not release to production with this parameter set to `true`!                                                                                                                                                                        |
| timeToWaitForATTUserAuthorization | double | Delays the SDK start for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out.                                                                                                                                                            |
| appInviteOneLink                  | String | The [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) that is used to generate a User Invite, this is not a required field in the `AppsFlyerOptions`, you may choose to set it later via the appropriate API.  |
| disableAdvertisingIdentifier      | bool | Opt-out of the collection of Advertising Identifiers, which include OAID, AAID, GAID and IDFA.                                                                                                                                                                                      |
| disableCollectASA                 | bool | Opt-out of the Apple Search Ads attributions.                                                                                                                                                                                                                                       |

The next step is to call `initSdk` which has the optional boolean parameters `registerConversionDataCallback` and the deep-link callback `registerOnDeepLinkingCallback`.
> These are **set to false by default**, meaning listeners will only be registered if you explicitly pass true.

> `onAppOpenAttribution` (OAOA / legacy direct deep linking) was removed in AppsFlyer SDK 7. Use `registerOnDeepLinkingCallback` (Unified Deep Linking) for all deep-link handling — read more in the [Deep linking guide](deep-linking.md).

After we call `initSdk` we can use all of AppsFlyer SDK features.
Here’s an example of how to register both:
```dart
await appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnDeepLinkingCallback: true
);
```

| Setting  | Description   |
| -------- | ------------- |
| registerConversionDataCallback | Set a listener for the [GCD](https://dev.appsflyer.com/hc/docs/conversion-data) response, it is also the callback used for the [Legacy deferred deeplinking](https://dev.appsflyer.com/hc/docs/android-legacy-apis#deferred-deep-linking) |
| registerOnDeepLinkingCallback | Set a listener for the [UDL](https://dev.appsflyer.com/hc/docs/unified-deep-linking-udl) response |

### startSdk
`startSDK({RequestSuccessListener? onSuccess, RequestErrorListener? onError})`
With AppsFlyer SDK 7 initialization and start are separate. `initSdk(...)` only
initializes the SDK; a session (Launch) is sent only by `startSDK()`. </br>
**`startSDK()` must be called once per foreground cycle** — the native SDK resets its
"started" state on every background, so a single call at launch reports only the first
session. Call `startSDK()` from inside the `registerSessionReadyListener` callback (which
fires once per foreground cycle, after any launch deep link resolves) so every
foreground — including background→foreground — reports a session. Gate the first session
(consent, Customer User ID) by deferring the call inside the callback.

> **SDK 7 setter persistence:** setter values (`setCustomerUserId`, `setCurrencyCode`,
> `setAdditionalData`, `setConsentDataV2`, `anonymizeUser`, …) are runtime-only on both
> platforms — Android no longer persists them across process restarts. Re-apply your
> configuration setters on every cold start, **before** `startSDK()`, so they attach to
> the launch event. They persist across background→foreground within a running process,
> so re-applying once per cold start is enough.

`onSuccess`: An optional callback that is triggered after a successful start of the SDK.
`onError`: An optional callback that is fired in case of an error during SDK start, providing an error code and an error message.

```dart
    // SDK Options
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: "<DEV_KEY>",
        appId: "<APP_ID>",
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15);
    _appsflyerSdk = AppsflyerSdk(options);

    // Start on every session-ready signal (once per foreground cycle).
    _appsflyerSdk.registerSessionReadyListener((res) {
        _appsflyerSdk.startSDK(
            onSuccess: () {
                showMessage("AppsFlyer SDK started successfully.");
            },
            onError: (int errorCode, String errorMessage) {
                showMessage("Error starting AppsFlyer SDK: Code $errorCode - $errorMessage");
            },
        );
    });

    // Initialization of the AppsFlyer SDK (listeners must be registered first)
    _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: true);
```

Use the `onSuccess` callback to perform actions after a session (Launch) is
successfully reported, and the `onError` callback to handle start errors (see the
combined example above).

---

## iOS 14 & App Tracking Transparency

On iOS, to attribute installs that rely on the IDFA you must present the App Tracking
Transparency (ATT) prompt and give the user time to respond before the first session is
sent.

**1. Present the consent dialog.** Use the
[`app_tracking_transparency`](https://pub.dev/packages/app_tracking_transparency) package,
or add a native prompt in `AppDelegate`:

```objc
- (void)applicationDidBecomeActive:(nonnull UIApplication *)application {
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            // handle status
        }];
    }
}
```

**2. Add the usage-description key** to your `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

**3. Delay the first session** with `timeToWaitForATTUserAuthorization` so the SDK waits
(up to *x* seconds) for the user's ATT decision before sending the launch:

```dart
final AppsFlyerOptions options = AppsFlyerOptions(
    afDevKey: "<DEV_KEY>",
    appId: "<APP_ID>",
    showDebug: true,
    timeToWaitForATTUserAuthorization: 30);
```

For the full iOS 14 guide, see AppsFlyer's
[ATT support article](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-33-configuring-app-tracking-transparency-att-support).