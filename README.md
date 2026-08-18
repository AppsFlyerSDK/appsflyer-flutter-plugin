# appsflyer-flutter-plugin

![AppsFlyer Logo](https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png)

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk)
![Coverage](https://raw.githubusercontent.com/AppsFlyerSDK/appsflyer-flutter-plugin/master/coverage_badge.svg)

Flutter plugin for the AppsFlyer mobile attribution and analytics SDK on **Android**
and **iOS**.

🛠 In order for us to provide optimal support, please contact AppsFlyer support through the Customer Assistant Chatbot for assistance with troubleshooting issues or product guidance. </br>
To do so, please follow [this article](https://support.appsflyer.com/hc/en-us/articles/23583984402193-Using-the-Customer-Assistant-Chatbot)


## SDK Versions

This plugin release bundles:

- Android AppsFlyer SDK **v7.0.1**
- iOS AppsFlyer SDK **v7.0.1**

### Purchase Connector versions

When Purchase Connector is enabled in your app:

- Android **2.2.0**
- iOS **7.0.1**

## ❗❗ Breaking changes when updating to v7.x.x ❗❗

Version `7.0.1` targets AppsFlyer SDK **7.0.1** on Android and iOS. The public
Flutter API changed in this major release.

- **Minimum supported versions: Flutter `3.24.0`, Dart `3.5.0` (and earlier than
  `4.0.0`), Android API 21, and iOS 13.0.**

Use `AppsFlyerSdk.instance`, call `init(devKey:, appId:)` (`appId` is required
on iOS and optional on Android), register the listeners you need with their
callbacks, and call `start()` from the session-ready callback:

```dart
final appsflyerSdk = AppsFlyerSdk.instance;

// If your app handles deep links, register before init(). Android decides once
// per install, while init() processes the launch intent, whether to request the
// deferred deep link — registering later skips it for that install permanently.
await appsflyerSdk.registerDeepLinkListener((result) {
  print('Deep link: ${result.deepLink?.deepLinkValue}');
});

await appsflyerSdk.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);
await appsflyerSdk.registerSessionReadyListener(() async {
  await appsflyerSdk.start();
});
```

All removed APIs, renamed APIs, lifecycle changes, and upgrade instructions are
documented in [doc/migration-guide.md](doc/migration-guide.md).

## AD_ID permission for Android

In v6.8.0 of the AppsFlyer SDK, we added the normal permission `com.google.android.gms.permission.AD_ID` to the SDK's AndroidManifest,
to allow the SDK to collect the Android Advertising ID on apps targeting API 33.
If your app is targeting children, you need to revoke this permission to comply with Google's Data policy.
You can read more about it in the [Android SDK installation guide](https://dev.appsflyer.com/hc/docs/install-android-sdk#the-ad_id-permission).

## 📖 Guides

- [Documentation index](doc/README.md)
- [Migrating from v6 to v7](doc/migration-guide.md)
- [Adding the SDK to your project](doc/installation-guide.md)
- [Getting started (init & session)](doc/getting-started.md)
- [In-app events & ad revenue](doc/in-app-events.md)
- [Deep linking](doc/deep-linking.md)
- [Advanced features](doc/advanced-features.md)
- [Consent & DMA compliance](doc/consent-dma.md)
- [Testing & troubleshooting](doc/testing-and-troubleshooting.md)
- [Purchase Connector](doc/purchase-connector.md)
- [API reference](doc/api-reference.md)
- [Sample App](example/)
