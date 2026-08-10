# Testing & troubleshooting

More info about testing the SDK for marketers [here](https://support.appsflyer.com/hc/en-us/articles/360001559405-Test-mobile-SDK-integration-with-the-app#introduction).

- [Testing for iOS](#iOS)
- [Testing for Android](#Android)
- [Troubleshooting](#troubleshooting)

Before testing the SDK, enable debug mode so the SDK produces full logs.
Call `enableDebug(true)` before `init()` and `start()`:

```dart
final appsflyerSdk = AppsFlyerSdk.instance;
await appsflyerSdk.enableDebug(true);
await appsflyerSdk.init(
  devKey: afDevKey,
  appId: appId,
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

In SDK 7, `init()` only initializes the SDK — it does **not** send a session.
`start()` must be called **once per foreground cycle**. Subscribe to
`onSessionReady`, register the native session-ready listener, and call `start()`
from the stream so every foreground (including
background→foreground) reports a session:

```dart
final appsflyerSdk = AppsFlyerSdk.instance;

appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});

await appsflyerSdk.init(
  devKey: afDevKey,
  appId: appId,
);
await appsflyerSdk.registerSessionReadyListener();
```

See [Getting started → start](getting-started.md#start).

### Setter values are lost after a cold start

SDK 7 setters (`setCustomerUserId`, `setCurrencyCode`, `setConsentData`, …) are
runtime-only. Re-apply them on every cold start **before** `start()` — see the
setter-persistence note in [Getting started](getting-started.md#start).

### Deep links stop working on Flutter 3.27+

Flutter 3.27 enables its built-in deep linking by default, which intercepts AppsFlyer
OneLinks. Disable it via `flutter_deeplinking_enabled=false` (Android) and
`FlutterDeepLinkingEnabled=false` (iOS) — see the breaking-change note at the top of
[Deep linking](deep-linking.md).

### `MissingPluginException` when calling a Purchase Connector API

Purchase Connector has no Swift Package Manager path. If you enabled SPM, calling
any Purchase Connector API throws `MissingPluginException`. Use CocoaPods for the
whole plugin — see [Purchase Connector](purchase-connector.md).

### iOS installs not attributed to IDFA

The ATT prompt must be presented and completed before the app allows the first
`start()` call. The Flutter plugin does not provide an ATT-wait API. See
[Getting started → iOS 14 & ATT](getting-started.md#ios-14--app-tracking-transparency).
