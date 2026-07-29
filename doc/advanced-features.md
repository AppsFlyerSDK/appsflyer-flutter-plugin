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

  **`Future<void> setAppInviteOneLinkID(String oneLinkID, [Function? callback])`**  (the `callback` is optional; it only signals a static `"success"`)

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

**iOS sandbox mode:**

For testing iOS purchase validation against the App Store sandbox, enable sandbox mode before validating:

```dart
appsFlyerSdk.useReceiptValidationSandbox(true);
```

For the uninstall-measurement flow, `useUninstallSandbox(true)` is the sandbox companion.

---

## <a id="out-of-store"> Android Out of Store

Use out-of-store attribution when you distribute the Android app through a store other
than Google Play. Read AppsFlyer's
[out-of-store attribution guide](https://support.appsflyer.com/hc/en-us/articles/207447023-Attributing-out-of-store-Android-markets-guide).

### SDK 7: install referrer (Google Play and most stores)

AppsFlyer SDK 7 **removed** the legacy broadcast receivers
`com.appsflyer.SingleInstallBroadcastReceiver` and
`com.appsflyer.MultipleInstallBroadcastReceiver`. **Do not** add them to your
`AndroidManifest.xml` — leftover entries from a v6 integration cause a **build failure**
during manifest merge.

Play Install Referrer is collected via Google's Install Referrer library instead. Add this
to your **app module** `android/app/build.gradle` (the SDK declares it as `compileOnly`; your
app must include it explicitly):

```gradle
dependencies {
    implementation 'com.android.installreferrer:installreferrer:2.2'
}
```

See [Migrate Android SDK to V7 — §8](https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7#8-remove-legacy-broadcast-receivers).

If you upgraded from plugin v6, **remove** any existing `<receiver>` entries for those
classes and their `com.android.vending.INSTALL_REFERRER` intent filters.

### Alternative stores (Samsung, Xiaomi, Huawei)

If you publish to Samsung Galaxy Store, Xiaomi GetApps, or Huawei AppGallery, add the
optional store referrer Gradle dependencies from the native migration guide
([§11 — optional store referrer libraries](https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7#11-add-optional-store-referrer-libraries)).
No extra Flutter plugin setup is required beyond those dependencies.

### Runtime configuration

Set the alternative store label at runtime with `setOutOfStore` (Android only). Re-apply on
every cold start — SDK 7 does not persist setter values. See the
[API reference](api-reference.md#setOutOfStore):

```dart
if (Platform.isAndroid) {
  appsflyerSdk.setOutOfStore("facebook_int");
}
```

---

## iOS 14 & App Tracking Transparency

App Tracking Transparency (ATT) setup has moved to
[Getting started → iOS 14 & App Tracking Transparency](getting-started.md#ios-14--app-tracking-transparency).