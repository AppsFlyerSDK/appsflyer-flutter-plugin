
# Flutter Purchase Connector
**At a glance:** Automatically validate and measure revenue from in-app purchases and auto-renewable subscriptions to get the full picture of your customers' life cycles and accurate ROAS measurements.
For more information please check the following pages:
*  [ROI360 in-app purchase (IAP) and subscription revenue measurement](https://support.appsflyer.com/hc/en-us/articles/7459048170769-ROI360-in-app-purchase-IAP-and-subscription-revenue-measurement?query=purchase)
* [Android Purchase Connector](https://dev.appsflyer.com/hc/docs/purchase-connector-android)
* [iOS Purchase Connector](https://dev.appsflyer.com/hc/docs/purchase-connector-ios)

🛠 In order for us to provide optimal support, we would kindly ask you to submit any issues to
support@appsflyer.com

> *When submitting an issue please specify your AppsFlyer sign-up (account) email , your app ID , production steps, logs, code snippets and any additional relevant information.*

## Table Of Content
<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

* [Important Note](#important-note)
* [Adding The Connector To Your Project](#install-connector)
  - [How to Opt-In](#install-connector)
  - [What Happens if You Use Dart Files Without Opting In?](#install-connector)
* [Basic Integration Of The Connector](#basic-integration)
  - [Create PurchaseConnector Instance](#create-instance)
  - [Start Observing Transactions](#start)
  - [Stop Observing Transactions](#stop)
  - [Log Subscriptions](#log-subscriptions)
  - [Log In App Purchases](#log-inapps)
* [Register Validation Results Listeners](#validation-callbacks)
  - [Cross-Platform Considerations](#cross-platform-considerations)
  - [Android Callback Types](#android-callback-types)
  - [Android - Subscription Validation Result Listener](#ars-validation-callbacks)
  - [Android In Apps Validation Result Listener](#inapps-validation-callbacks)
  - [iOS Combined  Validation Result Listener](#ios-callback)
* [Testing the Integration](#testing)
  - [Android](#testing-android)
  - [iOS](#testing-ios)
  - [Dart Usage for Android and iOS](#testing-config)
* [ProGuard Rules for Android](#proguard)
* [Full Code Example](#example)

<!-- TOC end -->

## <a id="important-note"> ⚠️ ⚠️ Important Note ⚠️ ⚠️

The Purchase Connector feature of the AppsFlyer SDK depends on specific libraries provided by Google and Apple for managing in-app purchases:

-   For Android, it depends on the  [Google Play Billing Library](https://developer.android.com/google/play/billing/integrate) (Supported versions: 5.x.x - 6.x.x).
-   For iOS, it depends on  [StoreKit](https://developer.apple.com/documentation/storekit). (Supported version is StoreKit V1)

However, these dependencies aren't actively included with the SDK. This means that the responsibility of managing these dependencies and including the necessary libraries in your project falls on you as the consumer of the SDK.

If you're implementing in-app purchases in your app, you'll need to ensure that the Google Play Billing Library (for Android) or StoreKit (for iOS) are included in your project. You can include these libraries manually in your native code, or you can use a third-party Flutter plugin, such as the  [`in_app_purchase`](https://pub.dev/packages/in_app_purchase)  plugin.

Remember to appropriately manage these dependencies when implementing the Purchase Validation feature in your app. Failing to include the necessary libraries might result in failures when attempting to conduct in-app purchases or validate purchases.

## <a id="install-connector">  Adding The Connector To Your Project

The Purchase Connector feature in AppsFlyer SDK Flutter Plugin is an optional enhancement that you can choose to use based on your requirements. This feature is not included by default and you'll have to opt-in if you wish to use it.

### How to Opt-In

To opt-in and include this feature in your app, you need to set specific properties based on your platform:

For **iOS**, in your Podfile located within the `iOS` folder of your Flutter project, set `$AppsFlyerPurchaseConnector` to `true`.
```ruby
$AppsFlyerPurchaseConnector = true
```
For **Android**, in your `gradle.properties` file located within the `Android` folder of your Flutter project,, set `appsflyer.enable_purchase_connector` to `true`.
```groovy
appsflyer.enable_purchase_connector=true
```
Once you set these properties, the Purchase Validation feature will be integrated into your project and you can utilize its functionality in your app.

### What Happens if You Use Dart Files Without Opting In?

The Dart files for the Purchase Validation feature are always included in the plugin. If you try to use these Dart APIs without opting into the feature, the APIs will not have effect because the corresponding native code necessary for them to function will not be included in your project.

In such cases, you'll likely experience errors or exceptions when trying to use functionalities provided by the Purchase Validation feature. To avoid these issues, ensure that you opt-in to the feature if you intend to use any related APIs.

## <a id="basic-integration"> Basic Integration Of The Connector
### <a id="create-instance"> Create PurchaseConnector Instance
The `PurchaseConnector` requires a configuration object of type `PurchaseConnectorConfiguration` at instantiation time. This configuration object governs how the `PurchaseConnector` behaves in your application.

To properly set up the configuration object, you must specify certain parameters:

- `logSubscriptions`: If set to `true`, the connector logs all subscription events.
- `logInApps`: If set to `true`, the connector logs all in-app purchase events.
- `sandbox`: If set to `true`, transactions are tested in a sandbox environment. Be sure to set this to `false` in production.

Here's an example usage:

```dart
void main() {
  final afPurchaseClient = PurchaseConnector(
    config: PurchaseConnectorConfiguration(
      logSubscriptions: true,   // Enables logging of subscription events
      logInApps: true,          // Enables logging of in-app purchase events
      sandbox: true,            // Enables testing in a sandbox environment
    ),
  );

  // Continue with your application logic...
}
```

**IMPORTANT**: The `PurchaseConnectorConfiguration` is required only the first time you instantiate `PurchaseConnector`. If you attempt to create a `PurchaseConnector` instance and no instance has been initialized yet, you must provide a `PurchaseConnectorConfiguration`. If an instance already exists, the system will ignore the configuration provided and will return the existing instance to enforce the singleton pattern.

For example:

```dart
void main() {
  // Correct usage: Providing configuration at first instantiation
  final purchaseConnector1 = PurchaseConnector(
    config: PurchaseConnectorConfiguration(
      logSubscriptions: true,
      logInApps: true,
      sandbox: true,
    ),
  );

  // Additional instantiations will ignore the provided configuration
  // and will return the previously created instance.
  final purchaseConnector2 = PurchaseConnector(
    config: PurchaseConnectorConfiguration(
      logSubscriptions: false,
      logInApps: false,
      sandbox: false,
    ),
  );

  // purchaseConnector1 and purchaseConnector2 point to the same instance
  assert(purchaseConnector1 == purchaseConnector2);
}
```

Thus, always ensure that the initial configuration fully suits your requirements, as subsequent changes are not considered.

Remember to set `sandbox` to `false` before releasing your app to production. If the production purchase event is sent in sandbox mode, your event won't be validated properly by AppsFlyer.
### <a id="start"> Start Observing Transactions
Start the SDK instance to observe transactions. </br>

**⚠️ Please Note**
> This should be called right after calling the `AppsflyerSdk` [start](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/blob/master/doc/BasicIntegration.md#startsdk).
>  Calling `startObservingTransactions` activates a listener that automatically observes new billing transactions. This includes new and existing subscriptions and new in app purchases.
>  The best practice is to activate the listener as early as possible.
```dart
        // start
        afPurchaseClient.startObservingTransactions();
```

### <a id="stop"> Stop Observing Transactions
Stop the SDK instance from observing transactions. </br>
**⚠️ Please Note**
> This should be called if you would like to stop the Connector from listening to billing transactions. This removes the listener and stops observing new transactions.
> An example for using this API is if the app wishes to stop sending data to AppsFlyer due to changes in the user's consent (opt-out from data sharing). Otherwise, there is no reason to call this method.
> If you do decide to use it, it should be called right before calling the Android SDK's [`stop`](https://dev.appsflyer.com/hc/docs/android-sdk-reference-appsflyerlib#stop) API

```dart
        // start
        afPurchaseClient.stopObservingTransactions();
```

### <a id="log-subscriptions"> Log Subscriptions
Enables automatic logging of subscription events. </br>
Set true to enable, false to disable.</br>
If this field is not used,  by default, the connector will not record Subscriptions.</br>
```dart
final afPurchaseClient = PurchaseConnector(  
    config: PurchaseConnectorConfiguration(logSubscriptions: true));
```

### <a id="log-inapps"> Log In App Purchases
Enables automatic logging of In-App purchase events</br>
Set true to enable, false to disable.</br>
If this field is not used,  by default, the connector will not record In App Purchases.</br>

```dart
final afPurchaseClient = PurchaseConnector(  
    config: PurchaseConnectorConfiguration(logInApps: true));
```


##  <a id="validation-callbacks"> Register Validation Results Listeners
You can register listeners to get the validation results once getting a response from AppsFlyer servers to let you know if the purchase was validated successfully.</br>

### <a id="cross-platform-considerations">  Cross-Platform Considerations

The AppsFlyer SDK Flutter plugin acts as a bridge between your Flutter app and the underlying native SDKs provided by AppsFlyer. It's crucial to understand that the native infrastructure of iOS and Android is quite different, and so is the AppsFlyer SDK built on top of them. These differences are reflected in how you would handle callbacks separately for each platform.

In the iOS environment, there is a single callback method  `didReceivePurchaseRevenueValidationInfo`  to handle both subscriptions and in-app purchases. You set this callback using  `setDidReceivePurchaseRevenueValidationInfo`.

On the other hand, Android segregates callbacks for subscriptions and in-app purchases. It provides two separate listener methods -  `setSubscriptionValidationResultListener`  for subscriptions and  `setInAppValidationResultListener`  for in-app purchases. These listener methods register callback handlers for  `OnResponse`  (executed when a successful response is received) and  `OnFailure`  (executed when a failure occurs, including due to a network exception or non-200/OK response from the server).

By splitting the callbacks, you can ensure platform-specific responses and tailor your app's behavior accordingly. It's crucial to consider these nuances to ensure a smooth integration of AppsFlyer SDK into your Flutter application.

### <a id="android-callback-types"> Android Callback Types

| Listener Method               | Description  |
|-------------------------------|--------------|
| `onResponse(result: Result?)` | Invoked when we got 200 OK response from the server (INVALID purchase is considered to be successful response and will be returned to this callback) |
|`onFailure(result: String, error: Throwable?)`|Invoked when we got some network exception or non 200/OK response from the server.|

### <a id="ars-validation-callbacks"> Android - Subscription Validation Result Listener

```dart
// set listeners for Android  
afPurchaseClient.setSubscriptionValidationResultListener(  
    (Map<String, SubscriptionValidationResult>? result) {  
  // handle subscription validation result for Android  
}, (String result, JVMThrowable? error) {  
  // handle subscription validation error for Android  
});
```

### <a id="inapps-validation-callbacks"> Android In Apps Validation Result Listener
```dart
afPurchaseClient.setInAppValidationResultListener(  
        (Map<String, InAppPurchaseValidationResult>? result) {  
      // handle in-app validation result for Android  
  }, (String result, JVMThrowable? error) {  
  // handle in-app validation error for Android  
});
```

### <a id="ios-callback"> iOS Combined  Validation Result Listener
```dart
afPurchaseClient.setDidReceivePurchaseRevenueValidationInfo((validationInfo, error) {  
  // handle subscription and in-app validation result and errors for iOS  
});
```


## <a id="testing"> Testing the Integration

With the AppsFlyer SDK, you can select which environment will be used for validation - either **production** or **sandbox**. By default, the environment is set to production. However, while testing your app, you should use the sandbox environment.

### <a id="testing-android"> Android

For Android, testing your integration with the [Google Play Billing Library](https://developer.android.com/google/play/billing/test) should use the sandbox environment.

To set the environment to sandbox in Flutter, just set the `sandbox` parameter in the `PurchaseConnectorConfiguration` to `true` when instantiating `PurchaseConnector`.

Remember to switch the environment back to production (set `sandbox` to `false`) before uploading your app to the Google Play Store.

### <a id="testing-ios"> iOS

To test purchases in an iOS environment on a real device with a TestFlight sandbox account, you also need to set `sandbox` to `true`.

> *IMPORTANT NOTE: Before releasing your app to production please be sure to set `sandbox` to `false`. If a production purchase event is sent in sandbox mode, your event will not be validated properly! *

### <a id="testing-config"> Dart Usage for Android and iOS

For both Android and iOS, you can set the sandbox environment using the `sandbox` parameter in the `PurchaseConnectorConfiguration` when you instantiate `PurchaseConnector` in your Dart code like this:

```dart
// Testing in a sandbox environment
final purchaseConnector = PurchaseConnector(
  PurchaseConnectorConfiguration(sandbox: true)
);
```

Remember to set `sandbox` back to `false` before releasing your app to production. If the production purchase event is sent in sandbox mode, your event won't be validated properly.

## <a id="proguard">  ProGuard Rules for Android

If you are using ProGuard to obfuscate your APK for Android, you need to ensure that it doesn't interfere with the functionality of AppsFlyer SDK and its Purchase Connector feature.

Add following keep rules to your  `proguard-rules.pro`  file:

```groovy
-keep  class  com.appsflyer.** { *; }  
-keep  class  kotlin.jvm.internal.Intrinsics{ *; }  
-keep  class  kotlin.collections.**{ *; }
```

## <a id="example"> Full Code Example
```dart
PurchaseConnectorConfiguration config = PurchaseConnectorConfiguration(  
    logSubscriptions: true, logInApps: true, sandbox: false);  
final afPurchaseClient = PurchaseConnector(config: config);  
  
// set listeners for Android  
afPurchaseClient.setSubscriptionValidationResultListener(  
    (Map<String, SubscriptionValidationResult>? result) {  
  // handle subscription validation result for Android  
  result?.entries.forEach((element) {  
    debugPrint(  
        "Subscription Validation Result\n\t Token: ${element.key}\n\tresult: ${jsonEncode(element.value.toJson())}");  
  });  
}, (String result, JVMThrowable? error) {  
  // handle subscription validation error for Android  
  var errMsg = error != null ? jsonEncode(error.toJson()) : null;  
  debugPrint(  
      "Subscription Validation Result\n\t result: $result\n\terror: $errMsg");  
});  
  
afPurchaseClient.setInAppValidationResultListener(  
    (Map<String, InAppPurchaseValidationResult>? result) {  
  // handle in-app validation result for Android  
  result?.entries.forEach((element) {  
    debugPrint(  
        "In App Validation Result\n\t Token: ${element.key}\n\tresult: ${jsonEncode(element.value.toJson())}");  
  });  
}, (String result, JVMThrowable? error) {  
  // handle in-app validation error for Android  
  var errMsg = error != null ? jsonEncode(error.toJson()) : null;  
  debugPrint(  
      "In App Validation Result\n\t result: $result\n\terror: $errMsg");  
});  
  
// set listener for iOS  
afPurchaseClient  
    .setDidReceivePurchaseRevenueValidationInfo((validationInfo, error) {  
  var validationInfoMsg =  
      validationInfo != null ? jsonEncode(validationInfo) : null;  
  var errMsg = error != null ? jsonEncode(error.toJson()) : null;  
  debugPrint(  
      "iOS Validation Result\n\t validationInfo: $validationInfoMsg\n\terror: $errMsg");  
  // handle subscription and in-app validation result and errors for iOS  
});  
  
// start  
afPurchaseClient.startObservingTransactions();
```