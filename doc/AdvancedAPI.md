# 📑 Advanced APIs

- [Measure App Uninstalls](#uninstall)
- [User invite](#user-invite)
- [In-app purchase validation](#iae)
- [Android Out of Store](#out-of-store)
- [Set plugin for IOS 14](#ios14)

---

## <a id="uninstall"> Measure App Uninstalls

### iOS

You may update the uninstall token from the native side and from the plugin side, as shown in the methods below, you do not have to implement both of the methods, but only one.
You can read more about iOS Uninstall Measurement in our [knowledge base](https://support.appsflyer.com/hc/en-us/articles/4408933557137) and you can follow our guide for Uninstall measurement on our [DevHub](https://dev.appsflyer.com/hc/docs/uninstall-measurement-ios).

#### First method

You can register the uninstall token with AppsFlyer by modifying your `AppDelegate.m` file, add the following function call with your uninstall token inside [didRegisterForRemoteNotificationsWithDeviceToken](https://developer.apple.com/reference/uikit/uiapplicationdelegate).

**Example:**

```objective-c
@import AppsFlyerLib;

...

- (void)application:(UIApplication ​*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *​)deviceToken {
// notify AppsFlyerLib
 [[AppsFlyerLib shared] registerUninstall:deviceToken];
}
```

#### Second method

You can register the uninstall token with AppsFlyer by calling the following API with your uninstall token:
```dart
appsFlyerSdk.updateServerUninstallToken("token");
```

> **Note:** When using this method on iOS, the token should be passed as a **hexadecimal string representation** of the device token. The plugin will automatically convert the hex string to the required `NSData` format for the AppsFlyer SDK.
>
> If you're using the [firebase_messaging](https://pub.dev/packages/firebase_messaging) plugin, you can get the APNs token on iOS using `FirebaseMessaging.instance.getAPNSToken()` which returns the token as a hex string, which is the expected format for this method.

### Android

It is possible to utilize the [Firebase Messaging Plugin for Flutter](https://pub.dev/packages/firebase_messaging) for everything related to the uninstall token.
You can read more about Android Uninstall Measurement in our [knowledge base](https://support.appsflyer.com/hc/en-us/articles/4408933557137) and you can follow our guide for Uninstall measurement using FCM on our [DevHub](https://dev.appsflyer.com/hc/docs/uninstall-measurement-android).

On the Flutter side, you can register the uninstall token with AppsFlyer by calling the following API with your uninstall token:
```dart
appsFlyerSdk.updateServerUninstallToken("token");
```

**Example using Firebase Messaging (cross-platform):**
```dart
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';

// Update uninstall token for AppsFlyer
void _updateUninstallToken(appsFlyerSdk) {
  if (Platform.isAndroid) {
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        appsFlyerSdk.updateServerUninstallToken(token);
      }
    });
  } else if (Platform.isIOS) {
    FirebaseMessaging.instance.getAPNSToken().then((token) {
      if (token != null) {
        appsFlyerSdk.updateServerUninstallToken(token);
      }
    });
  }
}
```
**Note:**  
- On Android, `getToken()` returns the FCM token.  
- On iOS, `getAPNSToken()` returns the APNs token as a hex string, suitable for `updateServerUninstallToken`.  
- Replace `appsFlyerSdk` with your instance of `AppsflyerSdk`.

---

## <a id="user-invite"> User invite

A complete list of supported parameters is available [here](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-Invite-Tracking), you can also make use of the `customParams` field to include custom parameters of your choice.

1. First define the Onelink ID either in the AppsFlyerOptions, or in the setAppInviteOneLinkID API (find it in the AppsFlyer dashboard in the onelink section):

  **`Future<void> setAppInviteOneLinkID(String oneLinkID, Function callback)`**

2. Utilize the AppsFlyerInviteLinkParams class to set the query params in the user invite link:

```dart
class AppsFlyerInviteLinkParams {
  final String channel;
  final String campaign;
  final String referrerName;
  final String referrerImageUrl;
  final String customerID;
  final String baseDeepLink;
  final String brandDomain;
  final Map<String?, String?>? customParams;
}
```

3. Call the generateInviteLink API to generate the user invite link. Use the success and error callbacks for handling.

**Full example:**

```dart
// Setting the OneLinkID
appsFlyerSdk.setAppInviteOneLinkID('OnelinkID', 
(res){ 
  print("setAppInviteOneLinkID callback: $res"); 
});

// Creating the required parameters of the OneLink
AppsFlyerInviteLinkParams inviteLinkParams = new AppsFlyerInviteLinkParams(
      channel: "",
      referrerName: "",
      baseDeepLink: "",
      brandDomain: "",
      customerID: "",
      referrerImageUrl: "",
      campaign: "",
      customParams: {"key":"value"}
);

// Generating the OneLink
appsFlyerSdk.generateInviteLink(inviteLinkParams, 
  (result){ 
    print(result); 
  }, 
  (error){ 
    print(error);
  }
);
```

---

### <a id="iae"> In-app purchase validation
Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.<br>
Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases<br>

**Cross-Platform V2 API (Recommended - SDK v6.17.3+):**

The unified purchase validation API that works across both Android and iOS platforms:

```dart
Future<Map<String, dynamic>> validateAndLogInAppPurchaseV2(
      AFPurchaseDetails purchaseDetails,
      {Map<String, String>? additionalParameters})
```

**AFPurchaseDetails class:**
```dart
AFPurchaseDetails(
  purchaseType: AFPurchaseType,    // oneTimePurchase or subscription
  purchaseToken: String,           // Purchase token from app store
  productId: String,               // Product identifier
)
```

**Example:**
```dart
// Create purchase details
AFPurchaseDetails purchaseDetails = AFPurchaseDetails(
  purchaseType: AFPurchaseType.oneTimePurchase,
  purchaseToken: "sample_purchase_token_12345",
  productId: "com.example.product",
);

// Validate purchase (works on both Android and iOS)
try {
  Map<String, dynamic> result = await appsFlyerSdk.validateAndLogInAppPurchaseV2(
    purchaseDetails,
    additionalParameters: {"custom_param": "value"}
  );
  print("Validation successful: $result");
} on PlatformException catch (e) {
  // Handle platform-specific errors with detailed information
  print("Validation failed: ${e.message}");
  print("Error code: ${e.code}");
  if (e.details != null) {
    // Access detailed error information
    final details = e.details as Map<String, dynamic>;
    print("Error details: $details");
    // On iOS, additional fields may include:
    // - error_code: The NSError code
    // - error_domain: The NSError domain
    // - error_user_info: Additional error context
  }
} catch (e) {
  print("Unexpected error: $e");
}
```

**Benefits of V2 API:**
- ✅ **Cross-platform**: Single API works on both Android and iOS
- ✅ **Type-safe**: Uses structured data classes instead of raw strings
- ✅ **Comprehensive error handling**: Returns structured error information including NSError details on iOS
- ✅ **Enhanced validation**: Uses AppsFlyer's latest validation infrastructure
- ✅ **Future-proof**: Built for AppsFlyer's V2 validation endpoints

---

**Deprecated Platform-Specific APIs:**

> ⚠️ **Deprecated**: The following platform-specific APIs are deprecated and will be removed in a future version. Please migrate to `validateAndLogInAppPurchaseV2` for cross-platform support.

**Android (Deprecated):**
```dart
@Deprecated('Use validateAndLogInAppPurchaseV2 instead')
Future<dynamic> validateAndLogInAppAndroidPurchase( 
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String>? additionalParameters)
```
Example:
```dart
// Deprecated - migrate to validateAndLogInAppPurchaseV2
appsFlyerSdk.validateAndLogInAppAndroidPurchase(
           "publicKey",
           "signature",
           "purchaseData",
           "price",
           "currency",
           {"fs": "fs"});
```

**iOS (Deprecated):**

❗Important❗ for iOS - set SandBox to ```true```<br>
```appsFlyer.useReceiptValidationSandbox(true);```

```dart
@Deprecated('Use validateAndLogInAppPurchaseV2 instead')
Future<dynamic> validateAndLogInAppIosPurchase( 
      String productIdentifier,
      String price,
      String currency,
      String transactionId,
      Map<String, String> additionalParameters)
```

Example:
```dart
// Deprecated - migrate to validateAndLogInAppPurchaseV2
appsFlyerSdk.validateAndLogInAppIosPurchase(
           "productIdentifier",
           "price",
           "currency",
           "transactionId",
           {"fs": "fs"});
```

**Purchase validation callback:**

`void onPurchaseValidation(Function callback)`

Example:
```dart
appsflyerSdk.onPurchaseValidation((res){
  print("res: " + res.toString());
});
```

---

## <a id="out-of-store"> Android Out of Store
Please make sure to go over [this guide](https://support.appsflyer.com/hc/en-us/articles/207447023-Attributing-out-of-store-Android-markets-guide) to get a general understanding of how out of store attribution is set up in AppsFlyer, and how to implement it.

---

## <a id="ios14"> Set plugin for IOS 14
	
1. Adding the conset dialog:
	
There are 2 ways to add it to your app:
	
	a. Utilize the following Library: https://pub.dev/packages/app_tracking_transparency

Or 
	
	b. Add native implementation:

	
- Add `#import <AppTrackingTransparency/AppTrackingTransparency.h>` in your `AppDelegate.m` 

- Add the ATT pop-up for IDFA collection so your `AppDelegate.m` will look like this:
	
```
- (void)applicationDidBecomeActive:(nonnull UIApplication *)application {
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            // native code here
        }];
    }
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

For more info visit our [Full Support guide for iOS 14](https://support.appsflyer.com/hc/en-us/articles/207032066#integration-33-configuring-app-tracking-transparency-att-support).