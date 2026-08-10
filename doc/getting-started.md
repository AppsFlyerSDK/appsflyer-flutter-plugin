# 🚀 Getting started

This guide takes you through the required setup: creating the SDK instance, initializing
it, and starting sessions with the SDK 7 session-ready model.

> **Audience:** every app integrating the plugin. Complete [Installation](installation-guide.md) first.

## Prerequisites

- The plugin added to your app — see [Installation](installation-guide.md).
- Your AppsFlyer **Dev Key** (from the AppsFlyer dashboard) and, for iOS, your **App ID**.
- **iOS:** minimum deployment target `13.0`. For ATT/IDFA, see [iOS 14 & App Tracking Transparency](#ios-14--app-tracking-transparency) below.
- **Android:** review the `AD_ID` permission note in the [README](../README.md#ad_id-permission-for-android).

## Startup sequence

Set up the SDK once on every cold start, in this order:

1. Get the shared SDK instance.
2. Subscribe to the Dart streams your app needs.
3. Initialize the native SDK.
4. Apply configuration that must be included in the first Launch.
5. Register the corresponding native listeners.
6. Call `start()` whenever `onSessionReady` emits.

The following sections explain each step.

## 1. Create the SDK instance

Use the shared `AppsFlyerSdk.instance`. SDK configuration is applied through
explicit methods instead of a configuration object.

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final AppsFlyerSdk appsflyerSdk = AppsFlyerSdk.instance;
```

## 2. Subscribe to SDK events

Subscribe to each Dart stream before registering its native listener. Creating
a stream subscription does not initialize the SDK or send a request.

`onSessionReady` is required for session reporting. The conversion-data and
deep-link streams are optional:

```dart
// Optional: conversion data (GCD).
appsflyerSdk.onConversionDataSuccess.listen((data) {
  print('Conversion data: $data');
});
appsflyerSdk.onConversionDataFailure.listen((error) {
  print('Conversion data error: $error');
});

// Optional: Unified Deep Linking (UDL).
appsflyerSdk.onDeepLinkReceived.listen((result) {
  print('Deep-link result: $result');
});

// Required: start a session on every foreground cycle.
appsflyerSdk.onSessionReady.listen((_) async {
  try {
    await appsflyerSdk.start(awaitResponse: true);
    print('AppsFlyer session reported.');
  } on AppsFlyerException catch (error) {
    print('AppsFlyer start error: $error');
  }
});
```

The `onSessionReady` callback is declared at this point, but it cannot run until
`registerSessionReadyListener()` is called in step 5.

## 3. Initialize the SDK

`Future<void> init({required String devKey, String? appId})`

Call `init(...)` once during app setup. It initializes the native SDK but does
not send a session (Launch) or enable optional listeners.

```dart
// Optional. Enable only while testing.
await appsflyerSdk.enableDebug(true);

await appsflyerSdk.init(
  devKey: '<DEV_KEY>',
  appId: '<APP_ID>',
);
```

| Parameter | Required | Description |
|---|---|---|
| `devKey` | Android and iOS | Your application's [Dev Key](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#retrieving-the-dev-key). |
| `appId` | iOS only | Your application's [Apple App ID](https://support.appsflyer.com/hc/en-us/articles/207377436-Adding-a-new-app#available-in-the-app-store-google-play-store-windows-phone-store). It is optional and is not sent to the native SDK on Android. |

`enableDebug(...)` can be called before `init(...)`. Disable debug logging
before releasing the app to production.

## 4. Configure the first Launch

After `init(...)`, apply any runtime configuration that must be included in the
first Launch. Do this before registering the session-ready listener because the
listener can emit immediately and trigger `start()`.

For example:

```dart
await appsflyerSdk.setCustomerUserId('<CUSTOMER_USER_ID>');
```

In SDK 7, values set with `setCustomerUserId`, `setCurrencyCode`,
`setAdditionalData`, `setConsentData`, and `anonymizeUser` are kept in memory
only. Re-apply the values your app needs on every cold start. They remain
available when the app moves between the background and foreground in the same
process.

Other methods can have different timing and persistence requirements. For
example, `setInstallId()` has platform-specific requirements. Check the
[API reference](api-reference.md#setInstallId) for the method you use.

Other common optional settings include:

| Method | Description |
|---|---|
| `setAppInviteOneLink(String oneLinkId)` | Sets the [OneLink template ID](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-invite-attribution#parameters) used to generate user-invite links. |
| `setDisableAdvertisingIdentifiers(bool disable)` | Opts out of collecting advertising identifiers, including OAID, AAID, GAID, and IDFA. |
| `setDisableCollectASA(bool disable)` | Opts out of Apple Search Ads attribution collection. This method is available only on iOS. |

## 5. Register native listeners

Register listeners after `init(...)`. Only register the optional listeners your
app uses, and register the session-ready listener last:

```dart
// Optional. The Dart streams were subscribed to in step 2.
await appsflyerSdk.registerConversionListener();
await appsflyerSdk.registerDeepLinkListener();

// Required. Register last because this can emit onSessionReady immediately.
await appsflyerSdk.registerSessionReadyListener();
```

| Registration method | Event |
|---|---|
| `registerConversionListener()` | Enables [GCD](https://dev.appsflyer.com/hc/docs/conversion-data) success and failure events. |
| `registerDeepLinkListener()` | Enables [UDL](https://dev.appsflyer.com/hc/docs/unified-deep-linking-udl) results. |
| `registerSessionReadyListener()` | Enables one `onSessionReady` event per foreground cycle. |

<a id="start"></a>
<a id="startsdk"></a>
## 6. Start sessions

`Future<void> start({bool awaitResponse = false})`

`init(...)` and `registerSessionReadyListener()` do not report a session.
`start()` sends the session (Launch). Call it from the `onSessionReady` handler
created in step 2.

`onSessionReady` emits once per foreground cycle, after launch deep-link
processing finishes or times out. This includes the initial launch and every
background-to-foreground transition. Calling `start()` only once during app
setup reports the first session but misses later foreground sessions.

If the first session must wait for consent, a Customer User ID, ATT
authorization, or another app condition, complete that work in the
`onSessionReady` handler before calling `start()`.

### Choose when the `Future` completes

- `start()` uses `awaitResponse: false` by default. Its `Future` completes when
  the native SDK accepts the fire-and-forget call; this does not confirm request
  delivery.
- `start(awaitResponse: true)` waits for the native request callback. Native
  errors and timeouts are reported as `AppsFlyerException`. A timeout does not
  cancel the native request, which may still succeed later.

<a id="conversion-data-start"></a>
### Conversion-data timing

`registerConversionListener()` only enables the callbacks. The conversion-data
request is sent after `start()` reports the Launch, and its result is delivered
through `onConversionDataSuccess` or `onConversionDataFailure`.

The `Future` returned by `start()` is not the conversion-data result. Always use
the conversion-data streams to receive GCD data.

Conversion data also provides an extended deferred deep-linking path for cases
where UDL does not return a deferred link, such as some SRN campaigns or legacy
links. If both listeners are enabled, handle a deferred link only once to avoid
routing the user twice.

### Complete startup example

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final AppsFlyerSdk appsflyerSdk = AppsFlyerSdk.instance;

Future<void> configureAppsFlyer() async {
  // Subscribe before registering native listeners.
  appsflyerSdk.onConversionDataSuccess.listen((data) {
    print('Conversion data: $data');
  });
  appsflyerSdk.onConversionDataFailure.listen((error) {
    print('Conversion data error: $error');
  });
  appsflyerSdk.onDeepLinkReceived.listen((result) {
    print('Deep-link result: $result');
  });
  appsflyerSdk.onSessionReady.listen((_) async {
    try {
      await appsflyerSdk.start(awaitResponse: true);
      print('AppsFlyer session reported.');
    } on AppsFlyerException catch (error) {
      print('AppsFlyer start error: $error');
    }
  });

  await appsflyerSdk.enableDebug(true); // Testing only.
  await appsflyerSdk.init(
    devKey: '<DEV_KEY>',
    appId: '<APP_ID>',
  );

  // Apply values that must be included in the first Launch.
  await appsflyerSdk.setCustomerUserId('<CUSTOMER_USER_ID>');

  // Register optional listeners first.
  await appsflyerSdk.registerConversionListener();
  await appsflyerSdk.registerDeepLinkListener();

  // Register last. This can emit onSessionReady and trigger start().
  await appsflyerSdk.registerSessionReadyListener();
}
```

---

## iOS 14 & App Tracking Transparency

On iOS, to attribute installs that rely on the IDFA you must present the App Tracking
Transparency (ATT) prompt and give the user time to respond before the first session is
sent.

**1. Add ATT handling.** The recommended Flutter integration is the
[`app_tracking_transparency`](https://pub.dev/packages/app_tracking_transparency)
package. Request authorization from the `onSessionReady` handler shown in step
3 so the same Dart flow works with both the legacy application lifecycle and
the UIScene lifecycle.

**2. Add the usage-description key** to your `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

**3. Delay the first session** until the ATT request completes. The plugin does
not expose `waitForATTUserAuthorization`. In step 2, use the following
`onSessionReady` handler instead of the basic handler, then continue with steps
3–5:

```dart
var attHandled = false;

appsflyerSdk.onSessionReady.listen((_) async {
  if (!attHandled) {
    await AppTrackingTransparency.requestTrackingAuthorization();
    attHandled = true;
  }
  await appsflyerSdk.start();
});
```

> **Native lifecycle note:** Flutter 3.41 and later use UIScene by default for
> iOS apps. If you implement the ATT request in native code, a UIScene app must
> request it from `sceneDidBecomeActive` in its `SceneDelegate`. Do not rely only
> on `applicationDidBecomeActive` in `AppDelegate`, because that callback may not
> receive UI lifecycle events after UIScene migration. Use the AppDelegate
> callback only for a legacy app that has not adopted UIScene. See Flutter's
> [UIScene adoption guide](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

As in the standard flow, call `registerSessionReadyListener()` only after
`init(...)` and any configuration that must be included in the first Launch.

For the full iOS 14 guide, see AppsFlyer's
[ATT support article](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-33-configuring-app-tracking-transparency-att-support).
