# Deep linking

> **Audience:** apps routing users to in-app content via OneLink. Complete
> [Getting started](getting-started.md) first. API details:
> [`registerDeepLinkListener`](api-reference.md#registerDeepLinkListener).
> Push deep links:
> [`addPushNotificationDeepLinkPath`](api-reference.md#addPushNotificationDeepLinkPath),
> Android [`sendPushNotificationData`](api-reference.md#sendPushNotificationData),
> iOS [`handlePushNotification`](api-reference.md#handlePushNotification).

> ⚠️ **IMPORTANT: Flutter 3.27+ breaking change**
>
> From Flutter 3.27, built-in Flutter deep linking defaults to **enabled** and
> can conflict with AppsFlyer. **Disable it** when you use this plugin:
>
> **Android** — inside the main `<activity>` in `AndroidManifest.xml`:
>
> ```xml
> <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
> ```
>
> **iOS** — in `Info.plist`:
>
> ```xml
> <key>FlutterDeepLinkingEnabled</key>
> <false/>
> ```
>
> See the [Flutter breaking change](https://docs.flutter.dev/release/breaking-changes/deep-links-flag-change).

## Overview

A **deep link** routes a user to a specific place in your app. If the app is not
installed, **deferred deep linking** routes the user to the store first and
delivers the in-app destination after install.

The plugin uses **Unified Deep Linking (UDL)** for both direct and deferred deep
links. Results are delivered to the callback you pass to
`registerDeepLinkListener()`.

Read the [OneLink™ Deep Linking Guide](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#Intro) for dashboard and link configuration.

![Deep linking flow](https://massets.appsflyer.com/wp-content/uploads/2018/03/21101417/app-installed-Recovered.png)

---

## <a id="setup"></a> Platform setup

Configure native link handling before you wire up Dart listeners. The plugin
forwards incoming URLs and Universal Links to the AppsFlyer SDK; your app must
declare the schemes and domains the OS should open.

### <a id="android-deeplink"></a> Android

#### <a id="uri-scheme"></a> URI scheme

Add an intent filter on the activity that should receive the link:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="afshopapp"
        android:host="mainactivity" />
</intent-filter>
```

#### <a id="app-links"></a> App Links

For App Links, see AppsFlyer's
[Android App Links guide](https://support.appsflyer.com/hc/en-us/articles/115005314223-Deep-Linking-Users-with-Android-App-Links#what-are-android-app-links).

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="yourcompany.onelink.me"
        android:pathPrefix="/your-path-prefix" />
</intent-filter>
```

#### <a id="on-new-intent"></a> Warm starts (`onNewIntent`)

The plugin updates the attached activity with each new intent. The Android SDK
resolves warm-start deep links through its activity-lifecycle hook after
`registerDeepLinkListener()` has registered the native listener. No custom
`MainActivity.onNewIntent` implementation is required.

### <a id="ios-deeplink"></a> iOS

#### <a id="universal-links"></a> Universal Links

See AppsFlyer's
[Universal Links setup](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#setups-universal-links).

1. Configure your OneLink sub-domain in the AppsFlyer dashboard (AppsFlyer hosts the `apple-app-site-association` file).
2. Enable **Associated Domains** and add approved domains to `Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>com.apple.developer.associated-domains</key>
        <array>
            <string>applinks:test.onelink.me</string>
        </array>
    </dict>
</plist>
```

The plugin forwards Universal Link callbacks from `UIApplicationDelegate` and,
when available, from `UISceneDelegate` (Flutter 3.41+). No AppsFlyer-specific
`AppDelegate` forwarding code is required.

#### <a id="ios-uri-scheme"></a> URI scheme

Add your URI scheme under Xcode **General → URL Types**.

The plugin forwards URL-scheme callbacks the same way. See AppsFlyer's
[URI scheme guide](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-deep-linking-guide#setups-uri-scheme-for-ios-8-and-below).

---

## Flutter integration

1. Complete [Getting started](getting-started.md) — `init()`, listener
   registration, and `start()` from the session-ready callback.
2. Call `registerDeepLinkListener(onDeepLinking:)` **before** `init()`, passing the
   callback that handles the result.

> ⚠️ **Register before `init()`.** On Android, `init()` hands the launch intent
> to the native SDK, which then decides — once per install — whether to send the
> deferred deep-link resolution request. With no listener registered at that
> point, that request is never sent, and the decision is persisted: later
> launches do not retry it. Registering after `init()` therefore breaks deferred
> deep linking on Android even though direct links keep working. When testing a
> fix, reinstall the app (or clear its data); the skipped state survives a plain
> app restart.

### <a id="unified-deeplinking"></a> Unified Deep Linking (recommended)

UDL handles **direct** links (app already open or cold start) and **deferred**
links (after install) through the same `registerDeepLinkListener` callback.

**Flow:**

1. User clicks a OneLink short URL.
2. Android App Links / iOS Universal Links (or the deferred install path) open the app.
3. The native SDK resolves the link and delivers a result to the plugin.
4. Your callback receives a `DeepLinkResult` with `deep_link_value` and other available fields.

> 📘 **UDL privacy (new users):** UDL returns only deferred deep-linking
> parameters (`deep_link_value`, `deep_link_sub1`–`deep_link_sub10`). Other
> fields such as `media_source`, `campaign`, and `af_sub1`–`af_sub5` may be
> `null` for new users.

**Considerations:**

- Uses the AppsFlyer SDK 7 Unified Deep Linking implementation.
- `af_dp` is not returned in the API response.

Platform references: [Android UDL](https://dev.appsflyer.com/docs/android-unified-deep-linking), [iOS UDL](https://dev.appsflyer.com/docs/ios-unified-deep-linking).

```dart
await appsflyerSdk.registerDeepLinkListener(
    onDeepLinking: (DeepLinkResult result) {
  switch (result.status) {
    case DeepLinkStatus.found:
      print(result.deepLink);
      print('deep link value: ${result.deepLink?.deepLinkValue}');
      break;
    case DeepLinkStatus.notFound:
      print('deep link not found');
      break;
    case DeepLinkStatus.error:
      print('deep link error: ${result.error}');
      break;
    case DeepLinkStatus.unknown:
      print('unknown deep link status');
      break;
  }
});
```

`DeepLinkResult` exposes a `DeepLink` model:

```dart
class DeepLink {
  final Map<String, dynamic> _clickEvent;

  const DeepLink(this._clickEvent);

  Map<String, dynamic> get clickEvent => _clickEvent;

  String? getStringValue(String key) => _clickEvent[key]?.toString();

  String? get deepLinkValue => getStringValue('deep_link_value');
  String? get matchType => getStringValue('match_type');
  String? get clickHttpReferrer => getStringValue('click_http_referrer');
  String? get mediaSource => getStringValue('media_source');
  String? get campaign => getStringValue('campaign');
  String? get campaignId => getStringValue('campaign_id');
  String? get afSub1 => getStringValue('af_sub1');
  String? get afSub2 => getStringValue('af_sub2');
  String? get afSub3 => getStringValue('af_sub3');
  String? get afSub4 => getStringValue('af_sub4');
  String? get afSub5 => getStringValue('af_sub5');

  bool? get isDeferred {
    final value = _clickEvent['is_deferred'];
    if (value is bool) {
      return value;
    }
    if (value?.toString().toLowerCase() == 'true') {
      return true;
    }
    if (value?.toString().toLowerCase() == 'false') {
      return false;
    }
    return null;
  }
  @override
  String toString() {
    return 'DeepLink: ${jsonEncode(_clickEvent)}';
  }
}
```

> **Platform behavior:** `DeepLink.isDeferred` is populated on both Android and
> iOS — `true` when the link was resolved by deferred deep linking on the first
> launch after install, `false` for a direct click into an installed app. It is
> `null` only if the click event carries no `is_deferred` key, so treat `null`
> as "unknown" rather than as "direct".

### <a id="handle-deeplinking"></a> Direct deep linking

When the app is already installed, a URL scheme, App Link, or Universal Link
opens the app and the resolved destination is delivered to the
`registerDeepLinkListener` callback.
Use the UDL listener above — no separate direct-link API is required.

### <a id="deferred-deep-linking"></a> Deferred deep linking

When the app is not installed, the link first sends the user to the app store.
After installation and the first app open, the resolved destination is
delivered to the `registerDeepLinkListener` callback. Use the same UDL listener described
above; no separate deferred-link listener is required.

This is the path that depends on registration order: register the listener
before `init()`, otherwise Android never sends the resolution request for that
install.

---

## <a id="Deep-Linking"></a> Quick reference

| Topic | Section |
| --- | --- |
| Disable Flutter 3.27+ default deep linking | Top of this page |
| Android / iOS manifest and entitlements | [Platform setup](#setup) |
| UDL listener and `DeepLink` model | [Unified Deep Linking](#unified-deeplinking) |
| Direct deep linking | [Direct deep linking](#handle-deeplinking) |
| Deferred deep linking | [Deferred deep linking](#deferred-deep-linking) |
