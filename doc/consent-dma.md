# Privacy, identity, consent & DMA compliance

> **Audience:** apps configuring user identity, privacy controls, or DMA/GDPR
> consent. Requires the [core setup](getting-started.md).

## Privacy and identity workflow

Apply privacy and identity settings that must affect the first Launch after
`init()` and **before** registering the session-ready listener. Registration can
emit `onSessionReady` immediately and trigger `start()`.

| Goal | API | When to use it |
| --- | --- | --- |
| Anonymize attribution data for the current user | `anonymizeUser(true)` | Call before the first `start()`. Call `anonymizeUser(false)` to stop anonymizing future data. |
| Stop all SDK activity and communication | `stop(true)` | Use for a complete SDK opt-out. Do not call `start()` while stopped. Call `stop(false)` to resume, then continue with the normal `onSessionReady` → `start()` flow. |
| Disable advertising-identifier collection | `setDisableAdvertisingIdentifiers(true)` | Call before the first `start()` when your privacy choice requires GAID, IDFA, and OAID collection to be disabled. Pass `false` to enable collection again. |
| Set user PII for network sharing | `setUserEmail`, `setUserPhone`, `setUserFirstName`, `setUserLastName`, `setUserFbLoginId` | Set only the values your app is allowed to share. Email, phone, and name values are hashed by the native SDK; the Facebook App-Scoped ID is not hashed. |
| Remove previously set PII | `clearUserPii()` | Call on logout, before switching accounts, or when the app should no longer retain values set through the `setUser*` APIs. It does not clear the Customer User ID, consent, or anonymization state. |

For example:

```dart
await appsflyerSdk.init(
  devKey: 'your_dev_key',
  appId: '1234567890',
);

// Apply the current user's privacy and identity choices before the first start().
await appsflyerSdk.setDisableAdvertisingIdentifiers(true);
await appsflyerSdk.anonymizeUser(true);

// Register last because this can emit onSessionReady immediately.
await appsflyerSdk.registerSessionReadyListener();
```

