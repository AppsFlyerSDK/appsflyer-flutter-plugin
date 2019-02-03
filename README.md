<img src="https://www.appsflyer.com/wp-content/uploads/2016/11/logo-1.svg"  width="200">

# appsflyer_sdk

A Flutter plugin for AppsFlyer SDK.

[![pub package](https://img.shields.io/pub/v/appsflyer_sdk.svg)](https://pub.dartlang.org/packages/appsflyer_sdk) [![Build Status](https://travis-ci.org/AppsFlyerSDK/flutter_appsflyer_sdk.svg?branch=master)](https://travis-ci.org/AppsFlyerSDK/flutter_appsflyer_sdk)

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).

---

### Supported Platforms

- Android
- iOS 8+

### This plugin is built for

- iOS AppsFlyerSDK **v4.8.10**
- Android AppsFlyerSDK **v4.8.19**

##<a id="api-methods"> API Methods

---

##### **`AppsflyerSdk(Map options)`**

| parameter | type  | description       |
| --------- | ----- | ----------------- |
| `options` | `Map` | SDK configuration |

**`options`**

| name       | type      | default | description                                                                                                                    |
| ---------- | --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `afDevKey` | `string`  |         | [Appsflyer Dev key](https://support.appsflyer.com/hc/en-us/articles/207032126-AppsFlyer-SDK-Integration-Android)               |
| `afAppId`  | `string`  |         | [Apple Application ID](https://support.appsflyer.com/hc/en-us/articles/207032066-AppsFlyer-SDK-Integration-iOS) (for iOS only) |
| `isDebug`  | `boolean` | `false` | debug mode (optional)                                                                                                          |

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

Map options = { "afDevKey": afDevKey,
                "afAppId": appId,
                "isDebug": true};

AppsflyerSdk appsflyerSdk = AppsflyerSdk(appsFlyerOptions);

```

** Or you can use `AppsFlyerOptions` class instead**

##### **`AppsflyerSdk(Map options)`**

| parameter | type               | description       |
| --------- | ------------------ | ----------------- |
| `options` | `AppsFlyerOptions` | SDK configuration |

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

final AppsFlyerOptions options = AppsFlyerOptions(afDevKey: "af dev key",
                                                  showDebug: true,
                                                  appId: "123456789");
```

##### **`static Future<dynamic> initSdk() async`**

initialize the SDK, using the options initialized from the constructor|

_Example:_

```dart
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
//..

AppsflyerSdk appsflyerSdk = AppsflyerSdk({...});

try {
      result = await appsflyerSdk.initSdk();
    } on Exception catch (e) {
      print("error: " + e.toString());
      return;
    }

```

---

##### **`static Future<bool> trackEvent(String eventName, Map eventValues) async`** (optional)

- These in-app events help you track how loyal users discover your app, and attribute them to specific
  campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  to track ROI (Return on Investment) and LTV (Lifetime Value).
- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.

| parameter     | type     | description                                                                                                                                                                       |
| ------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eventName`   | `String` | custom event name, is presented in your dashboard. See the Event list [HERE](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/blob/master/src/ios/AppsFlyerTracker.h) |
| `eventValues` | `Map`    | event details                                                                                                                                                                     |

_Example:_

```dart
Future<bool> sendEvent(String eventName, Map eventValues) async {
    bool result;
    try {
      result = await appsflyerSdk.trackEvent(eventName, eventValues);
    } on Exception catch (e) {}
      print("Result trackEvent: ${result}");
  }
```

---

##### **Conversion Data and on app open attribution**

Returns `Stream`. Accessing AppsFlyer Attribution / Conversion Data from the SDK (Deferred Deeplinking). Read more: [Android](http://support.appsflyer.com/entries/69796693-Accessing-AppsFlyer-Attribution-Conversion-Data-from-the-SDK-Deferred-Deep-linking-), [iOS](http://support.appsflyer.com/entries/22904293-Testing-AppsFlyer-iOS-SDK-Integration-Before-Submitting-to-the-App-Store-). AppsFlyer plugin will return attribution data as JSON `Map` in `Stream`.

##### **`static Stream<dynamic> registerConversionDataCallback()`**

_Example:_

```dart
appsflyerSdk.registerConversionDataCallback().listen((data) {
      //print("GCD: " + data.toString());
      //....
    }).onError((handleError) {
      print("error");
    });
```

_Example of success Organic response:_

```
{
  "status": "success",
  "type": "onInstallConversionDataLoaded",
  "data": {
    "af_status": "Organic",
    "af_message": "organic install",
    "is_first_launch": "false"
  }
}
```

_Example of failure response:_

```
{
  "status": "failure",
  "type": "onInstallConversionDataLoaded",
  "data": "SOME_ERROR_MESSAGE"
}
```

##### **`static Stream<dynamic> registerOnAppOpenAttributionCallback()`**

_Example:_

```dart
appsflyerSdk.registerOnAppOpenAttributionCallback().listen((data) {
      //print("OnAppOpenAttribution: " + data.toString());
      //....
    }).onError((handleError) {
      print("error");
    });
```

_Example of response on deep-link "https://flutter.demo" :_

```
{
  "status": "success",
  "type": "onAppOpenAttribution",
  "data": {
    "link": "https://flutter.demo"
  }
}
```

---
