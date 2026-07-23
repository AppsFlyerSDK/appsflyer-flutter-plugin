---
id: F-018
name: Uninstall Measurement
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Attribution isn't just about installs — media sources and marketers also need to measure uninstalls to calculate true retention/ROI. AppsFlyer measures uninstalls by receiving silent push notifications and needs the device's push token registered against the install. `updateServerUninstallToken` is how the host app hands that token (FCM token on Android, APNs device token on iOS) to the native SDK. Without it, uninstall events never reach AppsFlyer's backend and uninstall-based campaign reporting/ROI calculations would be silently incomplete.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app whenever it obtains/refreshes its push token — typically inside a Firebase Messaging (`FirebaseMessaging.instance.getToken()` on Android / `getAPNSToken()` on iOS) callback, or from native `didRegisterForRemoteNotificationsWithDeviceToken:` on iOS.

---

## Call Chain
```
AppsflyerSdk.updateServerUninstallToken(token)                         [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("updateServerUninstallToken", {'token': token})
    → Android: AppsflyerSdkPlugin.onMethodCall("updateServerUninstallToken") → updateServerUninstallToken(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().updateServerUninstallToken(mContext, token)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("updateServerUninstallToken") → updateServerUninstallToken:result:         [ios/Classes/AppsflyerSdkPlugin.m]
      → hex-string token manually decoded into NSData
      → [AppsFlyerLib shared] registerUninstall:deviceTokenData]

AppsflyerSdk.enableUninstallTracking(senderId)  [DEPRECATED — no-op]    [lib/src/appsflyer_sdk.dart]
  → prints a deprecation message only; does not invoke the method channel at all
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `updateServerUninstallToken(String)` (active), `enableUninstallTracking(String)` (`@Deprecated`, no-op) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `updateServerUninstallToken(call, result)`, line 1027 |
| `ios/Classes/AppsflyerSdkPlugin.m` | `updateServerUninstallToken:result:`, line 740 — converts hex-string token to `NSData` before calling `registerUninstall:` |
| `doc/AdvancedAPI.md` | "Measure App Uninstalls" section documents both the iOS-native (`registerUninstall:` in `AppDelegate.m`) and plugin-side paths, and the Firebase Messaging integration pattern |

---

## Input / Output
| | |
|--|--|
| **Input** | `token` (String) — Android: FCM registration token, passed through as-is. iOS: APNs device token as a **hexadecimal string** (e.g. from `FirebaseMessaging.instance.getAPNSToken()`); the plugin strips spaces and manually converts each hex byte pair into raw `NSData` before calling `registerUninstall:`. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check updateServerUninstallToken call` (line 150) asserts the mocked channel receives `'updateServerUninstallToken'` with `capturedArguments['token'] == 'token123'`. No test exercises `enableUninstallTracking` (there is nothing to assert — it never touches the channel), and no test covers the iOS hex-to-`NSData` conversion logic.

---

## Known Limitations
- `enableUninstallTracking(senderId)` is `@Deprecated` and, unlike most other deprecated methods in this file, has been fully gutted — it only prints a message and does nothing else, even though the `ios/Classes/AppsflyerSdkPlugin.m` method-dispatch table still has a (no-op) `enableUninstallTracking` branch left over from the old implementation.
- On iOS, `updateServerUninstallToken`'s hex-string parsing has no length/format validation — a malformed or odd-length hex string will silently produce truncated/incorrect `NSData` rather than raising an error back to Dart.
- The app is responsible for obtaining and refreshing the push token itself (e.g. via `firebase_messaging`); this API only forwards whatever string it is given, so a stale or missing token upstream silently degrades uninstall measurement with no error surfaced to the caller.

---

## Dependencies
```mermaid
flowchart LR
    F018["F-018 · Uninstall Measurement"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
