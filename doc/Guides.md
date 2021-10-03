# Flutter AppsFlyer Plugin Guides

<img src="https://massets.appsflyer.com/wp-content/uploads/2016/06/26122512/banner-img-ziv.png"  width="150">

## Table of content

- [Init SDK](#init-sdk)
- [Android out of store](#out-of-store)
- [Deep Linking](#deeplinking)
    - [Deferred Deep Linking (Get Conversion Data)](#deferred-deep-linking)
    - [Direct Deep Linking](#direct-deep-linking)
    - [Unified deep linking](#Unified-deep-linking)
    - [Android Deeplink Setup](#android-deeplinks)
    - [iOS Deeplink Setup](#iosdeeplinks)
    - [Example in swift](#Example-swift)
- [Set plugin for IOS 14](#ios14)
- [Setting strict mode (app for kids)](#strictMode)
- [Uninstall feature](#uninstall)

---

##  <a id="init-sdk"> Init SDK

To start using AppsFlyer you first need to create an instance of `AppsflyerSdk` before using any other of our sdk functionalities.  

`AppsflyerSdk` receives a map or `AppsFlyerOptions` object. This is how you can configure our `AppsflyerSdk` instance and connect it to your AppsFlyer account.

*Example (using map):*
```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsFlyerOptions appsFlyerOptions = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

The next step is to call `initSdk` which have the optional boolean parameters `registerConversionDataCallback` and the deeplink callbacks: `registerOnAppOpenAttributionCallback` 
`registerOnDeepLinkingCallback`
All callbacks are set to true as default.

After we call `initSdk` we can use all of AppsFlyer SDK features.

```dart
appsflyerSdk.initSdk(
    registerConversionDataCallback: true,
    registerOnAppOpenAttributionCallback: true,
    registerOnDeepLinkingCallback: true
);
```

---

## <a id="out-of-store"> Android Out of store
Please make sure to go over [this guide](https://support.appsflyer.com/hc/en-us/articles/207447023-Attributing-out-of-store-Android-markets-guide) to get general understanding of how out of store attribution is set up in AppsFlyer. If the store you distribute the app through supports install referrer matching or requires the referrer in the postback, make sure to add the following to the AndroidManifest.xml:
```xml
<application>
...
	<receiver android:name="com.appsflyer.SingleInstallBroadcastReceiver" android:exported="true">
		<intent-filter>
			 <action android:name="com.android.vending.INSTALL_REFERRER" />
		 </intent-filter>
	</receiver>
</application>
```

---

## <a id="deeplinking"> Deep Linking
<img src="https://massets.appsflyer.com/wp-content/uploads/2018/03/21101417/app-installed-Recovered.png" width="350">


#### The 3 Deep Linking Types:
Since users may or may not have the mobile app installed, there are 2 types of deep linking:

1. Deferred Deep Linking - Serving personalized content to new or former users, directly after the installation. 
2. Direct Deep Linking - Directly serving personalized content to existing users, which already have the mobile app installed.
3. Unified deep linking - Unified deep linking sends new and existing users to a specific in-app activity as soon as the app is opened.

For more info please check out the [OneLink™ Deep Linking Guide](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#Intro).

###  <a id="deferred-deep-linking"> 1. Deferred Deep Linking (Get Conversion Data)
In order to use the unified deep link you need to send the `registerConversionDataCallback: true` flag inside the object that sent to the sdk.

=======
Handle the Deferred deeplink in the following callback:
```dart
appsflyerSdk.onInstallConversionData((res){
    print("res: " + res.toString());
});
```

Check out the deferred deeplinkg guide from the AppFlyer knowledge base [here](https://support.appsflyer.com/hc/en-us/articles/207032096-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deeplinking-#Introduction)

###  <a id="handle-deeplinking"> 2. Direct Deeplinking
In order to use the unified deep link you need to send the `registerOnAppOpenAttributionCallback: true` flag inside the object that sent to the sdk.

Handle the Direct deeplink in the following callback:

```dart
appsflyerSdk.onAppOpenAttribution((res){
    print("res: " + res.toString());
});
```

When a deeplink is clicked on the device the AppsFlyer SDK will return the link in the [onAppOpenAttribution](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#deep-linking-data-the-onappopenattribution-method-) method.

###  <a id="Unified-deep-linking"> 3. Unified deep linking
In order to use the unified deep link you need to send the `registerOnDeepLinkingCallback: true` flag inside the object that sent to the sdk.
**NOTE:** when sending this flag, the sdk will ignore `onAppOpenAttribution`!

**Breaking changes!**

From version v6.4.0 a Unified deeplinking class was addded. You can use the following class to handle the deeplink:

```dart
class DeepLink{

    DeepLink(this._clickEvent);
    final Map<String , dynamic> _clickEvent;
    Map<String , dynamic> get clickEvent => _clickEvent;
    String? get deepLinkValue =>  _clickEvent["deep_link_value"] as String;
    String? get matchType =>  _clickEvent["match_type"] as String;
    String? get clickHttpReferrer =>   _clickEvent["click_http_referrer"] as String;
    String? get mediaSource =>  _clickEvent["media_source"] as String;
    String? get campaign =>  _clickEvent["campaign"] as String;
    String? get campaignId =>   _clickEvent["campaign_id"] as String;
    String? get afSub1 => _clickEvent["af_sub1"] as String;
    String? get afSub2 =>  _clickEvent["af_sub2"] as String;
    String? get afSub3 => _clickEvent["af_sub3"] as String;
    String? get afSub4 =>  _clickEvent["af_sub4"] as String;
    String? get afSub5 =>   _clickEvent["af_sub5"] as String;
    bool get isDeferred =>  _clickEvent["is_deferred"] as bool;

    @override
    String toString() {
        return 'DeepLink: ${jsonEncode(_clickEvent)}';
    }
    String? getStringValue(String key) {
        return _clickEvent[key] as String;
    }
}
```

Example of handling both the Direct & the deferred deeplink in the following callback:

```dart
 _appsflyerSdk?.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          print(dp.deepLink?.toString());
          print("deep link value: ${dp.deepLink?.deepLinkValue}");
          break;
        case Status.NOT_FOUND:
          print("deep link not found");
          break;
        case Status.ERROR:
          print("deep link error: ${dp.error}");
          break;
        case Status.PARSE_ERROR:
          print("deep link status parsing error");
          break;
      }
    }
```

For more information about this api, please check [OneLink Guide Here](https://dev.appsflyer.com/docs/android-unified-deep-linking)

###  <a id="android-deeplink"> Android Deeplink Setup
    
    
    
#### URI Scheme
In your app’s manifest add the following intent-filter to your relevant activity:
```xml 
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="your unique scheme" />
</intent-filter>
```

**❗Not needed from v6.4.0 and above**

**NOTE:** On Android, AppsFlyer SDK inspects activity intent object during onResume(). Because of that, for each activity that may be configured or launched with any [non-standard launch mode](https://developer.android.com/guide/topics/manifest/activity-element#lmode) the following code was added to `MainActivity.java` in `android/app/src/main/java/com...`

Java:

```java
    @Override
    public void onNewIntent(Intent intent) {
         super.onNewIntent(intent);
         setIntent(intent);
    }
```

Kotlin:

```
    override fun onNewIntent(intent : Intent){
        super.onNewIntent(intent)
        setIntent(intent)
    }
```


#### App Links

In your app’s manifest add the following intent-filter to your relevant activity:

```xml 
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="your unique scheme" />
    <data android:scheme="https"
        android:host="yourcompany.onelink.me" 
        android:pathPrefix="your path prefix" />
</intent-filter>
```

For more on App Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/115005314223-Deep-Linking-Users-with-Android-App-Links#what-are-android-app-links).


###  <a id="iosdeeplinks"> iOS Deeplink Setup

**❗Not needed from v6.4.0 and above**


In order for the callback to be called:
	
1. Import AppsFlyer SDK:
    
Objective C:
	
    a. For AppsFlyer SDK V6.2.0 and above add: 
	
	```#import "AppsflyerSdkPlugin.h"```
   
    b. For AppsFlyer SDK V6.1.0 and below add: 
	
	```#import <AppsFlyerLib/AppsFlyerLib.h>```

Swift:
	
Add ```import AppsFlyerLib``` in the `AppDelegate.swift` file.

Add in the `Runner-Bridging-Header.h` one of the following lines:
	
     a. For AppsFlyer SDK V6.2.0 and above add: 
	
	```#import <AppsflyerSdkPlugin.h>``
   
     b. For AppsFlyer SDK V6.1.0 and below add: 
	
	```#import <AppsFlyerLib/AppsFlyerLib.h>```

2. Set-up the following AppsFlyer API:

### URI Scheme


Objective-C:

```
    - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
        // AppsFlyer SDK version 6.2.0 and above 
        [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
        
        // AppsFlyer SDK version 6.1.0 and below 
        [[AppsFlyerLib shared] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
        return YES;
    }

    // Reports app open from deep link for iOS 10
    - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *) options {
        
        // AppsFlyer SDK version 6.2.0 and above 
        [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
        
        // AppsFlyer SDK version 6.1.0 and below 
        [[AppsFlyerLib shared] handleOpenUrl:url options:options];
        return YES;
    }
```

Swift:

```swift
    override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AppsFlyerAttribution.shared()!.handleOpenUrl(url, sourceApplication: sourceApplication, annotation: annotation);
        return true
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerAttribution.shared()!.handleOpenUrl(url, options: options)
        return true
    }
```

For more on URI-schemes check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-deep-linking-guide#setups-uri-scheme-for-ios-8-and-below)


### Universal Links

**❗Not needed from v6.4.0 and above**

Objective-C:

    ```
    // Reports app open from a Universal Link for iOS 9 or above
    - (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
        // AppsFlyer SDK version 6.2.0 and above 
        [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
        
        // AppsFlyer SDK version 6.1.0 and below 
        [[AppsFlyerLib shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
        return YES;
    }
    ```
    
Swift:

```swift
    private func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        AppsFlyerAttribution.shared()!.continueUserActivity(userActivity, restorationHandler: nil)
        return true
    }

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerAttribution.shared()!.continueUserActivity(userActivity, restorationHandler: nil)
        return true
     }
```

<a id="Example-swift">	
###Example in swift:###
	
	

`Runner-Bridging-Header.h`	
	
```	
#import "GeneratedPluginRegistrant.h"
#import <AppsflyerSdkPlugin.h>
```
	
	
`AppDelegate.swift`
	
```swift
import UIKit
import Flutter
import AppsFlyerLib

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
       // Open URI-scheme for iOS 9 and above
    override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        NSLog("AppsFlyer [deep link]: Open URI-scheme for iOS 9 and above")
        AppsFlyerAttribution.shared()!.handleOpenUrl(url, sourceApplication: sourceApplication, annotation: annotation);
        return true
       }

       // Reports app open from deep link for iOS 10 or later
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        NSLog("AppsFlyer [deep link]: continue userActivity")
        AppsFlyerAttribution.shared()!.continueUserActivity(userActivity, restorationHandler:nil )
           return true
       }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        NSLog("AppsFlyer [deep link]: Open URI-scheme options")

        AppsFlyerAttribution.shared()!.handleOpenUrl(url, options: options)
           return true
       }
}
```
	
	
More on Universal Links:
Essentially, the Universal Links method links between an iOS mobile app and an associate website/domain, such as AppsFlyer’s OneLink domain (xxx.onelink.me). To do so, it is required to:

1. Get your SHA256 fingerprint:

    a. [Creating A Keystore](https://flutter.dev/docs/deployment/android#create-a-keystore) (you'll eventually need to do this to release on the Play Store)

    b. [Generate Fingerprint](https://developers.google.com/android/guides/client-auth)
2. Configure OneLink sub-domain and link to mobile app in the AppsFlyer onelink setup on your dashboard, add the fingerprint there (AppsFlyer takes care of hosting the ‘apple-app-site-association’ file)
3. Configure the mobile app to register approved domains:

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

For more on Universal Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#setups-universal-links).


## <a id="ios14"> Set plugin for IOS 14
	
1. Adding the conset dialog:
	
There are 2 ways to add it to your app:
	
	a. Add the following Library: https://pub.dev/packages/app_tracking_transparency

Or 
	
	b. Add native implementation:

	
- Add `#import <AppTrackingTransparency/AppTrackingTransparency.h>` in your `AppDelegate.m` 

- Add the ATT pop-up for IDFA collection so your `AppDelegate.m` will look like this:
	
	
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

	

2. Add Privacy - Tracking Usage Description inside your `.plist` file in Xcode.
	
```
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```
	
3. Optional: Set the `timeToWaitForATTUserAuthorization` property in the `AppsFlyerOptions` to delay the sdk initazliation for a number of `x seconds` until the user accept the consent dialog:
	
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

## <a id="strictMode">👨‍👩‍👧‍👦  Strict mode for App-kids

Starting from version **6.2.4-nullsafety.5** iOS SDK comes in two variants: **Strict** mode and **Regular** mode. 

Please read more: https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

***Change to Strict mode***

After you [installed](#installation) the AppsFlyer plugin:

1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder
2. Open `appsflyer_sdk.podspec`, add `/Strict` to the `s.ios.dependency` as follow:

`s.ios.dependency 'AppsFlyerFramework', '6.x.x'` To >> `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'`
and save

3. Go to `ios` folder of your current project and Run `pod update`

***Change to Regular mode***

1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder:
2. Open `appsflyer_sdk.podspec` and remove `/strict`:

`s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'` To >> `s.ios.dependency 'AppsFlyerFramework', '6.x.x'`
and save

3. Go to `ios` folder of your current project and Run `pod update`

---

## <a id="uninstall"> Uninstall Feature

Android:

1. Add Firebase messaging to your flutter app. You can use the Offical Firebase messagin package by Google:
https://pub.dev/packages/firebase_messaging
2. Follow the native guide on implementing the Uninstall feature both on the Firebase plaform and the app:
https://support.appsflyer.com/hc/en-us/articles/360017822118-Integrate-Android-uninstall-measurement-into-an-app

iOS:

1. Follow the native iOS guide:

https://support.appsflyer.com/hc/en-us/articles/360017822178-Integrate-iOS-uninstall-measurement-into-an-app-

---
