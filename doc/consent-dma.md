# Consent & DMA compliance

> **Audience:** apps serving EEA users that must collect consent for DMA/GDPR. Requires the [core setup](getting-started.md).

Following the DMA regulations that were set by the European Commission, Google (and potentially other SRNs in the future) require to send them the user's consent data in order to interact with them during the attribution process. In our latest plugin update (6.16.2), we've introduced two new public APIs, enhancing our support for user consent and data collection preferences in line with evolving digital market regulations.
There are two alternative ways for gathering consent data:

- Through a Consent Management Platform (CMP): If the app uses a CMP that complies with the Transparency and Consent Framework (TCF) v2.2 protocol, the SDK can automatically retrieve the consent details.

**OR**

- Through a dedicated SDK API: Developers can pass Google's required consent data directly to the SDK using a specific API designed for this purpose.

## Use CMP to collect consent data

A CMP compatible with TCF v2.2 collects DMA consent data and stores it in NSUserDefaults (iOS) and SharedPreferences (Android). To enable the SDK to access this data and include it with every event, follow these steps:

1. Call `appsflyerSdk.enableTCFDataCollection(true)`
2. Initialize the SDK with `appsflyerSdk.initSdk(...)`. In SDK 7 the first session is always sent explicitly via `startSDK()`, so the consent data can be provided between init and start.
3. Use the CMP to decide if you need the consent dialog in the current session to acquire the consent data. If you need the consent dialog move to step 4, otherwise move to step 5.
4. Get confirmation from the CMP that the user has made their consent decision and the data is available in NSUserDefaults/SharedPreferences.
5. Call `appsflyerSdk.startSDK()`

```dart
// The first session is always sent explicitly via startSDK()
final AppsFlyerOptions options = AppsFlyerOptions(
  afDevKey: 'your_dev_key',
  appId: '1234567890',  // Required for iOS only
  showDebug: true
);

// Create the AppsflyerSdk instance
AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

// Initialize the SDK
appsflyerSdk.initSdk(
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true
);

// CMP pseudocode procedure
if (cmpManager.hasConsent()) {
  appsflyerSdk.startSDK();
} else {
  cmpManager.presentConsentDialogToUser()
    .then((_) => appsflyerSdk.startSDK());
}
```

## Manually collect consent data

<!-- markdownlint-disable MD033 -->
### <span style="color: red">setConsentData is now **deprecated**. use [setConsentDataV2](#setconsentdatav2-recommended-api-for-manual-consent-collection---since-6162)</span>
<!-- markdownlint-enable MD033 -->

If your app does not use a CMP compatible with TCF v2.2, use the SDK API detailed below to provide the consent data directly to the SDK, distinguishing between cases when GDPR applies or not.

### When GDPR applies to the user

If GDPR applies to the user, perform the following:

1. Given that GDPR is applicable to the user, determine whether the consent data is already stored for this session.
    1. If there is no consent data stored, show the consent dialog to capture the user consent decision.
    2. If there is consent data stored continue to the next step.
2. Transfer the consent data to the SDK with `setConsentDataV2`, passing `isUserSubjectToGDPR: true`. When the user is subject to GDPR both consent flags are required:<br>
    `consentForDataUsage: bool` - Indicates whether the user has consented to use their data for advertising purposes.<br>
    `consentForAdsPersonalization: bool` - Indicates whether the user has consented to use their data for personalized advertising.<br>
    `hasConsentForAdStorage: bool?` - (Optional) Indicates whether the user consents to storing ad-related data.
3. Call `appsflyerSdk.setConsentDataV2(...)` before starting the SDK.
4. Initialize the SDK using `appsflyerSdk.initSdk()`.

```dart
// If the user is subject to GDPR - collect the consent data
// or retrieve it from the storage
// ...

// Set the consent data to the SDK:
appsflyerSdk.setConsentDataV2(
  isUserSubjectToGDPR: true,
  consentForDataUsage: true,
  consentForAdsPersonalization: false,
);

// Initialize AppsFlyerOptions
final AppsFlyerOptions options = AppsFlyerOptions(
  afDevKey: 'your_dev_key',
  appId: '1234567890',  // Required for iOS only
  showDebug: true
);

// Create the AppsflyerSdk instance
AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

// Initialize the SDK
appsflyerSdk.initSdk(
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true
);
```

