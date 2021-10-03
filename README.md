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
- [Set plugin for IOS 14](#ios14)
- [Additional Guides](#guides)
- [APIs](#api)

---

### Supported Platforms

- Android
- iOS 8+

### This plugin is built for

- iOS AppsFlyerSDK **v6.4.0**

- Android AppsFlyerSDK **v6.4.0**

### Flutter 2.0 is supported from version `6.2.3+2`, including null safety support!

### The version `6.2.4-flutterv1` will use iOS SDK V6.2.4 with Flutter V1

---
## <a id="v6.4.0-breaking-changes"> **❗Breaking changes in v6.4.0**
- UDL (Unified deep link) now as a dedicated class with getters for handling the deeplink result. 
[Check the full UDL guide](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/Guides.md#-3-unified-deep-linking).
- `setSharingFilter` & `setSharingFilterForAllPartners` APIs are deprecated. 
Instead use the [new API `setSharingFilterForPartners`](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/RD-69098/update6.4.0%26more/doc/API.md#setSharingFilterForPartners).


## <a id="v6.3.5+2"> **❗Breaking changes in v6.3.5+2**
- Remove stream from the plugin (no change is needed if you use callbacks for handling deeplink).


## <a id="v6-breaking-changes"> **❗Migration Guide to v6**
- [Integration guide](https://support.appsflyer.com//hc/en-us/articles/207032066#introduction)
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

---

## <a id="getting-started"> **📲 Getting started**

In order to install the plugin, visit [this](https://pub.dartlang.org/packages/appsflyer_sdk#-installing-tab-) page.

---

### <a id="appsFlyer-options"> ⚙️  AppsFlyerOptions

To start using AppsFlyer you first need to create an instance of `AppsflyerSdk` before using any other of our sdk functionalities.  

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


**Disable Advertiser ID & IDFA:**


Adding `"disableAdvertisingIdentifier": true` in the appsFlyerOptions will disable:


Android:

OAID (Open Anonymous Device Identifier)

AAID (Amazon Advertising ID)

GAID (Google Advertising ID)


iOS:

IDFA


```dart
Map appsFlyerOptions = { 
    "afDevKey": afDevKey,
    "afAppId": appId,
    "isDebug": true
    "disableAdvertisingIdentifier": true
};
```
---

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

---

## <a id="ios14"> Set plugin for IOS 14

1. Add `#import <AppTrackingTransparency/AppTrackingTransparency.h>` in your `AppDelegate.m` 

2. Add the ATT pop-up for IDFA collection so your `AppDelegate.m` will look like this:
```
-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [GeneratedPluginRegistrant registerWithRegistry:self];
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            //If you want to do something with the pop-up
        }];
    }
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

3. Add Privacy - Tracking Usage Description inside your `.plist` file in Xcode.

4. Optional: Set the `timeToWaitForATTUserAuthorization` property in the `AppsFlyerOptions` to delay the sdk initazliation for a number of `x seconds` until the user accept the consent dialog:
```dart
AppsFlyerOptions options = AppsFlyerOptions(
    afDevKey: DotEnv().env["DEV_KEY"],
    appId: DotEnv().env["APP_ID"],
    showDebug: true,
    timeToWaitForATTUserAuthorization: 30
    ); 
```

For more info visit our Full Support guide for iOS 14:

https://support.appsflyer.com/hc/en-us/articles/207032066#integration-33-configuring-app-tracking-transparency-att-support

---

## <a id="guides"> **📖 Additional Guides (Deeplinking, out of store, Strict mode (app for kids) & iOS 14) **

Great installation and setup guides can be viewed [here](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/Guides.md)

---
## <a id="api"> **📑 API**

see the full [API](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/API.md) available for this plugin.
