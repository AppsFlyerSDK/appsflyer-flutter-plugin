---
id: F-044
name: Partner-Specific Data
type: platformIntegration
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Some AppsFlyer-integrated partner networks accept custom, partner-defined fields alongside standard attribution data (e.g. a partner's own user ID, campaign metadata, or other identifiers that only that partner's integration understands). `setPartnerData` lets the host app attach an arbitrary key/value payload to a named partner integration so it gets forwarded on postbacks to that specific partner. Without it, the app would have no way to enrich a specific partner's data beyond what the standard AppsFlyer event/attribution schema carries, limiting partner-side matching, deduplication, or reporting capabilities that depend on partner-specific fields.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app whenever it needs to associate custom data with a named partner integration — typically during startup configuration or when the relevant partner-specific identifiers become available at runtime.

---

## Call Chain
```
AppsflyerSdk.setPartnerData(partnerId, partnerData)                      [lib/src/appsflyer_sdk.dart:630]
  → _methodChannel.invokeMethod("setPartnerData", {'partnerId': partnerId, 'partnersData': partnerData})
    → Android: AppsflyerSdkPlugin.onMethodCall("setPartnerData") → setPartnerData(call, result)   [android/.../AppsflyerSdkPlugin.java:358,546]
      → AppsFlyerLib.getInstance().setPartnerData(partnerId, partnerData)   (only if partnerData != null)
    → iOS: AppsflyerSdkPlugin handleMethodCall: case "setPartnerData" → setPartnerData:result:   [ios/Classes/AppsflyerSdkPlugin.m:161,370]
      → [AppsFlyerLib shared] setPartnerDataWithPartnerId:partnerId partnerInfo:partnersData
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setPartnerData(String partnerId, Map<String, Object> partnerData)` — platform-agnostic Dart API surface |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setPartnerData` native handler |
| `ios/Classes/AppsflyerSdkPlugin.m` | `setPartnerData:result:` native handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `partnerId` (String) — the AppsFlyer partner integration identifier. `partnerData` (`Map<String, Object>`) — arbitrary key/value payload; on Android the handler no-ops if this map is `null`, on iOS an `NSNull` value is normalized to `nil` before being forwarded. |
| **Output** | `void` — fire-and-forget; both native handlers always return success/`nil`. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setPartnerData call` (around line 320) asserts the mocked channel receives `'setPartnerData'` with the `{'partnerId': ..., 'partnersData': ...}` argument map. The Dart test harness cannot verify that native code actually forwards the data to `AppsFlyerLib`/`setPartnerDataWithPartnerId:partnerInfo:`, nor that a given partner integration consumes it correctly.

---

## Known Limitations
- No validation that `partnerId` corresponds to an actual integrated/configured partner — an unrecognized ID silently has no effect (the data is simply never forwarded by that partner's integration).
- Android silently drops the call if `partnerData` is `null` rather than surfacing an error, which can mask integration mistakes; iOS instead normalizes `NSNull` to `nil` and still invokes the native SDK call.
- No schema/type validation on the contents of `partnerData` — arbitrary object values are passed through the channel as-is, so type mismatches would only surface as native-side runtime issues.

---

## Dependencies
```mermaid
flowchart LR
    F044["F-044 · Partner-Specific Data"]:::platformIntegration
    classDef platformIntegration fill:#495057,color:#fff
```
