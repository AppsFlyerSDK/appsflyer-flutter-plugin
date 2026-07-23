---
id: F-007
name: Device ID Collection Opt-out (IMEI/Android ID)
type: sdkCore
platform: android
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Google Play policy prohibits apps that bundle Google Play Services from collecting IMEI or Android ID for advertising/attribution purposes; only apps without Play Services are allowed to rely on these identifiers as a fallback. `setCollectIMEI`/`setCollectAndroidId` let a Play-Services-enabled app explicitly opt out of this collection so it stays compliant, while apps without Play Services can leave it enabled as their only device-level identifier fallback. Getting this wrong risks Play Store policy violations and app rejection/removal.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app during startup configuration, before or around SDK init, whenever the app needs to explicitly declare its IMEI/Android ID collection posture (typically apps that ship with Google Play Services present).

---

## Call Chain
```
AppsflyerSdk.setCollectIMEI(isCollect)                                  [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setCollectIMEI", {'isCollect': isCollect})
    → Android: AppsflyerSdkPlugin.onMethodCall("setCollectIMEI") → setCollectIMEI(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setCollectIMEI(isCollect)

AppsflyerSdk.setCollectAndroidId(isCollect)                             [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setCollectAndroidId", {'isCollect': isCollect})
    → Android: AppsflyerSdkPlugin.onMethodCall("setCollectAndroidId") → setCollectAndroidId(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setCollectAndroidID(isCollect)
```
No iOS branch exists for either method name in `ios/Classes/AppsflyerSdkPlugin.m`'s `handleMethodCall:` — on iOS these calls fall through to `result(FlutterMethodNotImplemented)`.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCollectIMEI(bool)`, `setCollectAndroidId(bool)` — platform-agnostic Dart API surface (no `Platform.isAndroid` guard) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setCollectIMEI`, `setCollectAndroidId` native handlers |

---

## Input / Output
| | |
|--|--|
| **Input** | `isCollect` (bool) — `true` keeps collection enabled (default SDK behavior), `false` opts out. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setCollectIMEI call` (line 232) and `check setCollectAndroidId call` (line 238) assert the mocked channel receives the respective method names. Tests run in the Dart test harness only, so they cannot and do not distinguish Android vs. iOS native behavior.

---

## Known Limitations
- **Android-only**: there is no corresponding native implementation on iOS (concept doesn't apply — IMEI/Android ID are Android-specific identifiers). Calling these methods from a Flutter app running on iOS results in a `MissingPluginException`/`FlutterMethodNotImplemented` at the native layer, since the Dart API has no platform guard and will happily invoke the channel method regardless of `Platform.isIOS`.
- No compile-time or runtime warning in the Dart layer indicates these are Android-only; integrators must consult documentation (or this catalog) to learn that.

---

## Dependencies
```mermaid
flowchart LR
    F007["F-007 · Device ID Collection Opt-out"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
