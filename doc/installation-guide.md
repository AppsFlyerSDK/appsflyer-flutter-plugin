# Installation

Add the plugin to your app and configure the native (iOS/Android) dependencies. This is
step 1 — continue with [Getting started](getting-started.md) once the package is added.

## Add the package

Open the terminal of your chosen IDE and run the following:

```
flutter pub add appsflyer_sdk
```

This will download the AppsFlyer flutter plugin to your project, you may observe the changes in your `pubspec.yaml` file.

The plugin requires:

- Flutter `3.35.0` or later;
- Dart `3.9.0` or later;
- Android API 21 or later;
- iOS 13.0 or later.

On Android the plugin also requires the toolchain the AppsFlyer Android SDK is
built with. Flutter `3.35` templates all of these, so a project created or
updated with `flutter create` on `3.35` already satisfies them:

| Requirement | Minimum |
|---|---|
| Kotlin Gradle Plugin | `2.0.21` |
| Android Gradle Plugin | `8.9.1` |
| Gradle | `8.11.1` |
| JDK | `17` |

The Kotlin Gradle Plugin version is declared by **your** project, in
`android/settings.gradle`, and upgrading Flutter does not change it — a project
generated on an older Flutter keeps its original Kotlin version after the
upgrade. If it is below `2.0.21`, the build fails at configuration time with a
message naming the version found and the file to edit.

---
## iOS: Swift Package Manager (SPM) support

Starting with v6.18.0, the plugin's **Core** integration supports Swift Package Manager on iOS, alongside continued full CocoaPods support. If your app has SPM enabled (the default on Flutter 3.44+, or via `flutter config --enable-swift-package-manager` on earlier versions), no extra setup is needed — Flutter's tooling picks up the plugin's `Package.swift` automatically.

**If you use Purchase Connector, do not enable SPM for this plugin.** [Purchase Connector](purchase-connector.md) requires CocoaPods for the entire plugin (Core included) — it cannot currently be combined with SPM, pending resolution of an upstream Flutter limitation ([flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182)). Apps that do not use Purchase Connector can use SPM. Apps that use Purchase Connector must keep CocoaPods and set the `$AppsFlyerPurchaseConnector` Podfile flag as documented in [purchase-connector.md](purchase-connector.md).

---
## Android: Google Play Install Referrer (SDK 7)

Plugin `7.x` uses AppsFlyer Android SDK 7, which collects Play Install Referrer via
Google's Install Referrer library — **not** legacy `INSTALL_REFERRER` broadcast receivers.

The plugin already declares the required dependency and includes it transitively
in the application runtime:

```gradle
implementation 'com.android.installreferrer:installreferrer:2.2'
```

No app-level Gradle change is required for AppsFlyer. Add the dependency to your
app module only if your application code imports and uses the Install Referrer
API directly.

For Samsung Galaxy Store, Xiaomi GetApps, or Huawei AppGallery, see
[Advanced features — Alternative stores](advanced-features.md#alternative-stores-samsung-xiaomi-huawei).

Upgrade-specific removal of legacy receiver declarations is documented in
[doc/migration-guide.md](migration-guide.md).

---

## <a id="strictMode">👨‍👩‍👧‍👦  Strict mode for Kids Apps

The iOS SDK ships in two variants: **Strict** mode and **Regular** mode.
Please read more: https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

> **⚠️ SDK 7 note:** The Flutter plugin does not currently expose Strict mode
> as a public configuration option. Swift Package Manager uses the Regular SDK
> variant. If your Kids App requires Strict mode, use CocoaPods and contact
> AppsFlyer Support for the supported plugin configuration.
