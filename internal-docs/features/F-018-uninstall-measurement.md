---
id: F-018
name: Uninstall Measurement
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Attribution isn't just about installs — media sources and marketers also need to measure uninstalls to calculate true retention/ROI. AppsFlyer measures uninstalls by receiving silent push notifications and needs the device's push token registered against the install. `updateServerUninstallToken(String token)` is how the host app hands that token (FCM token on Android, APNs device token on iOS) to the native SDK. Without it, uninstall events never reach AppsFlyer's backend and uninstall-based campaign reporting/ROI calculations would be silently incomplete.

---

## Trigger
Called by the host app whenever it obtains/refreshes its push token — typically inside a Firebase Messaging (`FirebaseMessaging.instance.getToken()` on Android / `getAPNSToken()` on iOS) callback, or from native `didRegisterForRemoteNotificationsWithDeviceToken:` on iOS.

---

## Call Chain
The single Dart method dispatches to a different RPC per platform (Android's FCM path vs. iOS's `registerUninstall`).

```
AppsflyerSdk.updateServerUninstallToken(token)                         [lib/src/appsflyer_sdk.dart]
  → Android: _executeRpc('updateServerUninstallToken', {'token': token})
  → iOS:     _executeRpc('registerUninstall', {'deviceToken': token})

  → MethodChannel "af-api".invokeMethod('executeRpc', {method, params})
    → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().updateServerUninstallToken(context, token)   [FCM token as-is]
    → iOS: AppsflyerSdkPlugin executeRpc → AppsFlyerRPCBridge                       [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → hex-string token decoded into NSData → [[AppsFlyerLib shared] registerUninstall:deviceTokenData]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `updateServerUninstallToken(String)` — dispatches `updateServerUninstallToken` (Android) / `registerUninstall` (iOS) RPC |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | RPC bridge entry (`executeRpc`) routing `updateServerUninstallToken` to `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | RPC bridge entry (`executeRpc`) forwarding `registerUninstall`; the bridge converts the hex-string token to `NSData` |
| `doc/advanced-features.md` | "Measure App Uninstalls" section documents both the iOS-native (`registerUninstall:` in `AppDelegate.m`) and plugin-side paths, and the Firebase Messaging integration pattern |

---

## Input / Output
| | |
|--|--|
| **Input** | `token` (String) — Android: FCM registration token, passed through as-is. iOS: APNs device token as an even-length **hexadecimal string** (e.g. from `FirebaseMessaging.instance.getAPNSToken()`); the bridge converts each hex byte pair into raw `NSData` before calling `registerUninstall:` (a non-hex string is rejected silently). |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check updateServerUninstallToken call` asserts the mocked `af-api` channel receives `executeRpc` with method `updateServerUninstallToken` and params `{'token': 'token123'}` (host tests run the Android branch). No test covers the iOS `registerUninstall` branch or the hex-to-`NSData` conversion.

---

## Known Limitations
- On iOS, the hex-string token is decoded byte-pair by byte-pair; a malformed/odd-length hex string is rejected silently by the bridge rather than raising an error back to Dart.
- The app is responsible for obtaining and refreshing the push token itself (e.g. via `firebase_messaging`); this API only forwards whatever string it is given, so a stale or missing token upstream silently degrades uninstall measurement with no error surfaced to the caller.

---

## Dependencies
```mermaid
flowchart LR
    F018["F-018 · Uninstall Measurement"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
