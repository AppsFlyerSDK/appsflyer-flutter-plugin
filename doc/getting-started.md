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
2. Register the deep-link listener, if your app uses deep linking.
3. Initialize the native SDK.
4. Apply configuration that must be included in the first Launch.
5. Register the remaining native listeners your app needs, each with its callback.
6. Call `start()` from the session-ready callback.

`registerDeepLinkListener()` is the one listener that must be registered
**before** `init(...)`; the others are registered after. See
[Register the deep-link listener before init](#deep-link-listener-before-init).

The following sections explain each step.

## 1. Create the SDK instance

Use the shared `AppsFlyerSdk.instance`. SDK configuration is applied through
explicit methods instead of a configuration object.

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final AppsFlyerSdk appsflyerSdk = AppsFlyerSdk.instance;
```

## <a id="deep-link-listener-before-init"></a> 2. Register the deep-link listener

`Future<void> registerDeepLinkListener(OnDeepLinkReceived onDeepLink)`

If your app handles deep links, register this listener **before** `init(...)`:

```dart
await appsflyerSdk.registerDeepLinkListener((result) {
  print('Deep-link result: $result');
});
```

On Android, `init(...)` hands the launch intent to the native SDK, and that is
when the SDK decides whether to resolve a deferred deep link. The decision is
made once per install: with no listener registered at that moment, the deferred
resolution request is never sent — not even on a later launch. Registering
before `init(...)` is supported on both platforms and is also correct for direct
links.

Skip this step if your app does not use deep linking. For the full guide,
including the `DeepLinkResult` payload, see [Deep linking](deep-linking.md).

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

## 5. Register the remaining listeners

Each listener takes its callback as an argument, so registering the listener and
handling its event are the same step. Register these after `init(...)`, register
only the optional listeners your app uses, and register the session-ready
listener last:

```dart
// Optional: conversion data (GCD).
await appsflyerSdk.registerConversionListener(
  onSuccess: (data) {
    print('Conversion data: $data');
  },
  onFailure: (error) {
    print('Conversion data error: $error');
  },
);

// Required. Register last because the callback can be invoked immediately.
await appsflyerSdk.registerSessionReadyListener(() async {
  try {
    await appsflyerSdk.start(awaitResponse: true);
    print('AppsFlyer session reported.');
  } on AppsFlyerException catch (error) {
    print('AppsFlyer start error: $error');
  }
});
```

| Registration method | Event |
|---|---|
| `registerConversionListener(onSuccess:, onFailure:)` | Enables [GCD](https://dev.appsflyer.com/hc/docs/conversion-data) success and failure events. |
| `registerDeepLinkListener(onDeepLink)` | Enables [UDL](https://dev.appsflyer.com/hc/docs/unified-deep-linking-udl) results. Register it before `init(...)` — see [step 2](#deep-link-listener-before-init). |
| `registerSessionReadyListener(onReady)` | Enables one session-ready event per foreground cycle. |

The plugin keeps **one callback per event** and replaces it when you register
again, matching the native SDKs. There is no stream to subscribe to, so a single
native event can never reach two handlers in your app — for example, `start()`
cannot be issued twice for one session-ready event.

### Unregister and re-register explicitly

Registration is native state, and the plugin never infers that a listener has
gone stale — your app decides when delivery should stop and start again:

```dart
@override
void dispose() {
  // Stop native delivery when this part of the app no longer consumes it.
  appsflyerSdk.unregisterSessionReadyListener();
  appsflyerSdk.unregisterConversionListener();
  super.dispose();
}
```

| Unregister method | Availability |
|---|---|
| `unregisterConversionListener()` | Android only |
| `unregisterDeeplinkListener()` | Android only, and a soft unsubscribe — the native SDK keeps its listener, so events are dropped rather than never delivered |
| `unregisterSessionReadyListener()` | Android and iOS |

Where the unregister call reaches the native SDK it also drops the callback you
passed at registration. On iOS, `unregisterConversionListener()` and
`unregisterDeeplinkListener()` drop your callback and then throw
`AppsFlyerException`, because the iOS SDK has no matching native call — guard
them with `Platform.isAndroid` or catch the exception.

On Android the native listener also outlives the Flutter engine, which is
destroyed on its own schedule (a back press, or a Flutter screen leaving an
add-to-app host) while the process keeps running. Your Dart callbacks do not
survive that, so after a new engine attaches, call the `register*Listener()`
methods again (steps 2 and 5) — the same sequence as a cold start. Re-registering
is
cheap: it reconnects to the already configured native bridge instead of building
a new one.

<a id="multi-engine"></a>
## Add-to-app and multiple Flutter engines

The AppsFlyer **native SDK is process-scoped** — one `AppsFlyerLib` instance per
app process. The Flutter plugin mirrors that on the native side: one RPC handler,
one `af-events` delivery path, and one native listener slot per event type
(`registerConversionListener`, `registerDeepLinkListener`, and so on all replace
the previous registration).

Each `FlutterEngine` gets its own plugin instance and Dart isolate.
`AppsFlyerSdk.instance` is a singleton **within that isolate**, not across
engines.

### One live engine at a time (typical add-to-app)

When the user leaves a Flutter screen and the engine is destroyed, register your
listeners again after a new engine attaches — the same sequence as steps 2 and 5
above. Native configuration survives; re-registering reconnects your Dart callbacks
to the existing native bridge.

### Multiple engines alive at once (unsupported)

If two or more Flutter engines coexist in the same process — add-to-app with
overlapping routes, `FlutterEngineGroup` warm-up, or multi-scene hosts — **only
one engine receives native events**:

| Layer | Behavior |
|---|---|
| `af-events` delivery | The engine whose EventChannel subscription attached **most recently** wins. Older engines do not receive conversion, deep-link, or session-ready callbacks even if Dart listeners are still registered. |
| Native `register*Listener()` | The **last** registration from any engine overwrites the native SDK's single listener reference for that event type. |
| `init()` / `start()` | All engines share the same native SDK. Call `init()`, register listeners, and drive `start()` from **one primary engine** only. |

Do not integrate AppsFlyer from secondary Flutter modules. If your host app uses
add-to-app, pick one engine (usually the main Flutter entry point) for the full
startup sequence in this guide.

See also [API reference → Multi-engine hosts](api-reference.md#multi-engine-hosts).

<a id="start"></a>
<a id="startsdk"></a>
## 6. Start sessions

`Future<void> start({bool awaitResponse = false})`

`init(...)` and `registerSessionReadyListener(...)` do not report a session.
`start()` sends the session (Launch). Call it from the session-ready callback
registered in step 5.

The session-ready callback runs once per foreground cycle, after launch deep-link
processing finishes or times out. This includes the initial launch and every
background-to-foreground transition. Calling `start()` only once during app
setup reports the first session but misses later foreground sessions.

If the first session must wait for consent, a Customer User ID, ATT
authorization, or another app condition, complete that work inside the
session-ready callback before calling `start()`.

### Choose when the `Future` completes

- `start()` uses `awaitResponse: false` by default. Its `Future` completes when
  the native SDK accepts the fire-and-forget call; this does not confirm request
  delivery.
- `start(awaitResponse: true)` waits for the native request callback. Native
  errors and timeouts are reported as `AppsFlyerException`. A timeout does not
  cancel the native request, which may still succeed later.

<a id="conversion-data-start"></a>
### Conversion-data timing

`registerConversionListener(...)` only enables the callbacks. The conversion-data
request is sent after `start()` reports the Launch, and its result is delivered
to `onSuccess` or `onFailure`.

The `Future` returned by `start()` is not the conversion-data result. Always use
the conversion-data callbacks to receive GCD data.

Conversion data also provides an extended deferred deep-linking path for cases
where UDL does not return a deferred link, such as some SRN campaigns or legacy
links. If both listeners are enabled, handle a deferred link only once to avoid
routing the user twice.

### Complete startup example

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final AppsFlyerSdk appsflyerSdk = AppsFlyerSdk.instance;

Future<void> configureAppsFlyer() async {
  await appsflyerSdk.enableDebug(true); // Testing only.

  // Register before init() so Android can resolve a deferred deep link.
  await appsflyerSdk.registerDeepLinkListener((result) {
    print('Deep-link result: $result');
  });

  await appsflyerSdk.init(
    devKey: '<DEV_KEY>',
    appId: '<APP_ID>',
  );

  // Apply values that must be included in the first Launch.
  await appsflyerSdk.setCustomerUserId('<CUSTOMER_USER_ID>');

  await appsflyerSdk.registerConversionListener(
    onSuccess: (data) {
      print('Conversion data: $data');
    },
    onFailure: (error) {
      print('Conversion data error: $error');
    },
  );

  // Register last. The callback can run immediately and trigger start().
  await appsflyerSdk.registerSessionReadyListener(() async {
    try {
      await appsflyerSdk.start(awaitResponse: true);
      print('AppsFlyer session reported.');
    } on AppsFlyerException catch (error) {
      print('AppsFlyer start error: $error');
    }
  });
}
```

---

## iOS 14 & App Tracking Transparency

On iOS, to attribute installs that rely on the IDFA you must present the App Tracking
Transparency (ATT) prompt and give the user time to respond before the first session is
sent.

**1. Add ATT handling.** The recommended Flutter integration is the
[`app_tracking_transparency`](https://pub.dev/packages/app_tracking_transparency)
package. Request authorization from the session-ready callback shown in step 5 so
the same Dart flow works with both the legacy application lifecycle and the
UIScene lifecycle.

**2. Add the usage-description key** to your `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

**3. Delay the first session** until the ATT request completes. The plugin does
not expose `waitForATTUserAuthorization`. In step 5, register the following
session-ready callback instead of the basic one:

```dart
var attHandled = false;

await appsflyerSdk.registerSessionReadyListener(() async {
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

As in the standard flow, call `registerSessionReadyListener(...)` only after
`init(...)` and any configuration that must be included in the first Launch.

For the full iOS 14 guide, see AppsFlyer's
[ATT support article](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-33-configuring-app-tracking-transparency-att-support).
