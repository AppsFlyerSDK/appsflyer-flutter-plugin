---
id: F-020
name: AppsFlyer UID Retrieval
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Every install gets a unique AppsFlyer-generated device/install ID, which is the primary key AppsFlyer uses internally to tie together attribution, in-app events, and reporting for that install. Host apps often need this same ID for their own backend correlation (e.g. sending it alongside server-side purchase records, or cross-referencing support tickets with AppsFlyer's dashboard/raw-data reports). `getAppsFlyerUID()` is the only supported way to read that ID from Dart.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called on demand by the host app — typically after SDK init, to attach the AppsFlyer ID to internal analytics, support diagnostics, or server-side event payloads.

---

## Call Chain
```
AppsflyerSdk.getAppsFlyerUID()                                        [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("getAppsFlyerUID")
    → Android: AppsflyerSdkPlugin.onMethodCall("getAppsFlyerUID") → getAppsFlyerUID(result)   [android/.../AppsflyerSdkPlugin.java]
      → result.success(AppsFlyerLib.getInstance().getAppsFlyerUID(mContext))
    → iOS: AppsflyerSdkPlugin.handleMethodCall("getAppsFlyerUID") → getAppsFlyerUID:result:   [ios/Classes/AppsflyerSdkPlugin.m]
      → result([[AppsFlyerLib shared] getAppsFlyerUID])
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `getAppsFlyerUID()` — `Future<String?>` async round-trip |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `getAppsFlyerUID(result)`, line 797 |
| `ios/Classes/AppsflyerSdkPlugin.m` | `getAppsFlyerUID:result:`, line 602 |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `Future<String?>` — the AppsFlyer-generated unique ID for this install; may resolve to `null`/empty if the SDK has not finished initializing/generating the ID yet. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check getAppsFlyerUID call` (line 198) asserts the mocked channel receives `'getAppsFlyerUID'`. The test does not stub a return value, so the resolved-ID contract (nullable String) is not exercised.

---

## Known Limitations
- No documented guarantee of the ID's availability timing relative to `initSdk()`/`startSDK()` — calling it too early (before the native SDK has generated/persisted the ID) can return an empty string or `null` depending on platform/SDK version, and the Dart API gives no way to await "ID ready."
- No test coverage of the actual resolved value or of null/empty-string edge cases on either platform.

---

## Dependencies
```mermaid
flowchart LR
    F020["F-020 · AppsFlyer UID Retrieval"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
