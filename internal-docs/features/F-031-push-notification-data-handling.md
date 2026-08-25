---
id: F-031
name: Push Notification Data Handling
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Push-notification re-engagement campaigns need to be measured (so their ROI shows up in AppsFlyer reporting) and, when the payload carries a OneLink URL, routed as a deep link into the right in-app screen. This feature hands the push campaign data to the native SDK so it can attribute the re-engagement and, if a deep-link path was configured (F-022), extract and resolve the embedded OneLink URL. Without it, push campaigns cannot be measured for re-engagement and push-embedded deep links never reach the SDK for resolution.

> The legacy `setPushNotification(bool)` toggle was **removed in SDK 7**. See the [migration guide](/doc/migration-guide.md).

---

## Trigger
Awaited by the host app whenever a push notification is received or tapped (foreground, background, or after a cold launch from a terminated state via a persisted "pending push" pattern). Each platform has its own entry point, so the app must branch and call the API that belongs to the platform it is running on.

---

## Call Chain
The push surface is **deliberately not unified**: the two platforms take different data, so the plugin exposes two platform-specific methods instead of one method with a platform-dependent map shape. Neither is gated in Dart — both are awaitable RPC calls with no per-method channel handler, and the native layer rejects the one it does not implement.

```
AppsFlyerSdk.sendPushNotificationData(campaign:, pid:, isRetargeting:, additionalParameters:)  [Android only]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('sendPushNotificationData', {campaign, pid, isRetargeting, additionalParameters})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler                 [android/.../AppsflyerSdkPlugin.kt]
        → SendPushNotificationDataRequest  // init: require(campaign.isNotEmpty()), require(pid.isNotEmpty())
        → AFPushData(campaign, pid, isRetargeting, additionalParameters)
        → appsFlyerLib.sendPushNotificationData(pushData)

AppsFlyerSdk.handlePushNotification(pushPayload)                                               [iOS only]
  → off iOS: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('handlePushNotification', {'pushPayload': pushPayload})
      → AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge                  [ios/.../AppsflyerSdkPlugin.swift]
        → non-empty pushPayload required, else a validation error
        → [[AppsFlyerLib shared] handlePushNotification:] → deep-link event (F-037)

  → PlatformException is converted to AppsFlyerException
```
Any OneLink URL found at the configured path (F-022) is resolved and delivered asynchronously over the `af-events` EventChannel and surfaces as a `DeepLinkResult` in the registered `registerDeepLinkListener` callback (F-037).

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `sendPushNotificationData({required String campaign, required String pid, bool isRetargeting = false, Map<String, dynamic>? additionalParameters})` (Android-only) and `handlePushNotification(Map<String, dynamic> pushPayload)` (iOS-only), both dispatched through RPC without a Dart platform check |
| `android/.../AppsflyerSdkPlugin.kt` / `ios/.../AppsflyerSdkPlugin.swift` | No per-method handler — the generic `executeRpc` → `dispatchRpc` path forwards the JSON envelope to the native RPC bridge |
| `android/.../plugin_bridge` / `AppsFlyerRPC` framework (native SDKs, not the Flutter plugin) | Parse the request and call `sendPushNotificationData` (Android) / `handlePushNotification:` (iOS) |
| `doc/api-reference.md` | Documents both methods and the per-platform push + deep-link matrix |

---

## Input / Output
| | |
|--|--|
| **Input** | Android: named arguments `campaign` and `pid` (both required by the native SDK), plus optional `isRetargeting` and `additionalParameters`; sent as `{campaign, pid, isRetargeting, additionalParameters}`. iOS: the complete APNs notification `userInfo` dictionary, sent as `{pushPayload}`. |
| **Output** | `Future<void>` for both. Each completes after native RPC validation and the synchronous SDK invocation; neither confirms attribution or deep-link resolution and neither has a request timeout. Validation or bridge failures throw `AppsFlyerException`. Called on the wrong platform, each is still dispatched and throws `AppsFlyerException` once the native RPC layer reports the method as unavailable. If F-022 was configured and F-037 registered, a resolved OneLink URL arrives asynchronously in the registered `onDeepLinking` callback. |

---

## Tests
`test/appsflyer_sdk_test.dart`:
- `maps deep-link, sharing, push, and uninstall APIs` — asserts `sendPushNotificationData(campaign: 'campaign', pid: 'media-source', isRetargeting: true, additionalParameters: {...})` dispatches RPC `sendPushNotificationData` with those four params, and that `handlePushNotification({'aps': {}})` dispatches RPC `handlePushNotification` with `{'pushPayload': {'aps': {}}}`.
- `platform-only calls are forwarded to the native RPC instead of being swallowed in Dart` — asserts that `handlePushNotification` on Android still dispatches the `handlePushNotification` RPC; the mirror case, `sendPushNotificationData` on iOS, is not covered separately.

No Dart test covers native attribution or the deep-link extraction that follows.

---

## Known Limitations
- **The two APIs are not interchangeable**: Android needs the structured campaign fields, iOS needs the raw APNs dictionary. Calling the wrong one is no longer absorbed by the Dart layer — it reaches the bridge, which does not implement it, and the call throws `AppsFlyerException`. A cross-platform app must therefore branch on `Platform.isAndroid` / `Platform.isIOS` (or catch the exception), which it would normally do anyway because the two APIs take different inputs.
- **iOS requires this call for push deep links** (per `doc/deep-linking.md`): configuring `addPushNotificationDeepLinkPath` (F-022) on iOS does nothing until the payload is forwarded through `handlePushNotification`; nothing in code enforces the ordering.
- Native rejections (empty Android `campaign`/`pid`, empty iOS payload) surface as `AppsFlyerException`, so the caller must await the Future to observe them.
- On Android the native call triggers a new Launch even if one was already sent in the current session.

---

## Dependencies
No required feature dependency for push attribution itself. F-022 and F-037 are optional workflow components when the payload also contains a OneLink URL that the app wants delivered through UDL.
