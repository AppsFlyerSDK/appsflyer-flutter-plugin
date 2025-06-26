<img src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png"  width="400" > 

# appsflyer-flutter-plugin 

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk) 
![Coverage](https://raw.githubusercontent.com/AppsFlyerSDK/appsflyer-flutter-plugin/master/coverage_badge.svg)

🛠 In order for us to provide optimal support, we would kindly ask you to submit any issues to support@appsflyer.com

> *When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , production steps, logs, code snippets and any additional relevant information.*


### <a id="plugin-build-for"> This plugin is built for

- Android AppsFlyer SDK **v6.16.2**
- iOS AppsFlyer SDK **v6.16.2**

## <a id="breaking-changes"> 	❗❗ Breaking changes when updating to v6.x.x❗❗

If you have used one of the removed/changed APIs, please check the integration guide for the updated instructions.

- From version `6.11.2`, the `setPushNotification` will not work in iOS. [Please use our new API `sendPushNotificationData` when receiving a notification on flutter side](/doc/API.md#sendPushNotificationData). 

- From version `6.8.0`, the `enableLocationCollection` has been removed from the plugin.

- From version `6.4.0`, UDL (Unified deep link) now as a dedicated class with getters for handling the deeplink result. 
[Check the full UDL guide](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/Guides.md#-3-unified-deep-linking).
`setSharingFilter` & `setSharingFilterForAllPartners` APIs are deprecated. 
Instead use the [new API `setSharingFilterForPartners`](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/RD-69098/update6.4.0%26more/doc/API.md#setSharingFilterForPartners).

- From version `6.3.5+2`, Remove stream from the plugin (no change is needed if you use callbacks for handling deeplink).

- From version `6.2.3+2`, Flutter 2 is supported, including null safety.
`6.2.4-flutterv1` will use iOS SDK 6.2.4 with Flutter V1.

- From version `6.0.0`, we have renamed the following APIs:

|Before v6                      | v6                          |
|-------------------------------|-----------------------------|
| trackEvent                    | logEvent                    |
| stopTracking                  | stop                        |
| validateAndTrackInAppPurchase | validateAndLogInAppPurchase |

- From version `6.1.2+4`, we have renamed the following APIs:

|Before v6.1.2+4                | v6.1.2+4                    |
|-------------------------------|-----------------------------|
| validateAndLogInAppPurchase | validateAndLogInAppIosPurchase/validateAndLogInAppAndroidPurchase |

### Important notice
- Switch `ConversionData` and `OnAppOpenAttribution` to be based on callbacks instead of streams from plugin version `6.0.5+2`.

## AD_ID permission for Android
In v6.8.0 of the AppsFlyer SDK, we added the normal permission `com.google.android.gms.permission.AD_ID` to the SDK's AndroidManifest, 
to allow the SDK to collect the Android Advertising ID on apps targeting API 33.
If your app is targeting children, you need to revoke this permission to comply with Google's Data policy.
You can read more about it [here](https://dev.appsflyer.com/hc/docs/install-android-sdk#the-ad_id-permission).

##  📖 Guides
- [Adding the SDK to your project](/doc/Installation.md)
- [Initializing the SDK](/doc/BasicIntegration.md)
- [In-app Events](/doc/InAppEvents.md)
- [Deep Linking](/doc/DeepLink.md)
- [Advanced APIs](/doc/AdvancedAPI.md)
- [Testing the integration](/doc/Testing.md)
- [APIs](/doc/API.md)
- [Sample App](/example)
