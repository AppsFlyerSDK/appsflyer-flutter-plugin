# Flutter AppsFlyer Plugin Guides

<img src="https://massets.appsflyer.com/wp-content/uploads/2016/06/26122512/banner-img-ziv.png"  width="150">

## Table of content

- [Init SDK](#init-sdk)
- [Android out of store](#out-of-store)
- [Deep Linking](#deeplinking)
    - [Deferred Deep Linking (Get Conversion Data)](#deferred-deep-linking)
    - [Direct Deep Linking](#direct-deep-linking)
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

Map options = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
```

The next step is to call `initSdk` which have the optional boolean parameters `egisterConversionDataCallback` and `registerOnAppOpenAttributionCallback` which are set to false as default.

After we call `initSdk` we can use all of AppsFlyer SDK features.

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

## <a id="deeplinking"> Deep Linking (coming soon)