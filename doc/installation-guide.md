# Installation

Add the plugin to your app and configure the native (iOS/Android) dependencies. This is
step 1 — continue with [Getting started](getting-started.md) once the package is added.

## Add the package

Open the terminal of your chosen IDE and run the following:

```
flutter pub add appsflyer_sdk
```

This will download the AppsFlyer flutter plugin to your project, you may observe the changes in your `pubspec.yaml` file.

The plugin pulls in the AppsFlyer RPC layer, which in turn brings the native
AppsFlyer SDK. For the exact versions this release resolves to, see
[SDK Versions](../README.md#sdk-versions) in the README.

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

## 👨‍👩‍👧‍👦  Strict mode for Kids Apps

The iOS SDK ships in two variants: **Strict** mode and **Regular** mode
(`AppsFlyerFramework/Main`). Strict mode ships a binary and privacy manifest
suited to ad-ID-less apps (no IDFA/ATT surface). Please read more:
https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

### CocoaPods opt-in (iOS)

Strict mode is selected at **`pod install`** time, not in `pubspec.yaml`. In your
app's `ios/Podfile`, set the global **before** `flutter_ios_podfile_setup` (same
pattern as [Purchase Connector](purchase-connector.md#how-to-opt-in)):

```ruby
$AppsFlyerStrictMode = true
```

Then run `cd ios && pod install` (or rebuild from Flutter). The plugin resolves
`AppsFlyerRPC/Strict` and `AppsFlyerFramework/Strict` instead of the Main subspecs.

Do **not** add `pod 'AppsFlyerFramework/Strict', …` to the Podfile yourself.
That adds Strict alongside the plugin's Main dependency and CocoaPods fails with
duplicate `AppsFlyerLib.xcframework` errors (see
[GitHub issue #473](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/issues/473)).

Runtime APIs such as `setDisableAdvertisingIdentifiers(true)` do not replace
Strict mode — they configure behavior inside whichever native binary is linked.

> **Swift Package Manager:** SPM integrations always use the Regular (`Main`)
> SDK variant. Strict mode requires CocoaPods for this plugin.
>
> **Purchase Connector:** The optional Purchase Connector pod still declares a
> dependency on the Regular `AppsFlyerFramework` subspec. Apps that enable both
> `$AppsFlyerPurchaseConnector` and `$AppsFlyerStrictMode` may hit the same
> duplicate-framework error until those native pins align. Use Strict mode only
> with Core attribution unless AppsFlyer Support confirms a supported combination
> for your versions.
