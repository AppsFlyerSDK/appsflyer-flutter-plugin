# appsflyer_sdk_example

This plugin has a demo project bundled with it. To give it a try , clone this repo and from root a.e. `flutter_appsflyer_sdk` execute the following:

```bash
$ flutter packages get
$ cd example/
$ flutter run

```

![demo printscreen](assets/demo_example.png?raw=true)

# How to Use Your Dashboard

1. Update the `.env` file with your values:

```bash
DEV_KEY="your dev key" # via Website Configuration Settings: https://hq1.appsflyer.com/account/api-tokens
ANDROID_APP_ID="com.domain.andoidApp"
IOS_APP_ID="com.domain.iosapp"
```

2. Update the intent filter on Android
Location: android > app > src > main > AndroidManifest.xml

```xml
<!-- start appsflyer_sdk -->
<!-- Get your apps configuration from the AppsFlyer Dashboard --> 
<!-- OneLink Template: "When app is installed" > Launching the app using Android App Links > Save Changes -->
<intent-filter  android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
        android:host="yourcompany.onelink.me"
        android:pathPrefix="yourPrefix" /> 
</intent-filter>
<!-- end appsflyer_sdk -->
```

3. Reload the app (stop the debugger)