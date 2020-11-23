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
- [Initializing the sdk](#init-sdk)
- [Guides](#guides)
- [API](#api)

### Supported Platforms

- Android
- iOS 8+

### This plugin is built for

- iOS AppsFlyerSDK **v6.0.5**
- Android AppsFlyerSDK **v5.4.5**

---
## <a id="v6-breaking-changes"> **❗Migration Guide to v6**
- [Integration guide](https://support.appsflyer.com//hc/en-us/articles/207032066#introduction)
- [Migration guide](https://support.appsflyer.com/hc/en-us/articles/360011571778)

In v6 of AppsFlyer SDK there are some api breaking changes: 

|Before v6                      | v6                          |
|-------------------------------|-----------------------------|
| trackEvent                    | logEvent                    |
| stopTracking                  | stop                        |
| validateAndTrackInAppPurchase | validateAndLogInAppPurchase |

## <a id="getting-started"> **📲 Getting started**

In order to install the plugin, visit [this](https://pub.dartlang.org/packages/appsflyer_sdk#-installing-tab-) page.

To start using AppsFlyer you first need to create an instance of `AppsflyerSdk` before using any other of our sdk functionalities.  

`AppsflyerSdk` receives a map or `AppsFlyerOptions` object. This is how you can configure our `AppsflyerSdk` instance and connect it to your AppsFlyer account.

*Example (using map):*
```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

Map options = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

The next step is to call `initSdk` which have the optional boolean parameters `registerConversionDataCallback` and `registerOnAppOpenAttributionCallback` which are set to false as default.

After we call `initSdk` we can use all of AppsFlyer SDK features.

## <a id="init-sdk"> **🚀 Initializing the SDK**

Initialize the SDK to enable AppsFlyer to detect installations, sessions (app opens) ,updates and use all of our features.

## <a id="guides"> **📖 Guides**

Great installation and setup guides can be viewed [here](/doc/Guides.md)

## <a id="api"> **📑 API**

see the full [API](/doc/API.md) available for this plugin.
