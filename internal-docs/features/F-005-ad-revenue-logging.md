---
id: F-005
name: Ad Revenue Logging
type: eventsAndRevenue
platform: both
status: active
last_verified: 2026-08-07
depends_on: []
---

## Business Purpose
Apps that monetize through in-app advertising (rather than, or in addition to, direct purchases) need their ad-impression revenue attributed back to the campaigns and media sources that drove the installs — otherwise ROI/LTV reporting only sees purchase revenue and dramatically understates (or misses entirely) the true value of ad-monetized user cohorts. `logAdRevenue` reports a single ad-revenue event (monetization network, mediation platform, currency, amount, optional extra parameters) to AppsFlyer so that ad monetization can be joined to install attribution the same way in-app purchase events are (see F-004). Removing it would blind AppsFlyer's dashboards to any revenue generated purely through ad impressions and clicks.

---

## Trigger
Called after `init()` whenever a mediation SDK (AdMob, AppLovin MAX, ironSource, Unity, etc.) reports a paid ad impression or click, typically from within that mediation SDK's own revenue-paid callback. Dart and the RPC layers do not enforce initialization ordering before forwarding the call.

---

## Call Chain
`logAdRevenue` takes flat, RPC-aligned named parameters. There is no Dart ad-revenue model class; the Dart layer builds the RPC parameter map inline and converts the typed `AFMediationNetwork` value to its platform-specific string.

```
AppsFlyerSdk.logAdRevenue(...)                                        [lib/src/appsflyer_sdk.dart]
  → mediationNetwork.rpcValue(isIOS: _isIOS)                          [lib/src/appsflyer_constants.dart]
  → _invokeVoidRpc('logAdRevenue', {monetizationNetwork, mediationNetwork,
                                    currencyIso4217Code, revenue,
                                    additionalParameters})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc('logAdRevenue', ...)
        → AppsFlyerRpcHandler.execute(json) → AppsFlyerLib.logAdRevenue(...)
      → iOS: AppsflyerSdkPlugin.executeRpc → dispatchRpc:method:@"logAdRevenue"
        → [AppsFlyerRPCBridge shared] executeJson:completion: → AFRPCRequestHandler → SDK
  → successful per-call reply completes Future<void>
  → PlatformException is converted to AppsFlyerException
```

`logAdRevenue` does not send an `awaitResponse` parameter, so the Future completes after RPC validation and invocation of the void native logging API. It does not confirm that the native SDK accepted or uploaded the event.

---

## Cross-platform mediation-network quirk
`AFMediationNetwork.rpcValue({required bool isIOS})` returns the canonical RPC string for each case (for example `applovinMax` → `"applovin_max"`). Two cases differ between platforms: the iOS RPC parser strips underscores and expects the short forms, while the Android bridge matches the underscored enum names.

| `AFMediationNetwork` | `rpcValue(isIOS: false)` | `rpcValue(isIOS: true)` |
|--|--|--|
| `customMediation` | `custom_mediation` | `custom` |
| `directMonetizationNetwork` | `direct_monetization_network` | `directmonetization` |

Every other value returns the same string on both platforms.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `logAdRevenue({monetizationNetwork, mediationNetwork, currencyIso4217Code, revenue, additionalParameters})` → `Future<void>`; builds the flat RPC parameter map |
| `lib/src/appsflyer_constants.dart` | `AFMediationNetwork` enum and its `rpcValue({required bool isIOS})` platform mapping |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | No per-method handler — generic `executeRpc` → `dispatchRpc('logAdRevenue', ...)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | No per-method handler — generic `executeRpc` → `dispatchRpc` |
| `doc/api-reference.md` | `logAdRevenue` and `AFMediationNetwork` public documentation |

---

## Input / Output
| | |
|--|--|
| **Input** | `monetizationNetwork` (`String`, required and non-empty in both RPC layers); `mediationNetwork` (`AFMediationNetwork`, required — typed, so an unknown network cannot be passed); `currencyIso4217Code` (`String`, required and non-empty; Android RPC additionally requires exactly three characters, while both native SDKs validate that it is an actual ISO 4217 code); `revenue` (`double`, required, with no Dart/RPC range validation); `additionalParameters` (`Map<String, dynamic>?`, optional) |
| **Output** | `Future<void>`. RPC validation and bridge errors surface as `AppsFlyerException`. A completed Future means RPC validation succeeded and the void native logging API was invoked. Native SDK validation failures and upload failures are not returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `ad mediation values preserve native platform naming` calls `logAdRevenue` with `AFMediationNetwork.customMediation` on the Android-configured and iOS-configured SDK instances and asserts the complete RPC parameter map, including `mediationNetwork == 'custom_mediation'` on Android and `'custom'` on iOS.

The `PlatformException becomes AppsFlyerException` test covers the shared `_invokeRpc` error conversion that `logAdRevenue` uses; it exercises that path through `logEvent` rather than through `logAdRevenue`.

---

## Known Limitations
- The mediation-network string mapping is duplicated between Dart (`AFMediationNetwork.rpcValue`) and the native RPC parsers, with no shared source of truth. A newly supported mediation network requires coordinated updates on both sides, and a mismatch fails as an "unsupported network" at runtime rather than at compile time.
- Future completion confirms only that the RPC request was validated and forwarded to the native logging API. Android silently ignores the call before SDK initialization, and both native SDKs can discard an invalid currency or payload without reporting that rejection through RPC. The native API also exposes no upload callback.
- Android RPC requires a three-character currency string; iOS RPC requires only a non-empty string. Both native SDKs subsequently validate the actual ISO 4217 code, but native rejection is not surfaced to Dart.
- `additionalParameters` values are untyped (`Map<String, dynamic>`), so an unsupported value can fail in the Flutter platform codec or plugin JSON serialization before reaching the native SDK.

---

## Dependencies
```mermaid
flowchart LR
    F005["F-005 · Ad Revenue Logging"]:::eventsAndRevenue
    classDef eventsAndRevenue fill:#12B886,color:#fff
```
