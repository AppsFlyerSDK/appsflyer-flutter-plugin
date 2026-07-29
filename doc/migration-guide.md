# Migrating the AppsFlyer Flutter plugin from v6 to v7

<img src="https://massets.appsflyer.com/wp-content/uploads/2018/06/20092440/static-ziv_1TP.png" width="400">

Plugin `7.0.1` migrates to **AppsFlyer SDK 7** (Android & iOS `7.0.1`) and routes every
call through the native RPC bridges (Android `AppsFlyerRpcHandler`, iOS
`AFRPCRequestHandler`). This is a major release with intentional breaking changes.

This guide is scoped to the **Flutter plugin**. For the underlying native behavior, read
the official SDK 7 migration guides — they are the source of truth for what changed:

- Android: <https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7>
- iOS: <https://dev.appsflyer.com/hc/docs/migrate-ios-sdk-to-v7>

---

## API Removal Rule

> **Preserve SDK 7 behavior — not SDK 6 APIs.**

If a public API has been **removed from the native AppsFlyer SDK 7, it is also removed from
the Flutter plugin.** The plugin does not preserve or emulate APIs that no longer exist in
the native SDK unless there is a strong technical or business justification.

Because this is a major version migration (SDK 6 → SDK 7), breaking API changes are expected
and acceptable when they align the plugin with the native SDKs. Obsolete SDK 6 APIs are **not**
kept for backward compatibility. Instead, for every migration the plugin:

- **Removes** APIs that were removed from the native SDK.
- **Redesigns** the Flutter API to follow the new SDK 7 architecture.
- **Documents** every removed or changed API in this guide and in the [CHANGELOG](/CHANGELOG.md).
- **Explains** the replacement API or the new SDK 7 workflow, when one exists.

The plugin stays a thin, platform-consistent abstraction over the native Android and iOS
SDKs rather than maintaining legacy concepts that no longer exist in SDK 7.

---

## Session model: `initSdk()` then `startSDK()`

The biggest behavioral change in SDK 7 is that **you control when a session (Launch) is
sent**. `initSdk()` only initializes the SDK; nothing is reported until you call `startSDK()`,
and `startSDK()` must be called **once per foreground cycle** (the native SDK resets its
"started" flag on every background).

Register a session-ready listener and start from inside it, so every foreground — including
background → foreground — reports a session:

```dart
final AppsflyerSdk appsflyer = AppsflyerSdk(options);

// Register BEFORE initSdk so the first signal is not missed.
appsflyer.registerSessionReadyListener((_) => appsflyer.startSDK());

await appsflyer.initSdk(
  registerConversionDataCallback: true,
  registerOnDeepLinkingCallback: true,
);
```

Gate the first session (consent, Customer User ID, ATT) by deferring the `startSDK()` call
inside the callback. Apply any configuration setters (e.g. `setCustomerUserId`,
`setCurrencyCode`, `setConsentDataV2`) **before** `startSDK()`.

> **Setter values are runtime-only on both platforms.** SDK 7 aligns Android with iOS:
> setter values are no longer persisted to disk and do not survive a process restart.
> Re-apply them on every cold start, before `startSDK()`.

---

## Removed APIs and their replacements

| Removed Flutter API (v6) | Why | SDK 7 replacement / action |
| --- | --- | --- |
| `manualStart` (`AppsFlyerOptions`) | `initSdk()` no longer auto-starts | Call `startSDK()` from `registerSessionReadyListener` |
| `onAppOpenAttribution`, `registerOnAppOpenAttributionCallback` | OAOA removed from both native SDKs | `onDeepLinking` + `registerOnDeepLinkingCallback: true` (Unified Deep Linking) |
| `performOnDeepLinking()` | Removed on Android (§5a), replaced on iOS | `performDeepLinking(url, {shouldTriggerSession})` |
| `subscribeForDeepLink(listener, timeout)` overload | Removed on Android (§5b) | `setDeepLinkTimeout(ms)` before `initSdk`, then subscribe |
| `validateAndLogInAppAndroidPurchase` (V1) | Native V1 purchase validation removed | `validateAndLogInAppPurchaseV2` |
| `validateAndLogInAppIosPurchase` (V1) | Native 6-param `validateAndLogInAppPurchase` removed (iOS §6) | `validateAndLogInAppPurchaseV2` |
| `setPushNotification(bool)` | Removed from both native SDKs | `sendPushNotificationData(Map)` |
| `enableUninstallTracking(String)` | Legacy device-token flow removed | `updateServerUninstallToken(String)` |
| `setCollectIMEI(bool)` | Removed from native SDK 7 (§9) | IMEI auto-collection removed; no replacement |
| `waitForCustomerUserId(bool)` | Removed from native SDK 7 (§9) | Call `setCustomerUserId()` before `startSDK()` |
| `setCustomerIdAndLogSession(String)` | Removed from native SDK 7 (§9) | `setCustomerUserId()` then `startSDK()` |
| `setSharingFilter`, `setSharingFilterForAllPartners` | Removed from both native SDKs | `setSharingFilterForPartners(["all"])` |
| `enableLocationCollection(bool)` | Removed in plugin `6.8.0` | No replacement |