### When GDPR does not apply to the user

If GDPR doesn't apply to the user perform the following:

1. Call `setConsentDataV2` with `isUserSubjectToGDPR: false`. The consent flags are ignored for non-GDPR users and may be omitted.
2. Initialize the SDK using `appsflyerSdk.initSdk()`.

```dart
// If the user is not subject to GDPR:
appsflyerSdk.setConsentDataV2(isUserSubjectToGDPR: false);

// Initialize AppsFlyerOptions
final AppsFlyerOptions options = AppsFlyerOptions(
  afDevKey: 'your_dev_key',
  appId: '1234567890',  // Required for iOS only
  showDebug: true
);

// Create the AppsflyerSdk instance
AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

// Initialize the SDK
appsflyerSdk.initSdk(
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true
);
```

## setConsentDataV2 (Recommended API for Manual Consent Collection) - since 6.16.2

🚀 **Why Use setConsentDataV2?**</br>
The setConsentDataV2 API is the new and improved way to manually provide user consent data to the AppsFlyer SDK.

It replaces the now deprecated setConsentData method, offering several improvements:</br>
✅ **Simpler and More Intuitive:** Accepts named parameters, making it easier to manage.</br>
✅ **Includes an Additional Consent Parameter:** Now supports hasConsentForAdStorage to give users more granular control over their data.</br>
✅ **Enhanced Clarity**: Allows nullable boolean values, indicating when users have not provided consent instead of forcing defaults.</br>
✅ **Future-Proof:** Designed to be aligned with evolving privacy regulations and best practices.</br>

If your app previously used setConsentData, it is highly recommended to migrate to setConsentDataV2 for a more flexible and robust solution.

📌 **API Reference**

```dart
void setConsentDataV2({
  required bool isUserSubjectToGDPR,
  bool? consentForDataUsage,
  bool? consentForAdsPersonalization,
  bool? hasConsentForAdStorage,
})
```

### Parameters

| Parameter | Type | Description |
| -------- | -------- | -------- |
| isUserSubjectToGDPR            | bool (required) | Indicates if the user is subject to GDPR regulations. |
| consentForDataUsage         | bool?     | Determines if the user consents to data usage. **Required when `isUserSubjectToGDPR` is `true`.** |
| consentForAdsPersonalization | bool?     | Determines if the user consents to personalized ads. **Required when `isUserSubjectToGDPR` is `true`.** |
| hasConsentForAdStorage         | bool?     | **(New!)** Determines if the user consents to storing ad-related data. Optional. |

- `isUserSubjectToGDPR` is **required**. When it is `true`, both `consentForDataUsage` and `consentForAdsPersonalization` are **also required** — omitting either throws an `ArgumentError` (mirroring the native iOS contract and keeping Android/iOS consistent).
- When `isUserSubjectToGDPR` is `false`, the consent flags are ignored and may be omitted.
- For an `hasConsentForAdStorage` value of `null`, the user has **not explicitly provided consent** for that option.
- These values should be collected from the user via an appropriate **UI or consent prompt** before calling this method.

📌 **Example Usage**

```dart
// The first session is always sent explicitly via startSDK()
final AppsFlyerOptions options = AppsFlyerOptions(
  afDevKey: 'your_dev_key',
  appId: '1234567890',  // Required for iOS only
  showDebug: true
);

// Create the AppsflyerSdk instance
AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

// Set consent data BEFORE initializing the SDK
appsflyerSdk.setConsentDataV2(
  isUserSubjectToGDPR: true,
  consentForDataUsage: true,
  consentForAdsPersonalization: false,
  hasConsentForAdStorage: null  // User has not explicitly provided consent
);

// Initialize the SDK
appsflyerSdk.initSdk(
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true
);

// Start the SDK
appsflyerSdk.startSDK();
```  

📌 **Notes**</br>
• You should call this method **before initializing the AppsFlyer SDK** if possible, or at least before `startSDK()`.</br>
• Ensure you collect consent **legally and transparently** from the user before passing these values.
