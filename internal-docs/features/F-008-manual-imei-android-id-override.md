---
id: F-008
name: Manual IMEI/Android ID Override
type: sdkCore
platform: android
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Some apps already collect IMEI/Android ID themselves (e.g. via a legacy device-management SDK) and want AppsFlyer to reuse those values rather than re-reading them independently, or need to supply a value in contexts where the SDK's own read would fail (e.g. restricted permission states). `setImeiData`/`setAndroidIdData` let the host app hand these identifiers to the SDK directly instead of relying on its automatic collection (F-007 governs whether that automatic collection happens at all).

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app during startup configuration when it already holds IMEI/Android ID values it wants to feed to AppsFlyer, in place of the SDK's own device-level collection.

---

## Call Chain
```
AppsflyerSdk.setImeiData(imei)                                          [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setImeiData", {'imei': imei})
    → Android: AppsflyerSdkPlugin.onMethodCall("setImeiData") → setImeiData(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setImeiData(imei)

AppsflyerSdk.setAndroidIdData(androidId)                                [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setAndroidIdData", {'androidId': androidId})
    → Android: AppsflyerSdkPlugin.onMethodCall("setAndroidIdData") → setAndroidIdData(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setAndroidIdData(androidId)
```
No iOS branch exists for either method name in `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m`'s `handleMethodCall:`.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setImeiData(String)`, `setAndroidIdData(String)` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setImeiData`, `setAndroidIdData` native handlers |

---

## Input / Output
| | |
|--|--|
| **Input** | `setImeiData`: `imei` (String). `setAndroidIdData`: `androidId` (String). |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setImeiData call` (line 272) and `check setAndroidIdData call` (line 278) assert the mocked channel receives the respective method names. No assertion on the argument values actually reaching native code (only channel dispatch is exercised, per the test's mock architecture).

---

## Known Limitations
- **Android-only**: no iOS implementation (IMEI/Android ID are not applicable identifiers on iOS). Same `MissingPluginException`/`FlutterMethodNotImplemented` risk as F-007 if called on iOS, since the Dart API is not platform-guarded.
- No format/length validation of the `imei`/`androidId` strings before they are handed to the native SDK — a malformed value would only surface as a data-quality problem downstream in AppsFlyer's reporting, not as a client-side error.

---

## Dependencies
```mermaid
flowchart LR
    F008["F-008 · Manual IMEI/Android ID Override"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
