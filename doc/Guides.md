# Flutter AppsFlyer Plugin Guides

<img src="https://massets.appsflyer.com/wp-content/uploads/2016/06/26122512/banner-img-ziv.png"  width="150">

## Table of content

- [Init SDK](#init-sdk)
- [Android out of store](#out-of-store)
- [Deep Linking](#deeplinking)
    - [Deferred Deep Linking (Get Conversion Data)](#deferred-deep-linking)
    - [Direct Deep Linking](#direct-deep-linking)
    - [Unified deep linking](#Unified-deep-linking)
    - [iOS Deeplink Setup](#iosdeeplinks)
    - [Android Deeplink Setup](#android-deeplinks)

    ---

##  <a id="init-sdk"> Init SDK

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

Handle both the Direct & the deferred deeplink in the following callback:

```dart
appsflyerSdk.onDeepLinking((res){
    print("res: " + res.toString());
});
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

**NOTE:** On Android, AppsFlyer SDK inspects activity intent object during onResume(). Because of that, for each activity that may be configured or launched with any [non-standard launch mode](https://developer.android.com/guide/topics/manifest/activity-element#lmode) the following code was added to `MainActivity.java` in `android/app/src/main/java/com...`

```java
@Override
    public void onNewIntent(Intent intent) {
         super.onNewIntent(intent);
         setIntent(intent);
    }
```

#### App Links
For more on App Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/115005314223-Deep-Linking-Users-with-Android-App-Links#what-are-android-app-links).


###  <a id="ios-deeplink"> iOS Deeplink Setup

In order for the callback to be called:
1. Import AppsFlyer SDK:
    
    a. For AppsFlyer SDK V6.2.0 and above add: ```#import #import "AppsflyerSdkPlugin.h"```
   
    b. For AppsFlyer SDK V6.1.0 and below add: ```#import <AppsFlyerLib/AppsFlyerLib.h>```

2. Set-up the following AppsFlyer API:

#### URI Scheme

```
//   Reports app open from deep link from apps which do not support Universal Links (Twitter) and for iOS8 and below
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

For more on URI-schemes check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-deep-linking-guide#setups-uri-scheme-for-ios-8-and-below)


### Universal Links
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
    

More on Universal Links:

Essentially, the Universal Links method links between an iOS mobile app and an associate website/domain, such as AppsFlyer’s OneLink domain (xxx.onelink.me). To do so, it is required to:
1. Configure OneLink sub-domain and link to mobile app (by hosting the ‘apple-app-site-association’ file - AppsFlyer takes care of this part in the onelink setup on your dashboard)
2. Configure the mobile app to register approved domains:

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
