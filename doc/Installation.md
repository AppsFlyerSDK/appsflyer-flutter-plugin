# Adding   appsflyer-flutter-plugin to your project

## Installation

Open the terminal of your chosen IDE and run the following:

```
flutter pub add appsflyer_sdk
```

This will download the AppsFlyer flutter plugin to your project, you may observe the changes in your `pubspec.yaml` file.

---

## <a id="strictMode">👨‍👩‍👧‍👦  Strict mode for Kids Apps

Starting from version **6.2.4-nullsafety.5**, the iOS SDK comes in two variants: **Strict** mode and **Regular** mode. 
Please read more: https://support.appsflyer.com/hc/en-us/articles/207032066#integration-strict-mode-sdk

***Change to Strict mode***

After you installed the AppsFlyer plugin:
1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder
2. Open `appsflyer_sdk.podspec`, add `/Strict` to the `s.ios.dependency` as follow:
`s.ios.dependency 'AppsFlyerFramework', '6.x.x'` to `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'`
and save.

3. Go to the `ios` folder of your current project and run `pod update`.

***Change to Regular mode***

After you installed the AppsFlyer plugin:
1. Go to the `$HOME/.pub-cache/hosted/pub.dartlang.org/appsflyer_sdk-<CURRENT VERSION>/ios` folder:
2. Open `appsflyer_sdk.podspec` and remove `/Strict`:
change `s.ios.dependency 'AppsFlyerFramework/Strict', '6.x.x'` to `s.ios.dependency 'AppsFlyerFramework', '6.x.x'`
and save.

3. Go to the `ios` folder of your current project and run `pod update`.