---
id: F-014
name: Manual Deep-Link Re-trigger (performOnDeepLinking)
type: deepLinking
platform: android
status: active
last_verified: 2026-07-15
depends_on: ["F-037"]
---

## Business Purpose
Apps that delay `startSDK()` (manual-start mode) can miss deep-link resolution for the launch intent, because AppsFlyer normally inspects the intent during its own lifecycle hooks around SDK start. `performOnDeepLinking()` lets the host app force the native SDK to re-process the activity's current intent on demand — typically right before a delayed `startSDK()` call — so a OneLink click that launched the app is still resolved even though initialization was deferred. Without this API, manual-start integrators on Android would silently lose deep-link data for the launch that started the app.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called explicitly by the host app, typically in a manual-start (`manualStart: true`) flow, immediately before invoking `startSDK()`/`startSDKwithHandler()` — e.g. after the app has finished its own startup gating (consent, config fetch, etc.) but still needs the original launch intent resolved for deep linking.

---

## Call Chain
```
AppsflyerSdk.performOnDeepLinking()                                          [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("performOnDeepLinking")
    → Android: AppsflyerSdkPlugin.onMethodCall("performOnDeepLinking") → performOnDeepLinking(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → intent = activity.getIntent()
      → AppsFlyerLib.getInstance().performOnDeepLinking(intent, mApplication)
        → afDeepLinkListener.onDeepLinking(DeepLinkResult) [if UDL subscribed]
          → runOnUIThread(..., AF_UDL_CALLBACK, AF_SUCCESS) → callbackChannel "callListener" → Dart onDeepLinking callback   (see F-037)
    → iOS: no "performOnDeepLinking" case in AppsflyerSdkPlugin.m's handleMethodCall: → FlutterMethodNotImplemented
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `performOnDeepLinking()` — platform-agnostic Dart API, no `Platform.isAndroid` guard |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `performOnDeepLinking(call, result)` — reads `activity.getIntent()` and forwards it to `AppsFlyerLib.getInstance().performOnDeepLinking(intent, mApplication)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | No corresponding case in `handleMethodCall:` — the method name is entirely absent |

---

## Input / Output
| | |
|--|--|
| **Input** | None (no arguments passed from Dart) |
| **Output** | Android: `void`; internally errors `"NO_INTENT"` if `activity.getIntent()` is null, or `"NO_ACTIVITY"` if the activity is null (Dart call is fire-and-forget and does not await/inspect these). No direct return value — the actual payload, if any, arrives asynchronously via the `onDeepLinking` callback (F-037). iOS: `MissingPluginException` / `FlutterMethodNotImplemented` since the method is unhandled. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart` does not exercise `performOnDeepLinking`.

---

## Known Limitations
- **iOS has no implementation at all** — unlike most other Dart APIs in this plugin, `performOnDeepLinking` is not merely a no-op stub on iOS (compare `setIsUpdate` in F-016); the method name doesn't appear in `AppsflyerSdkPlugin.m`'s `handleMethodCall:` chain, so the platform channel call falls through to `FlutterMethodNotImplemented`. Since the Dart method doesn't await or handle the channel result, this failure is silent to the caller.
- Documented as "Android Only!" in `doc/API.md`, confirming this is a deliberate platform restriction rather than an oversight — but the Dart API surface gives no compile-time signal of this, so cross-platform code calling it unconditionally will throw on iOS at the channel layer.
- Depends on `activity` and `activity.getIntent()` being non-null at call time; if the Flutter engine is detached from its activity (e.g. during a configuration change), the call errors out natively but this is invisible to the fire-and-forget Dart caller.

---

## Dependencies
```mermaid
flowchart LR
    F014["F-014 · Manual Deep-Link Re-trigger"]:::deepLinking -->|"result surfaces through"| F037["F-037 · Unified Deep Linking (UDL) Callback & Models"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