`anonymizeUser(true)` does not stop the SDK; it changes how the user's data is
reported. `stop(true)` stops SDK activity entirely. Re-apply the privacy and
identity configuration your app needs on every cold start, as described in
[Getting started](getting-started.md#4-configure-the-first-launch).

The following sections explain how to provide DMA/GDPR consent through a CMP or
the manual consent API.

Following the DMA regulations that were set by the European Commission, Google and Amazon require consent data in order to use it during the attribution process. The SDK 7 plugin supports both TCF-based collection and explicit consent data, enhancing support for user consent and data collection preferences in line with evolving digital market regulations.
There are two alternative ways for gathering consent data:

- Through a Consent Management Platform (CMP): If the app uses a CMP that complies with the Transparency and Consent Framework (TCF) v2.2 or v2.3 protocol, the SDK can automatically retrieve the consent details.

**OR**

- Through a dedicated SDK API: Developers can pass Google's required consent data directly to the SDK using a specific API designed for this purpose.

## Use CMP to collect consent data

A CMP compatible with TCF v2.2 or v2.3 collects DMA consent data and stores it in NSUserDefaults (iOS) and SharedPreferences (Android). To enable the SDK to access this data and include it with every event, follow these steps:

1. Initialize the SDK with `appsflyerSdk.init(...)`.
2. Call `appsflyerSdk.enableTCFDataCollection(true)`.
3. Use the CMP to decide if you need the consent dialog in the current session to acquire the consent data. If you need the consent dialog move to step 4, otherwise move to step 5.
4. Get confirmation from the CMP that the user has made their consent decision and the data is available in NSUserDefaults/SharedPreferences.
5. Register the session-ready listener. Call `appsflyerSdk.start()` when
   `onSessionReady` emits.

```dart
final appsflyerSdk = AppsFlyerSdk.instance;

appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});

await appsflyerSdk.init(
  devKey: 'your_dev_key',
  appId: '1234567890',
);
await appsflyerSdk.enableTCFDataCollection(true);

// CMP pseudocode procedure
if (cmpManager.hasConsent()) {
  await appsflyerSdk.registerSessionReadyListener();
} else {
  await cmpManager.presentConsentDialogToUser();
  await appsflyerSdk.registerSessionReadyListener();
}
```

## Manually collect consent data

<!-- markdownlint-disable MD033 -->
### Use [setConsentData](#setconsentdata-recommended-api-for-manual-consent-collection)
<!-- markdownlint-enable MD033 -->

If your app does not use a CMP compatible with TCF v2.2 or v2.3, use the SDK API detailed below to provide the consent data directly to the SDK, distinguishing between cases when GDPR applies or not.

### When GDPR applies to the user

If GDPR applies to the user, perform the following:

1. Given that GDPR is applicable to the user, determine whether the consent data is already stored for this session.
    1. If there is no consent data stored, show the consent dialog to capture the user consent decision.
    2. If there is consent data stored continue to the next step.
2. Prepare the required consent values:<br>
    `hasConsentForDataUsage: bool` - Indicates whether the user has consented to use their data for advertising purposes.<br>
    `hasConsentForAdsPersonalization: bool` - Indicates whether the user has consented to use their data for personalized advertising.<br>
    `hasConsentForAdStorage: bool?` - (Optional) Indicates whether the user consents to storing ad-related data.
3. Initialize the SDK using `appsflyerSdk.init(...)`.
4. Call `appsflyerSdk.setConsentData(...)` before registering the session-ready listener.
5. Register the session-ready listener and call `appsflyerSdk.start()` when
   `onSessionReady` emits.

```dart
// If the user is subject to GDPR - collect the consent data
// or retrieve it from the storage
// ...

final appsflyerSdk = AppsFlyerSdk.instance;
appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});

await appsflyerSdk.init(
  devKey: 'your_dev_key',
  appId: '1234567890',
);

await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: true,
  hasConsentForDataUsage: true,
  hasConsentForAdsPersonalization: false,
);

await appsflyerSdk.registerSessionReadyListener();
```

### When GDPR does not apply to the user

If GDPR doesn't apply to the user perform the following:

1. Initialize the SDK using `appsflyerSdk.init(...)`.
2. Call `setConsentData` with `isUserSubjectToGDPR: false`. Omit the
   GDPR-specific consent values.
3. Register the session-ready listener and call `appsflyerSdk.start()` when
   `onSessionReady` emits.

```dart
final appsflyerSdk = AppsFlyerSdk.instance;
appsflyerSdk.onSessionReady.listen((_) async {
  await appsflyerSdk.start();
});

await appsflyerSdk.init(
  devKey: 'your_dev_key',
  appId: '1234567890',
);

await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: false,
);

await appsflyerSdk.registerSessionReadyListener();
```

<a id="setconsentdata-recommended-api-for-manual-consent-collection"></a>
<a id="setconsentdatav2-recommended-api-for-manual-consent-collection---since-6162"></a>
## setConsentData (Recommended API for Manual Consent Collection)

🚀 **Why Use setConsentData?**</br>
The `setConsentData` API provides structured consent data to the AppsFlyer SDK.

It uses named parameters to distinguish GDPR and non-GDPR users:</br>
✅ **Simple and Intuitive:** Uses clear parameter names for each consent choice.</br>
✅ **Includes an Additional Consent Parameter:** Now supports hasConsentForAdStorage to give users more granular control over their data.</br>
✅ **Enhanced Clarity**: Allows nullable boolean values, indicating when users have not provided consent instead of forcing defaults.</br>
✅ **Future-Proof:** Designed to be aligned with evolving privacy regulations and best practices.</br>

📌 **API Reference**

```dart
Future<void> setConsentData({
  required bool isUserSubjectToGDPR,
  bool? hasConsentForDataUsage,
  bool? hasConsentForAdsPersonalization,
  bool? hasConsentForAdStorage,
})
```

### Parameters

| Parameter | Type | Description |
| -------- | -------- | -------- |
| isUserSubjectToGDPR            | bool (required) | Indicates if the user is subject to GDPR regulations. |
| hasConsentForDataUsage         | bool?     | Determines if the user consents to data usage. Supply when `isUserSubjectToGDPR` is `true`. |
| hasConsentForAdsPersonalization | bool?     | Determines if the user consents to personalized ads. Supply when `isUserSubjectToGDPR` is `true`. |
| hasConsentForAdStorage         | bool?     | Determines if the user consents to storing ad-related data. Optional. |

- When `isUserSubjectToGDPR` is `true`, supply both usage and ads-personalization values before the first `start()`. The iOS native RPC layer validates them; the plugin forwards the payload without Dart-side checks.
- When `isUserSubjectToGDPR` is `false`, omit the GDPR-specific values.
- For an `hasConsentForAdStorage` value of `null`, the user has **not explicitly provided consent** for that option.
- These values should be collected from the user via an appropriate **UI or consent prompt** before calling this method.

📌 **Example Usage**

```dart
final appsflyerSdk = AppsFlyerSdk.instance;
await appsflyerSdk.init(
  devKey: 'your_dev_key',
  appId: '1234567890',
);

await appsflyerSdk.setConsentData(
  isUserSubjectToGDPR: true,
  hasConsentForDataUsage: true,
  hasConsentForAdsPersonalization: false,
  hasConsentForAdStorage: null,
);
```  

📌 **Notes**</br>
• Call this method after `init()` and before `start()`.</br>
• Provide the current consent data on every app start. The values are not persisted across sessions.</br>
• Ensure you collect consent **legally and transparently** from the user before passing these values.
