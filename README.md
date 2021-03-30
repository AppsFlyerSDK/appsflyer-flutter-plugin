<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="200">

# appsflyer_sdk

A Flutter plugin for AppsFlyer SDK.

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk) 
![Coverage](https://raw.githubusercontent.com/AppsFlyerSDK/appsflyer-flutter-plugin/master/coverage_badge.svg)


🛠 In order for us to provide optimal support, we would kindly ask you to submit any issues to support@appsflyer.com


When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , reproduction steps, logs, code snippets and any additional relevant information.



---

### Table of content

- [v6 Breaking changes](#v6-breaking-changes)
- [Getting started](#getting-started)
- [Setting AppsFlyer options](#appsFlyer-options)
- [Initializing the SDK](#init-sdk)
- [Guides](#guides)
- [API](#api)

### Supported Platforms

- Android
- iOS 8+

### This plugin is built for

- iOS AppsFlyerSDK **v6.2.4**

- Android AppsFlyerSDK **v6.2.0**

### Type Safety Introduced from version `7.0.0`, upgraded from `Map` and `dynamic` types!

### Flutter 2.0 is supported from version `6.2.3+2`, including null safety support!

### The version `6.2.4-flutterv1` will use iOS SDK V6.2.4 with Flutter V1

---

## <a id="v7-breaking-changes"> **❗Migration Guide to v7**
With the introduction of type safety, we've fully revamped the way we return data! We've given you tools to interact with those types as well.

Before version 7, your callbacks would receive `dynamic` data and you'd have to do the leg work yourself. Now, in v7, we classes containing 
the information you're looking for. In the case of deep links, we provide classes you can use to convert our `Map`s to.

### Quick Start
Use the `AppsFlyerService` from the example app to get started!

### Rather Do It Yourself?
Use the `map` or `when` method in combination with `OneLinkBase.fromJson` on any `AppsFlyerResponse` to handle the payload returned.

Alternatively, check out the `DeepLinkResponse` class within the service to see how to create your own class with custom params.

## <a id="v6-breaking-changes"> **❗Migration Guide to v6**
- [Integration guide](https://support.appsflyer.com/hc/en-us/articles/207032066#introduction)
- [Migration guide](https://support.appsflyer.com/hc/en-us/articles/360011571778)

In v6 of AppsFlyer SDK there are some api breaking changes: 

|Before v6                      | v6                          |
|-------------------------------|-----------------------------|
| trackEvent                    | logEvent                    |
| stopTracking                  | stop                        |
| validateAndTrackInAppPurchase | validateAndLogInAppPurchase |

|Before v6.1.2+4                | v6.1.2+4                    |
|-------------------------------|-----------------------------|
| validateAndTrackInAppPurchase | validateAndTrackInAppIosPurchase/validateAndTrackInAppAndroidPurchase |

### Important notice
- Switch `ConversionData` and `OnAppOpenAttribution` to be based on callbacks instead of streams since plugin version `6.0.5+2`

## <a id="getting-started"> **📲 Getting started**

In order to install the plugin, visit [this](https://pub.dartlang.org/packages/appsflyer_sdk#-installing-tab-) page.

### <a id="appsFlyer-options"> ⚙️  AppsFlyerOptions

To start using AppsFlyer you first need to create an instance of `AppsflyerSdk` before using any other of our sdk functionalities (see the service in the example app for v7 and above).  

`AppsflyerSdk` receives a map or `AppsFlyerOptions` object. This is how you can configure our `AppsflyerSdk` instance and connect it to your AppsFlyer account.

*Example (using map):*
```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

Map appsFlyerOptions = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

### <a id="init-sdk"> 🚀  Initializing the SDK

The next step is to call `initSdk` which have the optional boolean parameters 
`registerConversionDataCallback`, 
`registerOnAppOpenAttributionCallback` and 
`registerOnDeepLinkingCallback` which are set to true as default.

After we call `initSdk` we can use all of AppsFlyer SDK features.

Initialize the SDK to enable AppsFlyer to detect installations, sessions (app opens) ,updates and use all of our features.

```dart
appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnAppOpenAttributionCallback: true,
    registerOnDeepLinkingCallback: true
);
```

## <a id="guides"> **📖 Guides**

Great installation and setup guides can be viewed [here](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/Guides.md)

## <a id="api"> **📑 API**

see the full [API](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/API.md) available for this plugin.
