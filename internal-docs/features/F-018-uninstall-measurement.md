---
id: F-018
name: Uninstall Measurement
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Attribution isn't just about installs — media sources and marketers also need to measure uninstalls to calculate true retention/ROI. AppsFlyer measures uninstalls by receiving silent push notifications and needs the device's push token registered against the install. `updateServerUninstallToken(String token)` is how the host app hands that token (FCM token on Android, APNs device token on iOS) to the native SDK. Without it, uninstall events never reach AppsFlyer's backend and uninstall-based campaign reporting/ROI calculations would be silently incomplete.

---

## Trigger
The host app awaits `updateServerUninstallToken` whenever it obtains or refreshes its push token — typically from a Firebase Messaging callback (`FirebaseMessaging.instance.getToken()` on Android, `getAPNSToken()` on iOS, or the `onTokenRefresh` stream).

---

## Call Chain
One Dart method, one public parameter; the platform difference is confined to the RPC name and parameter key. The call is awaitable and native failures surface as `AppsFlyerException`.

```
AppsFlyerSdk.updateServerUninstallToken(token)                        [lib/src/appsflyer_sdk.dart]
  → Android: _invokeVoidRpc('updateServerUninstallToken', {'token': token})
  → iOS:     _invokeVoidRpc('registerUninstall', {'deviceToken': token})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → UpdateServerUninstallTokenRequest(token)  // init: require(token.isNotEmpty())
        → appsFlyerLib.updateServerUninstallToken(context, token)   // FCM token as-is
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → AFRPCRegisterUninstallRequest  // hex string decoded to Data, else validationError
        → [[AppsFlyerLib shared] registerUninstall:deviceTokenData]
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `updateServerUninstallToken(String token)` — dispatches `updateServerUninstallToken` (Android) / `registerUninstall` (iOS) |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | No per-method handler — the generic `executeRpc` → `dispatchRpc` path forwards the envelope to `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | No per-method handler — the generic `executeRpc` → `dispatchRpc` path forwards the envelope to `AppsFlyerRPCBridge`, which decodes the hex token into `NSData` |
| `doc/advanced-features.md` | "Measure App Uninstalls" section documents both platforms and the Firebase Messaging integration pattern |

---

## Input / Output
| | |
|--|--|
| **Input** | `token` (`String`). Android: FCM registration token, passed through as-is under the `token` key. iOS: APNs device token as an even-length **hexadecimal string**, sent under the `deviceToken` key; the iOS RPC layer converts each hex byte pair into raw `Data` before calling `registerUninstall:`. |
| **Output** | `Future<void>` that completes after native RPC validation and the synchronous SDK registration call. Native validation and bridge failures throw `AppsFlyerException`; neither platform waits for server registration and there is no RPC timeout. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `maps deep-link, sharing, push, and uninstall APIs` asserts both branches: the Android SDK instance dispatches `updateServerUninstallToken` with `{'token': 'fcm-token'}`, and the iOS SDK instance dispatches `registerUninstall` with `{'deviceToken': '0123456789abcdef'}`. The hex-to-`Data` conversion itself lives in the native iOS RPC layer and is covered by its own tests, not by the Dart suite.

---

## Known Limitations
- The Flutter layer performs no token validation. An empty token (Android `require(token.isNotEmpty())`) or a malformed/odd-length hex string (iOS `validationError`) is rejected natively; the rejection now propagates back as `AppsFlyerException`, so the caller must `await` the call to observe it.
- The app is responsible for obtaining and refreshing the push token itself (e.g. via `firebase_messaging`). This API only forwards the string it is given, so a stale token upstream still degrades uninstall measurement without any error.

---

## Dependencies
```mermaid
flowchart LR
    F018["F-018 · Uninstall Measurement"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
