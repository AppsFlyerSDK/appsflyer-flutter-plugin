# Installation

Add the plugin to your app and configure the native (iOS/Android) dependencies. This is
step 1 — continue with [Getting started](getting-started.md) once the package is added.

## Add the package

Open the terminal of your chosen IDE and run the following:

```
flutter pub add appsflyer_sdk
```

This will download the AppsFlyer flutter plugin to your project, you may observe the changes in your `pubspec.yaml` file.

---
## iOS: Swift Package Manager (SPM) support

Starting with v6.18.0, the plugin's **Core** integration supports Swift Package Manager on iOS, alongside continued full CocoaPods support. If your app has SPM enabled (the default on Flutter 3.44+, or via `flutter config --enable-swift-package-manager` on Flutter 3.24+), no extra setup is needed — Flutter's tooling picks up the plugin's `Package.swift` automatically.

**If you use Purchase Connector, do not enable SPM for this plugin.** [Purchase Connector](purchase-connector.md) requires CocoaPods for the entire plugin (Core included) — it cannot currently be combined with SPM, pending resolution of an upstream Flutter limitation ([flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182)). SPM is recommended only for apps that don't use Purchase Connector at all; if you don't, keep CocoaPods and the `$AppsFlyerPurchaseConnector` Podfile flag as documented in [purchase-connector.md](purchase-connector.md).

---
## Huawei Referrer
Huawei Referrer is supported in SDK v6.14.0 and above.
Due to changes in the Huawei AppGallery store, previous versions of the AppsFlyer SDK are not able to fetch the referrer from the store. [Learn more](https://dev.appsflyer.com/hc/docs/install-android-sdk#huawei-install-referrer).
---

## <a id="strictMode">👨‍👩‍👧‍👦  Strict mode for Kids Apps

The iOS SDK ships in two variants: **Strict** mode and **Regular** mode.
Please read more: https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

> **⚠️ SDK 7 note:** In plugin `7.x` the iOS **Core** integration no longer depends on
> `AppsFlyerFramework` directly — it depends on the RPC bridge pod **`AppsFlyerRPC`**
> (pinned in `appsflyer_sdk.podspec`, see the `Core` subspec). The old
> `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'` edit no longer applies.
> Before releasing a Kids app on plugin 7.x, **verify the correct Strict variant of the
> `AppsFlyerRPC` pod** with AppsFlyer support / the current
> [AppsFlyerRPC CocoaPods spec](https://cocoapods.org/pods/AppsFlyerRPC), then pin that
> variant in the `Core` subspec of `appsflyer_sdk.podspec`.

To locate the plugin's podspec:
1. Go to the `$HOME/.pub-cache/hosted/pub.dev/appsflyer_sdk-<CURRENT VERSION>/ios` folder.
2. Open `appsflyer_sdk.podspec` and edit the `AppsFlyerRPC` dependency in the `Core` subspec.
3. Go to the `ios` folder of your current project and run `pod update`.
