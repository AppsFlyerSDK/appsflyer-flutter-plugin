---
id: F-005
name: Ad Revenue Logging
type: eventsAndRevenue
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Apps that monetize through in-app advertising (rather than, or in addition to, direct purchases) need their ad-impression revenue attributed back to the campaigns/media sources that drove the installs — otherwise ROI/LTV reporting only sees purchase revenue and dramatically understates (or misses entirely) the true value of ad-monetized user cohorts. `logAdRevenue` reports a single ad-revenue event (network, mediation platform, currency, amount, optional extra params) to AppsFlyer so that ad monetization can be joined to install attribution the same way in-app purchase events are (see F-004). Removing it would blind AppsFlyer's dashboards to any revenue generated purely through ad impressions/clicks.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app whenever a mediation SDK (AdMob, AppLovin MAX, ironSource, Unity, etc.) reports a paid ad impression/click, typically from within that mediation SDK's own revenue-paid callback.

---

## Call Chain
```
AppsflyerSdk.logAdRevenue(AdRevenueData)                                                          [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("logAdRevenue", adRevenueData.toMap())
    → Android: AppsflyerSdkPlugin.onMethodCall("logAdRevenue") → logAdRevenue(call, result)        [android/.../AppsflyerSdkPlugin.java]
      → MediationNetwork.valueOf(mediationNetworkString.toUpperCase(Locale.ENGLISH))
      → new AFAdRevenueData(monetizationNetwork, mediationNetwork, currencyIso4217Code, revenue)
      → AppsFlyerLib.getInstance().logAdRevenue(adRevenueData, additionalParameters)
      → result.success(true)  |  result.error(...) on invalid/unexpected input
    → iOS: AppsflyerSdkPlugin.handleMethodCall("logAdRevenue") → logAdRevenue:result:               [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → getEnumValueFromString: maps the Dart enum's string value to AppsFlyerAdRevenueMediationNetworkType
      → [[AFAdRevenueData alloc] initWithMonetizationNetwork:mediationNetwork:currencyIso4217Code:eventRevenue:]
      → [[AppsFlyerLib shared] logAdRevenue:additionalParameters:]
      → (no result(...) call on the success path; result(...) is only invoked on error)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `logAdRevenue(AdRevenueData)` — Dart public API, `void`, serializes via `adRevenueData.toMap()` |
| `lib/src/appsflyer_ad_revenue_data.dart` | `AdRevenueData` model: `monetizationNetwork`, `mediationNetwork` (String), `currencyIso4217Code`, `revenue` (double), optional `additionalParameters` |
| `lib/src/appsflyer_constants.dart` | `AFMediationNetwork` enum with a `.value` getter mapping each case (e.g. `applovinMax`) to the exact lowercase/snake_case string (`"applovin_max"`) both native sides expect |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `logAdRevenue(MethodCall, Result)` — validates required args via `requireNonNullArgument`, converts the mediation-network string to the native `MediationNetwork` enum via `.valueOf(...toUpperCase())`, builds `AFAdRevenueData`, calls `AppsFlyerLib.getInstance().logAdRevenue(...)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `logAdRevenue:result:` and `getEnumValueFromString:` — validates required args, maps the mediation-network string to `AppsFlyerAdRevenueMediationNetworkType` via an explicit `NSDictionary` lookup table, builds `AFAdRevenueData`, calls `[[AppsFlyerLib shared] logAdRevenue:additionalParameters:]` |
| `doc/API.md` | `logAdRevenue` / `AdRevenueData` / `AFMediationNetwork` public documentation and usage example |

---

## Input / Output
| | |
|--|--|
| **Input** | `monetizationNetwork` (String, required — the ad network the impression came from, e.g. "GoogleAdMob"); `mediationNetwork` (String, required — must equal one of `AFMediationNetwork.value`'s outputs, e.g. `"applovin_max"`); `currencyIso4217Code` (String, required); `revenue` (double, required); `additionalParameters` (Map, optional) |
| **Output** | Android: `Future` (unused by the `void` Dart method) resolving `result.success(true)` on success, or `result.error("INVALID_ARGUMENT_PROVIDED", ...)` for a missing/unrecognized field, or `result.error("UNEXPECTED_ERROR", ...)` for any other throwable. iOS: `result(...)` is only ever invoked on the error paths (`FlutterError` with codes such as `NULL_MONETIZATION_NETWORK`, `INVALID_MEDIATION_NETWORK`, `UNEXPECTED_ERROR`); on success the method returns without calling `result` at all. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check logAdRevenue call` (line 296) constructs an `AdRevenueData` with `AFMediationNetwork.applovinMax.value`, calls `logAdRevenue`, and asserts the mocked channel receives `logAdRevenue` with `mediationNetwork == 'applovin_max'`. This exercises only the Dart-to-channel dispatch and the enum-to-string mapping; it does not exercise either native handler's mediation-network parsing/validation logic.

---

## Known Limitations
- **String-based mediation network mapping is duplicated three times** (Dart `AFMediationNetwork.value`, Android's `MediationNetwork.valueOf(...toUpperCase())`, iOS's hand-written `NSDictionary` in `getEnumValueFromString:`) with no shared source of truth — adding a new mediation network requires updating all three in lockstep, and a mismatch (e.g. a typo in one map) fails silently as an "unsupported network" error at runtime rather than a compile-time error.
- **iOS never resolves the Flutter result on success**: in `logAdRevenue:result:`, the success path calls `[[AppsFlyerLib shared] logAdRevenue:additionalParameters:]` and returns without ever calling `result(...)`. Since the Dart-side `logAdRevenue` is `void` and does not await a result, this is silent to callers today, but it means the platform channel's pending reply is simply never resolved on the happy path — asymmetric with Android, which always calls `result.success(true)`.
- Android's mediation-network parsing uses `.toUpperCase(Locale.ENGLISH)` then `MediationNetwork.valueOf(...)`; any string that doesn't exactly match a native enum constant after upper-casing (e.g. an unexpected value from a future `AFMediationNetwork` addition) throws `IllegalArgumentException`, caught and surfaced as `INVALID_ARGUMENT_PROVIDED` — but only after the Dart caller has already committed to that string via the shared enum, so failures depend on the plugin's native SDK dependency version staying in sync with `AFMediationNetwork`.
- No compile-time guarantee that `AdRevenueData.mediationNetwork` (a plain `String`) was actually built from `AFMediationNetwork.value` — passing an arbitrary string compiles fine and only fails at the native layer.

---

## Dependencies
```mermaid
flowchart LR
    F005["F-005 · Ad Revenue Logging"]:::eventsAndRevenue
    classDef eventsAndRevenue fill:#12B886,color:#fff
```
