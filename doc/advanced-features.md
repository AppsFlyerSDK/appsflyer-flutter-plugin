# 📑 Advanced features

Optional features you add on top of the [core setup](getting-started.md). Adopt only the
ones your app needs.

> **Audience:** teams adding uninstall measurement, user invites, purchase validation, or
> out-of-store attribution. For the full method list see the [API reference](api-reference.md).

- [Measure App Uninstalls](#uninstall)
- [User invite](#user-invite)
- [In-app purchase validation](#iae)
- [Android Out of Store](#out-of-store)

> **iOS 14 / ATT setup moved.** App Tracking Transparency configuration now lives in
> [Getting started → iOS 14 & App Tracking Transparency](getting-started.md#ios-14--app-tracking-transparency).

---

## <a id="uninstall"> Measure App Uninstalls

Flutter exposes one cross-platform API:
`updateServerUninstallToken(String token)`. Pass an FCM registration token on
Android or a hexadecimal APNs device token on iOS.

### iOS

You may update the uninstall token from the native side and from the plugin side, as shown in the methods below, you do not have to implement both of the methods, but only one.
You can read more about iOS Uninstall Measurement in our [knowledge base](https://support.appsflyer.com/hc/en-us/articles/4408933557137) and you can follow our guide for Uninstall measurement on our [DevHub](https://dev.appsflyer.com/hc/docs/uninstall-measurement-ios).

#### First method

You can register the uninstall token with AppsFlyer by modifying your `AppDelegate.m` file, add the following function call with your uninstall token inside [didRegisterForRemoteNotificationsWithDeviceToken](https://developer.apple.com/reference/uikit/uiapplicationdelegate).

**Example:**

```objective-c
@import AppsFlyerLib;

...

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // Notify AppsFlyerLib.
  [[AppsFlyerLib shared] registerUninstall:deviceToken];
}
```

#### Second method

You can register the uninstall token with AppsFlyer by calling the following API with your uninstall token:
```dart
await appsFlyerSdk.updateServerUninstallToken("0123456789abcdef");
```

> **Note:** When using this method on iOS, the token should be passed as a **hexadecimal string representation** of the device token. The plugin will automatically convert the hex string to the required `NSData` format for the AppsFlyer SDK.
>
> If you're using the [firebase_messaging](https://pub.dev/packages/firebase_messaging) plugin, you can get the APNs token on iOS using `FirebaseMessaging.instance.getAPNSToken()` which returns the token as a hex string, which is the expected format for this method.

### Android

It is possible to utilize the [Firebase Messaging Plugin for Flutter](https://pub.dev/packages/firebase_messaging) for everything related to the uninstall token.
You can read more about Android Uninstall Measurement in our [knowledge base](https://support.appsflyer.com/hc/en-us/articles/4408933557137) and you can follow our guide for Uninstall measurement using FCM on our [DevHub](https://dev.appsflyer.com/hc/docs/uninstall-measurement-android).

On the Flutter side, you can register the uninstall token with AppsFlyer by calling the following API with your uninstall token:
```dart
await appsFlyerSdk.updateServerUninstallToken("fcm-registration-token");
```

**Example using Firebase Messaging (cross-platform):**
```dart
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';

// Update uninstall token for AppsFlyer.
Future<void> _updateUninstallToken(AppsFlyerSdk appsFlyerSdk) async {
  if (Platform.isAndroid) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await appsFlyerSdk.updateServerUninstallToken(token);
    }
  } else if (Platform.isIOS) {
    final token = await FirebaseMessaging.instance.getAPNSToken();
    if (token != null) {
      await appsFlyerSdk.updateServerUninstallToken(token);
    }
  }
}
```
**Note:**  
- On Android, `getToken()` returns the FCM token.  
- On iOS, `getAPNSToken()` returns the APNs token as a hex string, suitable for `updateServerUninstallToken`.  
- Replace `appsFlyerSdk` with your `AppsFlyerSdk.instance` reference.

---

## <a id="user-invite"> User invite

A complete list of supported parameters is available [here](https://support.appsflyer.com/hc/en-us/articles/115004480866-User-Invite-Tracking), you can also make use of the `userParams` field to include custom parameters of your choice.

1. First define the OneLink ID with `setAppInviteOneLink` (find it in the AppsFlyer dashboard in the OneLink section):

  **`Future<void> setAppInviteOneLink(String oneLinkId)`**

2. Utilize the AppsFlyerInviteLinkParams class to set the query params in the user invite link:

```dart
class AppsFlyerInviteLinkParams {
  final String? channel;
  final String? campaign;
  final String? referrerName;
  final String? referrerImageUrl;
  final String? referrerCustomerId;
  final String? baseDeepLink;
  final String? brandDomain;
  final Map<String, String>? userParams;
}
```

3. Call `generateInviteLink` to generate the user invite link. The returned
   Future completes with the generated URL or throws `AppsFlyerException`.
   `awaitResponse` defaults to `true`. On Android, `false` returns the
   synchronously generated long link. On iOS, link generation always waits for
   the asynchronous result. Both platforms time out after 10 seconds.

4. Pass the generated URL to your app's share flow. After the user shares the
   invite, call `logInvite` with the same channel to log the `af_invite` event:

   **`Future<void> logInvite(String channel, [Map<String, String>? eventParameters])`**

   Do not call `logInvite` when the link is only generated; call it for the
   actual share action.

**Full example:**

```dart
// Setting the OneLink ID
await appsFlyerSdk.setAppInviteOneLink('OnelinkID');

// Creating the required parameters of the OneLink
const AppsFlyerInviteLinkParams inviteLinkParams = AppsFlyerInviteLinkParams(
      channel: "whatsapp",
      campaign: "summer_sale",
      userParams: {"key":"value"}
);

// Generating the OneLink
try {
  final url = await appsFlyerSdk.generateInviteLink(
    parameters: inviteLinkParams,
    awaitResponse: true,
  );

  // Pass url to your app's share UI.
  // After the user completes the share action:
  await appsFlyerSdk.logInvite(
    "whatsapp",
    {"campaign": "summer_sale"},
  );
} on AppsFlyerException catch (error) {
  print(error);
}
```

---

### <a id="iae"> In-app purchase validation
Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.<br>
Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases<br>

**Cross-platform API:**

The unified purchase validation API that works across both Android and iOS platforms:

```dart
Future<Map<String, dynamic>> validateAndLogInAppPurchase(
  AFPurchaseDetails purchase, {
  Map<String, String>? additionalParameters,
})
```

Both platforms always wait for the validation result: the Future completes with
it or throws `AppsFlyerException`. Android times out after 5 seconds, iOS after
30.

**AFPurchaseDetails interface and platform implementations:**
```dart
AFAndroidPurchaseDetails(
  purchaseType: AFPurchaseType,    // oneTimePurchase or subscription
  purchaseToken: String,           // Purchase token from app store
  productId: String,               // Product identifier
)

AFIOSPurchaseDetails(
  purchaseType: AFPurchaseType,    // oneTimePurchase or subscription
  transactionId: String,           // App Store transaction identifier
  productId: String,               // Product identifier
)
```

Passing an Android purchase-details object on iOS, or an iOS purchase-details
object on Android, throws `ArgumentError` before the native validation call.

**Example:**
```dart
import 'dart:io' show Platform;

final AFPurchaseDetails purchaseDetails = Platform.isAndroid
    ? const AFAndroidPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        purchaseToken: "sample_purchase_token_12345",
        productId: "com.example.product",
      )
    : const AFIOSPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        transactionId: "sample_transaction_id",
        productId: "com.example.product",
      );

// Validate purchase (works on both Android and iOS)
try {
  Map<String, dynamic> result = await appsFlyerSdk.validateAndLogInAppPurchase(
    purchaseDetails,
    additionalParameters: {"custom_param": "value"},
  );
  print("Validation successful: $result");
} on AppsFlyerException catch (error) {
  print("Validation failed: $error");
} on ArgumentError catch (error) {
  print("Invalid purchase details: $error");
}
```

**Benefits:**
- ✅ **Cross-platform**: Single API works on both Android and iOS
- ✅ **Type-safe**: Uses structured data classes instead of raw strings
- ✅ **Comprehensive error handling**: `AppsFlyerException` provides an optional numeric `code` and `message` for failed SDK calls
- ✅ **Enhanced validation**: Uses AppsFlyer's latest validation infrastructure
- ✅ **Future-proof**: Built for AppsFlyer's V2 validation endpoints

---

**iOS sandbox mode:**

For testing iOS purchase validation against the App Store sandbox, enable sandbox mode before validating:

```dart
await appsFlyerSdk.setUseReceiptValidationSandbox(true);
```

For the uninstall-measurement flow,
`setUseUninstallSandbox(true)` is the sandbox companion.

---

## <a id="out-of-store"> Android Out of Store

Use out-of-store attribution when you distribute the Android app through a store other
than Google Play. Read AppsFlyer's
[out-of-store attribution guide](https://support.appsflyer.com/hc/en-us/articles/207447023-Attributing-out-of-store-Android-markets-guide).

### Google Play Install Referrer

Play Install Referrer is collected via Google's Install Referrer library. The native SDK
declares this dependency as `compileOnly`, and the Flutter plugin supplies the required
runtime dependency transitively:

```gradle
dependencies {
    implementation 'com.android.installreferrer:installreferrer:2.2'
}
```

No app-level Gradle change is required for AppsFlyer. Add the dependency to your app
module only if your application code imports and uses the Install Referrer API directly.

Upgrade-specific receiver removal instructions are documented in
[doc/migration-guide.md](migration-guide.md).

### Alternative stores (Samsung, Xiaomi, Huawei)

If you publish to Samsung Galaxy Store, Xiaomi GetApps, or Huawei AppGallery, add the
optional store referrer Gradle dependencies from the native migration guide
([§11 — optional store referrer libraries](https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7#11-add-optional-store-referrer-libraries)).
No extra Flutter plugin setup is required beyond those dependencies.

### Runtime configuration

Set the alternative store label at runtime with `setOutOfStore` (Android only). The value
is runtime-only, so re-apply it on every cold start. See the
[API reference](api-reference.md#setOutOfStore):

```dart
if (Platform.isAndroid) {
  await appsflyerSdk.setOutOfStore("facebook_int");
}
```

---

## iOS 14 & App Tracking Transparency

App Tracking Transparency (ATT) setup has moved to
[Getting started → iOS 14 & App Tracking Transparency](getting-started.md#ios-14--app-tracking-transparency).
