# Deep linking

Deep Linking vs Deferred Deep Linking:

A deep link is a special URL that routes to a specific spot, whether that’s on a website or in an app. A “mobile deep link” then, is a link that contains all the information needed to take a user directly into an app or a particular location within an app instead of just launching the app’s home page.

If the app is installed on the user's device - the deep link routes them to the correct location in the app. But what if the app isn't installed? This is where Deferred Deep Linking is used.When the app isn't installed, clicking on the link routes the user to the store to download the app. Deferred Deep linking defer or delay the deep linking process until after the app has been downloaded, and ensures that after they install, the user gets to the right location in the app.

[Android and iOS set-up](#setup)

![alt text](https://massets.appsflyer.com/wp-content/uploads/2018/03/21101417/app-installed-Recovered.png "")


#### <a id="Deep-Linking"> The 3 Deep Linking Types:
Since users may or may not have the mobile app installed, there are 2 types of deep linking (Deferred + Direct DeepLinking Legacy APIs or Unified Deep Linking):

1. Deferred Deep Linking - Legacy API, serving personalized content to new or former users, directly after the installation. 
2. Direct Deep Linking - Legacy API, directly serving personalized content to existing users, which already have the mobile app installed.
3. Unified Deep Linking - Starting from v6.1.3, the new Unified Deep Linking API is available to handle deeplinking logic.

In general, you should utilize either **both** of the legacy methods for deep linking, or only the Unified Deep Linking.

For more info please check out the [OneLink™ Deep Linking Guide](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#Intro).

---

###  <a id="deferred-deep-linking"> 1. Deferred Deep Linking (Get Conversion Data)

Check out the deferred deeplinking guide from the AppFlyer knowledge base [here](https://support.appsflyer.com/hc/en-us/articles/207032096-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deeplinking-#Introduction).

Code sample to handle the `onInstallConversionData`:

```dart
appsflyerSdk.onInstallConversionData((res){
    print("res: " + res.toString());
});
```

**Note:** The code implementation for `onInstallConversionData` must be made **prior to the initialization** code of the SDK.

---

###  <a id="handle-deeplinking"> 2. Direct Deeplinking
    
When a deeplink is clicked on the device the AppsFlyer SDK will return the resolved link in the [onAppOpenAttribution](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#deep-linking-data-the-onappopenattribution-method-) method.

Code sample to handle `OnAppOpenAttribution`:

```dart
appsflyerSdk.onAppOpenAttribution((res){
    print("res: " + res.toString());
});
```

**Note:** The code implementation for `onAppOpenAttribution` must be made **prior to the initialization** code of the SDK.

---

###  <a id="unified-deeplinking"> 3. Unified deep linking

The flow works as follows:

1. User clicks the OneLink short URL.
2. The iOS Universal Links/ Android App Links (for deep linking) or the deferred deep link, triggers the SDK.
3. The SDK triggers the didResolveDeepLink method, and passes the deep link result object to the user.
4. The onDeepLinking method uses the deep link result object that includes the deep_link_value and other parameters to create the personalized experience for the users, which is the main goal of OneLink.

> Check out the Unified Deep Linking docs for [Android](https://dev.appsflyer.com/docs/android-unified-deep-linking) and [iOS](https://dev.appsflyer.com/docs/ios-unified-deep-linking).

Considerations:

* Requires AppsFlyer Android SDK V6.1.3 or later.
* Does not support SRN campaigns.
* Does not provide af_dp in the API response.
* `onAppOpenAttribution` will not be called. All code should migrate to `onDeepLinking`.

**Note:** The code implementation for `onDeepLinking` must be made **prior to the initialization** code of the SDK.

Code sample to handle `onDeepLinking`:

```dart
 appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
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

From version v6.4.0 a Unified deeplinking class was addded. You may use the following class to handle the deeplink:

```dart
class DeepLink {

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

---
    
# <a id="setup"> Set-up

###  <a id="android-deeplink"> Android Deeplink Setup
    
#### <a id="uri-scheme"> URI Scheme
In your app’s manifest add the following intent-filter to your relevant activity:
```xml 
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="your unique scheme" />
</intent-filter>
```

---

#### <a id="app-links"> App Links
For more on App Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/115005314223-Deep-Linking-Users-with-Android-App-Links#what-are-android-app-links).

In your app's manifest add the following intent-filter to your relevant activity:
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

---

#### <a id="on-new-intent"> onNewIntent

**❗Setting the intent this way is not required from v6.4.0 and above❗**
**❗If you are using a plugin version higher or equal to v6.4.0, ignore this section❗**

**NOTE:** On Android, AppsFlyer SDK inspects the activity intent object during onResume(). Because of that, for each activity that may be configured or launched with any [non-standard launch mode](https://developer.android.com/guide/topics/manifest/activity-element#lmode) please make sure to add the following code to `MainActivity.java` in `android/app/src/main/java/com...`

Java example:
```java
    @Override
    public void onNewIntent(Intent intent) {
         super.onNewIntent(intent);
         setIntent(intent);
    }
```

Kotlin example:
```
    override fun onNewIntent(intent : Intent){
        super.onNewIntent(intent)
        setIntent(intent)
    }
```

✏️✏️

###  <a id="ios-deeplink"> iOS Deeplink Setup

For more on Universal Links check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-Deep-Linking-Guide#setups-universal-links).
    
Essentially, the Universal Links method links between an iOS mobile app and an associate website/domain, such as AppsFlyer’s OneLink domain (xxx.onelink.me). To do so, it is required to:

1. Configure OneLink sub-domain and link to the mobile app (by hosting the ‘apple-app-site-association’ file - AppsFlyer takes care of this part in the onelink setup on your dashboard)
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

#### <a id="ios-uri-scheme">  URI Scheme

Add your URI Scheme in the project's settings under "General" -> "URL Types" -> Add a new "URI Scheme".

**❗Adding the following URI Scheme code is not required from v6.4.0 and above❗**
**❗If you are using a plugin version higher or equal to v6.4.0, ignore the rest of this section❗**

Add the following to your `AppDelegate`:

Objective-C example:

```
    - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
        // Only for AppsFlyer SDK version 6.2.0 and above 
        [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
        
        // Only for AppsFlyer SDK version 6.1.0 and below 
        [[AppsFlyerLib shared] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
        return YES;
    }

    // Reports app open from deep link for iOS 10
    - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *) options {
        
        // Only for AppsFlyer SDK version 6.2.0 and above 
        [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
        
        // Only for AppsFlyer SDK version 6.1.0 and below 
        [[AppsFlyerLib shared] handleOpenUrl:url options:options];
        return YES;
    }
```

Swift example:

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

For more information on URI-Schemes check out the guide [here](https://support.appsflyer.com/hc/en-us/articles/208874366-OneLink-deep-linking-guide#setups-uri-scheme-for-ios-8-and-below).

---

#### <a id="universal-links">  Universal Links

**❗Adding the following Universal Links code is not required from v6.4.0 and above❗**
**❗If you are using a plugin version higher or equal to v6.4.0, ignore the rest of this section❗**

Objective-C example:

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
    
Swift example:

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