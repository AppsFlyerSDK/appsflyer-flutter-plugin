
# Purchase Connector

> **Audience:** apps measuring in-app purchase / subscription revenue. Requires the [core setup](getting-started.md). **iOS: CocoaPods only — not compatible with Swift Package Manager.**

**At a glance:** Automatically validate and measure revenue from in-app purchases and auto-renewable subscriptions to get the full picture of your customers' life cycles and accurate ROAS measurements.

> Purchase Connector requires an ROI360 subscription. When Purchase Connector
> reports purchase revenue, do not also send the same purchase through
> `validateAndLogInAppPurchase` or an in-app event containing revenue, because
> doing so can result in duplicate revenue reporting.

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
  - [How to Opt-In](#how-to-opt-in)
  - [What Happens if You Use Dart Files Without Opting In?](#what-happens-if-you-use-dart-files-without-opting-in)
* [Basic Integration Of The Connector](#basic-integration)
  - [Create PurchaseConnector Instance](#create-instance)
  - [Start Observing Transactions](#start)
  - [Stop Observing Transactions](#stop)
  - [Log Subscriptions](#log-subscriptions)
  - [Log In App Purchases](#log-inapps)
* [StoreKit Version Configuration (iOS)](#storekit-configuration)
  - [Available StoreKit Versions](#storekit-versions)
  - [Configuration Examples](#storekit-examples)
  - [StoreKit 2 Benefits and Requirements](#storekit-notes)
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

Plugin `7.0.2` resolves Android Purchase Connector `2.2.0` and iOS Purchase
Connector `7.0.2` when the feature is enabled. Android Purchase Connector
`2.2.0` supports Google Play Billing Library `8.x`. The Flutter plugin does
not add the Billing Library itself, so your app or IAP plugin must provide a
Billing Library `8.x` dependency and use Billing 8-compatible APIs.

The Purchase Connector feature of the AppsFlyer SDK depends on specific libraries provided by Google and Apple for managing in-app purchases:

-   For Android, it depends on the [Google Play Billing Library](https://developer.android.com/google/play/billing/integrate) `8.x`.
-   For iOS, it observes transactions from the system [StoreKit](https://developer.apple.com/documentation/storekit) framework. StoreKit 1 and StoreKit 2 are supported.

The Purchase Connector observes purchases; it does not implement your app's
purchase flow. Provide that flow in native application code or with a Flutter
plugin such as [`in_app_purchase`](https://pub.dev/packages/in_app_purchase).

Remember to appropriately manage these dependencies when implementing Purchase
Connector. Failing to provide the required purchase framework can prevent the
app from conducting or validating purchases.

## <a id="install-connector">  Adding The Connector To Your Project

The Purchase Connector feature in AppsFlyer SDK Flutter Plugin is an optional enhancement that you can choose to use based on your requirements. This feature is not included by default and you'll have to opt-in if you wish to use it.

### How to Opt-In

To opt-in and include this feature in your app, you need to set specific properties based on your platform:

For **iOS**, in your Podfile located within the `ios` folder of your Flutter project, set `$AppsFlyerPurchaseConnector` to `true`.
```ruby
$AppsFlyerPurchaseConnector = true
```
For **Android**, in your `gradle.properties` file located within the `android` folder of your Flutter project, set `appsflyer.enable_purchase_connector` to `true`.
```groovy
appsflyer.enable_purchase_connector=true
```
Once you set these properties and rebuild the app, Purchase Connector will be integrated into your project and you can utilize its functionality in your app.

> ⚠️ **iOS + Swift Package Manager**: Purchase Connector requires **CocoaPods for the entire plugin** — there is no Swift Package Manager path for it, and it cannot currently be combined with Swift Package Manager for the Core integration either. This is a temporary limitation pending an upstream Flutter fix ([flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182)). **If your app uses Purchase Connector, do not enable Swift Package Manager for this plugin — keep your `Podfile` and use CocoaPods for both Core and Purchase Connector.** If you enable SPM anyway, calling any Purchase Connector API throws `MissingPluginException` — see the next section. SPM is only recommended for apps that don't use Purchase Connector at all (see [installation-guide.md](installation-guide.md#ios-swift-package-manager-spm-support)).

### What Happens if You Use Dart Files Without Opting In?

The Dart files for Purchase Connector are always included in the plugin. If you try to use these Dart APIs without opting into the feature, the corresponding native code is not included and calling any Purchase Connector API throws `MissingPluginException`.

In such cases, you'll experience errors when invoking native Purchase Connector operations. To avoid these issues, ensure that you opt in to the feature if you intend to use it.

## <a id="basic-integration"> Basic Integration Of The Connector
### <a id="create-instance"> Create PurchaseConnector Instance
The `PurchaseConnector` requires a configuration object of type `PurchaseConnectorConfiguration` at instantiation time. This configuration object governs how the `PurchaseConnector` behaves in your application.

The configuration object has the following optional parameters:

- `logSubscriptions`: If set to `true`, the connector logs all subscription events.
- `logInApps`: If set to `true`, the connector logs all in-app purchase events.
- `sandbox`: If set to `true`, transactions are tested in a sandbox environment. Be sure to set this to `false` in production.
- `storeKitVersion`: (iOS only) Specifies which StoreKit version to use. Defaults to `StoreKitVersion.SK1` if not specified.

Here's an example usage:

```dart
void main() {
  final afPurchaseClient = PurchaseConnector(
    config: PurchaseConnectorConfiguration(
      logSubscriptions: true,   // Enables logging of subscription events
      logInApps: true,          // Enables logging of in-app purchase events
      sandbox: true,            // Enables testing in a sandbox environment
      storeKitVersion: StoreKitVersion.SK1,  // iOS only: StoreKit version (defaults to SK1)
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
      storeKitVersion: StoreKitVersion.SK1,  // Default StoreKit version
    ),
  );

  // Additional instantiations will ignore the provided configuration
  // and will return the previously created instance.
  final purchaseConnector2 = PurchaseConnector(
    config: PurchaseConnectorConfiguration(
      logSubscriptions: false,
      logInApps: false,
      sandbox: false,
      storeKitVersion: StoreKitVersion.SK2,  // This will be ignored
    ),
  );

  // purchaseConnector1 and purchaseConnector2 point to the same instance
  assert(purchaseConnector1 == purchaseConnector2);
}
```

Thus, always ensure that the initial configuration fully suits your requirements, as subsequent changes are not considered.

Remember to set `sandbox` to `false` before releasing your app to production. If the production purchase event is sent in sandbox mode, your event won't be validated properly by AppsFlyer.
### <a id="start"> Start Observing Transactions
Start Purchase Connector to observe transactions. </br>

**⚠️ Please Note**
> This should be called right after calling `AppsFlyerSdk` [start](getting-started.md#start).
>  Calling `startObservingTransactions` activates a listener that automatically observes new billing transactions. This includes new and existing subscriptions and new in app purchases.
>  The best practice is to activate the listener as early as possible.
```dart
        // start
        afPurchaseClient.startObservingTransactions();
```

### <a id="stop"> Stop Observing Transactions
Stop Purchase Connector from observing transactions. </br>
**⚠️ Please Note**
> This should be called if you would like to stop the Connector from listening to billing transactions. This removes the listener and stops observing new transactions.
> An example for using this API is if the app wishes to stop sending data to AppsFlyer due to changes in the user's consent (opt-out from data sharing). Otherwise, there is no reason to call this method.
> If you do decide to use it, it should be called right before calling the Android SDK's [`stop`](https://dev.appsflyer.com/hc/docs/android-sdk-reference-appsflyerlib#stop) API

```dart
        // stop
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

## <a id="storekit-configuration"> StoreKit Version Configuration (iOS)

The Purchase Connector supports both StoreKit 1 and StoreKit 2 on iOS. You can configure which version to use via the `storeKitVersion` parameter in `PurchaseConnectorConfiguration`.

### <a id="storekit-versions"> Available StoreKit Versions

- **`StoreKitVersion.SK1`** (Default) - Uses the original StoreKit framework
- **`StoreKitVersion.SK2`** - Uses the modern StoreKit 2 framework (iOS 15.0+)

### <a id="storekit-examples"> Configuration Examples

**Using StoreKit 1 (Default):**
```dart
final afPurchaseClient = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    logSubscriptions: true,
    logInApps: true,
    sandbox: true,
    // StoreKit 1 is used by default, no need to specify
  ),
);
```

**Explicitly Using StoreKit 1:**
```dart
final afPurchaseClient = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    logSubscriptions: true,
    logInApps: true,
    sandbox: true,
    storeKitVersion: StoreKitVersion.SK1,  // Explicitly set to StoreKit 1
  ),
);
```

**Using StoreKit 2:**
```dart
final afPurchaseClient = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    logSubscriptions: true,
    logInApps: true,
    sandbox: true,
    storeKitVersion: StoreKitVersion.SK2,  // Use modern StoreKit 2
  ),
);
```

### <a id="storekit-notes"> StoreKit 2 Benefits and Requirements

**Benefits of StoreKit 2:**
- ✅ **Modern API**: Built with Swift's async/await patterns
- ✅ **Better Performance**: More efficient transaction processing
- ✅ **Enhanced Features**: Improved subscription management and transaction handling
- ✅ **Future-Proof**: Apple's recommended approach for new apps

**Requirements:**
- 📱 **iOS 15.0+**: StoreKit 2 requires iOS 15.0 or later
- 🔄 **Backward Compatibility**: Falls back to StoreKit 1 on older iOS versions automatically
- 🧪 **Testing**: Thoroughly test on your target iOS versions

**Example with Error Handling:**
```dart
final afPurchaseClient = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    logSubscriptions: true,
    logInApps: true,
    sandbox: true,
    storeKitVersion: StoreKitVersion.SK2,
  ),
);

// Start observing transactions
afPurchaseClient.startObservingTransactions();
```

> 📝 **Note**: If you don't specify `storeKitVersion`, the connector defaults
> to `StoreKitVersion.SK1`. When `StoreKitVersion.SK2` is selected, the
> connector uses StoreKit 2 on iOS 15.0 and later and automatically falls back
> to StoreKit 1 on iOS 13 and 14. The app does not need to implement this
> fallback.

##  <a id="validation-callbacks"> Register Validation Results Listeners
You can register listeners to get the validation results once getting a response from AppsFlyer servers to let you know if the purchase was validated successfully.</br>

### <a id="cross-platform-considerations">  Cross-Platform Considerations

The Flutter plugin provides a common API, but purchase callbacks differ between
iOS and Android. Handle the callback model for the platform your app is running
on.

In the iOS environment, there is a single callback method  `didReceivePurchaseRevenueValidationInfo`  to handle both subscriptions and in-app purchases. You set this callback using  `setDidReceivePurchaseRevenueValidationInfo`.

On the other hand, Android segregates callbacks for subscriptions and in-app purchases. It provides two separate listener methods -  `setSubscriptionValidationResultListener`  for subscriptions and  `setInAppValidationResultListener`  for in-app purchases. These listener methods register callback handlers for  `OnResponse`  (executed when a successful response is received) and  `OnFailure`  (executed when a failure occurs, including due to a network exception or non-200/OK response from the server).

By splitting the callbacks, you can ensure platform-specific responses and tailor your app's behavior accordingly. It's crucial to consider these nuances to ensure a smooth integration of AppsFlyer SDK into your Flutter application.

### <a id="android-callback-types"> Android Callback Types

| Listener Method               | Description  |
|-------------------------------|--------------|
| `onResponse(result: Result?)` | Invoked when we got 200 OK response from the server (INVALID purchase is considered to be successful response and will be returned to this callback) |
|`onFailure(result: String, error: Throwable?)`|Invoked when we got some network exception or non 200/OK response from the server, or when a validation payload cannot be parsed.|

Every field of the validation-result models is nullable, because the Google Play
Developer API omits any field that is absent or left at its default value. Read
them with `?.` rather than `!`. If a payload cannot be parsed at all, `onFailure`
is invoked with a `result` string naming the callback and the error type — the
payload itself is never included, since it carries purchase and account
identifiers.

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

**StoreKit Version Considerations for Testing:**
- **StoreKit 1**: Works on all iOS versions, well-established testing procedures
- **StoreKit 2**: Used on iOS 15.0+; older supported iOS versions automatically fall back to StoreKit 1

```dart
// Example configuration for testing with StoreKit 2
final purchaseConnector = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    sandbox: true,  // Enable sandbox for testing
    storeKitVersion: StoreKitVersion.SK2,
    logSubscriptions: true,
    logInApps: true,
  ),
);
```

> *IMPORTANT NOTE: Before releasing your app to production please be sure to set `sandbox` to `false`. If a production purchase event is sent in sandbox mode, your event will not be validated properly!*

### <a id="testing-config"> Dart Usage for Android and iOS

For both Android and iOS, you can set the sandbox environment using the `sandbox` parameter in the `PurchaseConnectorConfiguration` when you instantiate `PurchaseConnector` in your Dart code like this:

```dart
// Testing in a sandbox environment with StoreKit 1 (default)
final purchaseConnector = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    sandbox: true,
    logSubscriptions: true,
    logInApps: true,
    // storeKitVersion defaults to StoreKitVersion.SK1
  )
);

// Prefer StoreKit 2 in the sandbox (used on iOS 15.0+)
final purchaseConnectorSK2 = PurchaseConnector(
  config: PurchaseConnectorConfiguration(
    sandbox: true,
    logSubscriptions: true,
    logInApps: true,
    storeKitVersion: StoreKitVersion.SK2,  // Enhanced testing capabilities
  )
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
-keep  class  kotlin.Result$Companion { *; }
```

## <a id="example"> Full Code Example
```dart
import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

void configurePurchaseConnector() {
  final config = PurchaseConnectorConfiguration(
    logSubscriptions: true,
    logInApps: true,
    sandbox: false,
    storeKitVersion: StoreKitVersion.SK2, // Uses SK2 on iOS 15+; SK1 on iOS 13-14
  );
  final afPurchaseClient = PurchaseConnector(config: config);

  // Set listeners for Android.
  afPurchaseClient.setSubscriptionValidationResultListener(
      (Map<String, SubscriptionValidationResult>? result) {
    // Handle subscription validation result for Android.
    result?.entries.forEach((element) {
      debugPrint(
          "Subscription Validation Result\n\t Token: ${element.key}\n\tresult: ${jsonEncode(element.value.toJson())}");
    });
  }, (String result, JVMThrowable? error) {
    // Handle subscription validation error for Android.
    final errMsg = error != null ? jsonEncode(error.toJson()) : null;
    debugPrint(
        "Subscription Validation Result\n\t result: $result\n\terror: $errMsg");
  });

  afPurchaseClient.setInAppValidationResultListener(
      (Map<String, InAppPurchaseValidationResult>? result) {
    // Handle in-app validation result for Android.
    result?.entries.forEach((element) {
      debugPrint(
          "In App Validation Result\n\t Token: ${element.key}\n\tresult: ${jsonEncode(element.value.toJson())}");
    });
  }, (String result, JVMThrowable? error) {
    // Handle in-app validation error for Android.
    final errMsg = error != null ? jsonEncode(error.toJson()) : null;
    debugPrint(
        "In App Validation Result\n\t result: $result\n\terror: $errMsg");
  });

  // Set listener for iOS.
  afPurchaseClient
      .setDidReceivePurchaseRevenueValidationInfo((validationInfo, error) {
    final validationInfoMsg =
        validationInfo != null ? jsonEncode(validationInfo) : null;
    final errMsg = error != null ? jsonEncode(error.toJson()) : null;
    debugPrint(
        "iOS Validation Result\n\t validationInfo: $validationInfoMsg\n\terror: $errMsg");
    // Handle subscription and in-app validation results and errors for iOS.
  });

  afPurchaseClient.startObservingTransactions();
}
```
