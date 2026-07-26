# Adding   appsflyer-flutter-plugin to your project

## Installation

Open the terminal of your chosen IDE and run the following:

```
flutter pub add appsflyer_sdk
```

This will download the AppsFlyer flutter plugin to your project, you may observe the changes in your `pubspec.yaml` file.

---
## iOS: Swift Package Manager (SPM) support

Starting with v6.18.0, the plugin's **Core** integration supports Swift Package Manager on iOS, alongside continued full CocoaPods support. If your app has SPM enabled (the default on Flutter 3.44+, or via `flutter config --enable-swift-package-manager` on Flutter 3.24+), no extra setup is needed — Flutter's tooling picks up the plugin's `Package.swift` automatically.

**Purchase Connector is CocoaPods-only.** If your app uses the [Purchase Connector](PurchaseConnector.md), it must stay on CocoaPods for now — there is no SPM opt-in path for it yet, pending resolution of an upstream Flutter limitation ([flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182)). Apps that need both SPM (for Core) and Purchase Connector (via CocoaPods) can use both simultaneously; Flutter's tooling handles this automatically as long as your `Podfile` still exists.

---
## Huawei Referrer
Huawei Referrer is supported in SDK v6.14.0 and above.
Due to changes in the Huawei AppGallery store, previous versions of the AppsFlyer SDK are not able to fetch the referrer from the store. [Learn more](https://dev.appsflyer.com/hc/docs/install-android-sdk#huawei-install-referrer).
---

## <a id="strictMode">👨‍👩‍👧‍👦  Strict mode for Kids Apps

Starting from version **6.2.4-nullsafety.5**, the iOS SDK comes in two variants: **Strict** mode and **Regular** mode. 
Please read more: https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

***Change to Strict mode***

After you installed the AppsFlyer plugin:
1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder
2. Open `appsflyer_sdk.podspec`, add `/Strict` to the `s.ios.dependency` as follow:
`s.ios.dependency 'AppsFlyerFramework', '6.x.x'` to `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'`
and save.

3. Go to the `ios` folder of your current project and run `pod update`.

***Change to Regular mode***

After you installed the AppsFlyer plugin:
1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder:
2. Open `appsflyer_sdk.podspec` and remove `/Strict`:
change `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'` to `s.ios.dependency 'AppsFlyerFramework', '6.x.x'`
and save.

3. Go to the `ios` folder of your current project and run `pod update`.