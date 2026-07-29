# Testing & troubleshooting

More info about testing the SDK for marketers [here](https://support.appsflyer.com/hc/en-us/articles/360001559405-Test-mobile-SDK-integration-with-the-app#introduction).

- [Testing for iOS](#iOS)
- [Testing for Android](#Android)
- [Troubleshooting](#troubleshooting)

Before testing the SDK, you need to enable the debug mode so the SDK will produce the full logs.
To enable it, set the appsFlyer options object with `showDebug` as `true`, and then initialize the SDK:

```dart
AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
        afDevKey: afDevKey,
        appId: appId,
        showDebug: true);

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnDeepLinkingCallback: false
);
```

---

## <a id="iOS"> Testing for iOS

Open your iOS project with XCode (`appName.xcworkspace`) and run it. In the logs section or in the console app, you will see logs related to AppsFlyer start with `[AppsFlyerSDK]`.<br>
Search for the launch event that looks like this:

```
<~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~~+~>
<~+~   SEND Start:   https://launches.appsflyer.com/api/v7.0/iosevent?app_id=7xXxXxX1&buildnumber=7.0.1
<~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~~+~>
{ launch event payload } // Just an example of a JSON. you will see the full payload
```
and also:
```
Result: {
    data = {length = 64, bytes = 0x7b226f6c 5f696422 3a224476 5769222c ... 696e6b2e 6d65227d };
    dataStr = "{\"oxXxXxd\":\"DXxXxi\",\"oXxXer\":ss,\"olXxXxain\":\"xXxXxXx\"}";
    retries = 2;
    statusCode = 200; // ~~> success!
    taskIdentifier = 4;
}
```

For more iOS integration tests, see [Here](https://dev.appsflyer.com/hc/docs/testing-ios)

---

## <a id="Android"> Testing for Android

Open your Android project with Android Studio (`android` folder) and run it. In the logcat, you will see logs related to AppsFlyer start with `I/AppsFlyer_x.x.x`.<br>
Search for the launch event that looks like this:

```
I/AppsFlyer_7.0.1: url: https://launches.appsflyer.com/api/v7.0/androidevent?app_id=com.aXxXxt.rxXxXxt&buildnumber=7.0.1
I/AppsFlyer_7.0.1: data: { launch event payload } // Just an example of a JSON. you will see the full payload
```
and also:
```
I/AppsFlyer_7.0.1: response code: 200 // ~~> success!
```

For more Android integration tests, see [Here](https://dev.appsflyer.com/hc/docs/testing-android)

---

## <a id="troubleshooting"> Troubleshooting

### No launch/session is sent ("SDK session not started")

In SDK 7, `initSdk()` only initializes the SDK — it does **not** send a session.
`startSDK()` must be called **once per foreground cycle**. Register a session-ready
listener and call `startSDK()` from inside it so every foreground (including
background→foreground) reports a session:

```dart
appsflyerSdk.registerSessionReadyListener((res) => appsflyerSdk.startSDK());
appsflyerSdk.initSdk(registerConversionDataCallback: true, registerOnDeepLinkingCallback: true);
```

See [Getting started → startSdk](getting-started.md#startsdk).

### Setter values are lost after a cold start

SDK 7 setters (`setCustomerUserId`, `setCurrencyCode`, `setConsentDataV2`, …) are
runtime-only. Re-apply them on every cold start **before** `startSDK()` — see the
setter-persistence note in [Getting started](getting-started.md#startsdk).

### Deep links stop working on Flutter 3.27+

Flutter 3.27 enables its built-in deep linking by default, which intercepts AppsFlyer
OneLinks. Disable it via `flutter_deeplinking_enabled=false` (Android) and
`FlutterDeepLinkingEnabled=false` (iOS) — see the breaking-change note at the top of
[Deep linking](deep-linking.md).

### `MissingPluginException` when calling a Purchase Connector API

Purchase Connector has no Swift Package Manager path. If you enabled SPM, Purchase
Connector calls fail silently with `MissingPluginException`. Use CocoaPods for the whole
plugin — see [Purchase Connector](purchase-connector.md).

### iOS installs not attributed to IDFA

The ATT prompt must be presented and `timeToWaitForATTUserAuthorization` set so the SDK
waits for the user's decision before the first session. See
[Getting started → iOS 14 & ATT](getting-started.md#ios-14--app-tracking-transparency).