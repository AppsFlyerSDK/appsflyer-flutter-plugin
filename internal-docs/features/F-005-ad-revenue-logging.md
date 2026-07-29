---
id: F-005
name: Ad Revenue Logging
type: eventsAndRevenue
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Apps that monetize through in-app advertising (rather than, or in addition to, direct purchases) need their ad-impression revenue attributed back to the campaigns/media sources that drove the installs — otherwise ROI/LTV reporting only sees purchase revenue and dramatically understates (or misses entirely) the true value of ad-monetized user cohorts. `logAdRevenue` reports a single ad-revenue event (network, mediation platform, currency, amount, optional extra params) to AppsFlyer so that ad monetization can be joined to install attribution the same way in-app purchase events are (see F-004). Removing it would blind AppsFlyer's dashboards to any revenue generated purely through ad impressions/clicks.

---

## Trigger
Called by the host app whenever a mediation SDK (AdMob, AppLovin MAX, ironSource, Unity, etc.) reports a paid ad impression/click, typically from within that mediation SDK's own revenue-paid callback.

---

## Call Chain
Since the SDK 7 / RPC migration this is a generic, fire-and-forget RPC call. `AdRevenueData.toMap()` serializes the fields and remaps the mediation network per platform (see below).
```
AppsflyerSdk.logAdRevenue(AdRevenueData)                                        [lib/src/appsflyer_sdk.dart]
  → _executeRpc('logAdRevenue', adRevenueData.toMap())                         // MethodChannel af-api → executeRpc
    → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc('logAdRevenue', ...) [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerRpcHandler.execute(json) → AppsFlyerLib.logAdRevenue(...)      [plugin_bridge module]
    → iOS: AppsflyerSdkPlugin.executeRpc → dispatchRpc:method:@"logAdRevenue"   [ios/.../AppsflyerSdkPlugin.m]
      → [AppsFlyerRPCBridge shared] executeJson:completion: → AFRPCRequestHandler → SDK
```

---

## Cross-platform mediation-network quirk
`AdRevenueData.toMap()` calls `mediationNetworkForPlatform(mediationNetwork, isIOS: Platform.isIOS)`. `AFMediationNetwork.customMediation` and `AFMediationNetwork.directMonetizationNetwork` serialize (via `.value`) to `custom_mediation` / `direct_monetization_network`. Those resolve on the Android bridge (matched by enum name) but are rejected by the iOS parser, which strips underscores and expects `custom` / `directmonetization`. So for iOS only, those two values are remapped:

| `AFMediationNetwork` | `.value` (Android) | Remapped for iOS |
|--|--|--|
| `customMediation` | `custom_mediation` | `custom` |
| `directMonetizationNetwork` | `direct_monetization_network` | `directmonetization` |

Every other value passes through unchanged.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `logAdRevenue(AdRevenueData)` — Dart public API, `void`, serializes via `adRevenueData.toMap()` |
| `lib/src/appsflyer_ad_revenue_data.dart` | `AdRevenueData` model: `monetizationNetwork`, `mediationNetwork` (String), `currencyIso4217Code`, `revenue` (double), optional `additionalParameters`; `mediationNetworkForPlatform(value, {isIOS})` implements the iOS remap |
| `lib/src/appsflyer_constants.dart` | `AFMediationNetwork` enum with a `.value` getter mapping each case (e.g. `applovinMax` → `"applovin_max"`) to the canonical string |
| `android/.../AppsflyerSdkPlugin.java` | No per-method handler — generic `executeRpc` → `dispatchRpc('logAdRevenue', ...)` |
| `ios/.../AppsflyerSdkPlugin.m` | No per-method handler — generic `executeRpc` → `dispatchRpc` |
| `doc/api-reference.md` | `logAdRevenue` / `AdRevenueData` / `AFMediationNetwork` public documentation |

---

## Input / Output
| | |
|--|--|
| **Input** | `monetizationNetwork` (String, required); `mediationNetwork` (String, required — prefer `AFMediationNetwork.value`); `currencyIso4217Code` (String, ISO 4217, required); `revenue` (double, required); `additionalParameters` (Map, optional) |
| **Output** | `void` — fire-and-forget. Errors (including a rejected/unknown `mediationNetwork`) are not surfaced to Dart, so always pass a known `AFMediationNetwork` value |

---

## Tests
`test/appsflyer_sdk_test.dart`:
- `logAdRevenue forwards the flat ad-revenue map` — constructs `AdRevenueData` with `AFMediationNetwork.applovinMax.value`, asserts the `logAdRevenue` RPC is dispatched with `mediationNetwork == 'applovin_max'`.
- `AdRevenueData.mediationNetworkForPlatform (CR-055)` group — verifies `customMediation`/`directMonetizationNetwork` remap to `custom`/`directmonetization` on iOS, pass through unchanged on Android, and other values are untouched.

---

## Known Limitations
- **String-based mediation network mapping is duplicated** (Dart `AFMediationNetwork.value` plus the native RPC parsers) with no shared source of truth — a new mediation network requires coordinated updates, and a mismatch fails as an "unsupported network" at runtime rather than at compile time.
- No compile-time guarantee that `AdRevenueData.mediationNetwork` (a plain `String`) was built from `AFMediationNetwork.value` — an arbitrary string compiles fine and only fails at the native layer.
- Fire-and-forget: a rejected `mediationNetwork` (or any other native error) is not reported back to the Dart caller.

---

## Dependencies
```mermaid
flowchart LR
    F005["F-005 · Ad Revenue Logging"]:::eventsAndRevenue
    classDef eventsAndRevenue fill:#12B886,color:#fff
```