### APIs present in native SDK 7 but removed from the plugin

The plugin is a thin bridge over the native **RPC** layers (`AppsFlyerRpcHandler` /
`AFRPCRequestHandler`). A few APIs still exist on the native `AppsFlyerLib` but are **not
exposed by the RPC bridges**, so the plugin cannot reach them. Rather than ship silent
no-ops, they are removed:

| Removed Flutter API (v6) | Why | SDK 7 replacement / action |
| --- | --- | --- |
| `setUserEmails(List, EmailCryptType)` | Not exposed by the RPC bridges | Hashed `setUserEmail(String)` |
| `setImeiData(String)` | Not exposed by the RPC bridges | No RPC-reachable replacement |
| `setAndroidIdData(String)` | Not exposed by the RPC bridges | No RPC-reachable replacement |

> The `EmailCryptType` enum was removed together with `setUserEmails`.

---

## Changed APIs

| v6 | v7 |
| --- | --- |
| `performOnDeepLinking()` | `performDeepLinking(String url, {bool shouldTriggerSession})` |
| `setConsentData(...)` | `setConsentDataV2({...})` (the old signature is deprecated) |
| Deep-link timeout passed to `subscribeForDeepLink` | `setDeepLinkTimeout(int timeoutMs)` |
| Deep-link result enum `Error` | `DeepLinkError` (renamed to stop shadowing `dart:core Error`; `DeepLinkResult.error` type is now `DeepLinkError?`) |

---

## Added in SDK 7

Session model and deep linking:

| API | Purpose |
| --- | --- |
| `registerSessionReadyListener`, `unregisterSessionReadyListener`, `isSessionReady` | SDK 7 session-ready model |
| `performDeepLinking(url, {shouldTriggerSession})` | Manual deep link resolution |
| `setDeepLinkTimeout(timeoutMs)` | Deep link resolution timeout |
| `appendParametersToDeepLinkingURL(contains, parameters)` | Enrich matching deep-link URLs before resolution (Android + iOS) |
| `setFacebookDeferredAppLink(url)` | Manually set/clear the Facebook deferred app-link URL (**iOS only**) |

User identity & hashed PII:

| API | Purpose |
| --- | --- |
| `setUserEmail`, `setUserPhone`, `setUserFirstName`, `setUserLastName`, `setUserFbLoginId`, `clearUserPii` | Hashed-PII setters (SHA-256, hashed by the SDK) |

New parity APIs exposed in the plugin (already present in the native SDK 7):

| API | Purpose | Platforms |
| --- | --- | --- |
| `logInvite(channel, [eventParameters])` | Log the `af_invite` in-app event | Android + iOS |
| `logLocation(latitude, longitude)` | Manually log the device location | Android + iOS |
| `logSession()` | Manually log a session (background/utility apps) | Android only |
| `setInstallId(installId)` | Correlate the install with your own id | Android + iOS |
| `isStopped()` | Query whether the SDK is stopped | Android only |
| `isPreInstalledApp()` | Query whether the install was an OEM preinstall | Android only |
| `getAttributionId()` | Read the Facebook (Katana) attribution id | Android only |
| `setPreinstallAttribution(mediaSource, campaign, siteId)` | Attribute an OEM preinstall | Android only |
| `setAppId(appId)` | Override the reported app id | Android only |
| `disableAppleAdsAttribution(disable)` | Disable Apple Ads (ASA) attribution via AdServices | iOS only |
| `disableIDFVCollection(disable)` | Disable IDFV collection | iOS only |
| `setShouldCollectDeviceName(collect)` | Opt in to device-name collection | iOS only |
| `useUninstallSandbox(enabled)` | Sandbox mode for uninstall-measurement validation | iOS only |

---

## Android: remove legacy install-referrer receivers

SDK 7 removed `SingleInstallBroadcastReceiver` and `MultipleInstallBroadcastReceiver`.
Remove any matching `<receiver>` entries from `android/app/src/main/AndroidManifest.xml`
(together with their `com.android.vending.INSTALL_REFERRER` intent filters). Leaving them
breaks manifest merge at **build time**.

Add Google Play Install Referrer to `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.android.installreferrer:installreferrer:2.2'
}
```

Native reference: [Migrate Android SDK to V7 — §8](https://dev.appsflyer.com/hc/docs/migrate-android-sdk-to-v7#8-remove-legacy-broadcast-receivers).
For Samsung / Xiaomi / Huawei store referrers, see §11 of the same guide.

> Plugin v6 docs recommended adding `SingleInstallBroadcastReceiver` for some out-of-store
> markets. That guidance is **obsolete** for SDK 7 — use the Install Referrer library,
> optional store-referrer artifacts, and `setOutOfStore`. See
> [Advanced features — Android Out of Store](advanced-features.md#out-of-store).

---

See the full, version-by-version history in the [CHANGELOG](/CHANGELOG.md) and the complete
method reference in [API reference](/doc/api-reference.md).
