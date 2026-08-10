---
id: F-042
name: Partner Postback Sharing Filter
type: platformIntegration
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
AppsFlyer forwards install/event data to integrated partner networks (ad networks, MMPs, analytics vendors) via server-to-server postbacks and API. Advertisers sometimes need to block that forwarding for specific partners or for all of them — to comply with GDPR/CCPA data-sharing restrictions, honor a user's opt-out choice, or enforce a business rule about which vendors may receive attribution data. `setSharingFilterForPartners` is the API surface for this; without it, the app would have no way to suppress third-party data sharing short of disabling the AppsFlyer SDK entirely via `stop()`, which would also break the advertiser's own attribution.

---

## Trigger
Called by the host app during startup configuration or in direct response to a user consent/opt-out event, whenever the set of partners allowed to receive S2S postback data needs to change.

---

## Call Chain
Awaitable RPC call over the single `executeRpc` entry point. (The legacy `setSharingFilter`/`setSharingFilterForAllPartners` Dart methods no longer exist — SDK 7 exposes only `setSharingFilterForPartners`.)

Clearing the filter — passing `null` or an empty list — is supported on iOS only. On Android the Dart layer logs a warning and returns without dispatching an RPC, leaving the existing filter in place. The two platforms disagree on how a clear is expressed, so Dart normalizes it: the iOS RPC clears only on an explicit `null` and treats a non-null array — empty included — as a set operation, while the Android bridge collapses both forms to a clear it cannot serve. Dart therefore maps an empty list to `null` before dispatch, making `null` and `[]` interchangeable for callers.

```
AppsFlyerSdk.setSharingFilterForPartners(List<String>? partners)         [lib/src/appsflyer_sdk.dart]
  → Android + (partners == null || partners.isEmpty)
      → log warning, return (no RPC dispatched; existing filter unchanged)
  → empty list is normalized to null
  → _invokeVoidRpc('setSharingFilterForPartners', {'partners': partners})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: dispatchRpc → AppsFlyerRpcHandler.execute("setSharingFilterForPartners") → SDK setSharingFilterForPartners
      → iOS: dispatchRpc → AppsFlyerRPCBridge executeJson("setSharingFilterForPartners") → SDK setSharingFilterForPartners:
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `Future<void> setSharingFilterForPartners(List<String>? partners)` — sends the `setSharingFilterForPartners` RPC with `{partners}`; normalizes an empty list to `null`, and ignores a clear request on Android with a logged warning |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | No per-method handler — the generic `executeRpc` → `dispatchRpc` forwards to the native RPC bridge |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | No per-method handler — the generic `executeRpc` → `dispatchRpc` forwards to the native RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `partners` (`List<String>?`) — partner ID strings (e.g. `'facebook_int'`, `'googleadwords_int'`), or the literal `'all'` to block every partner. `null` or an empty list clears the filter (iOS only); both are sent as `null` under the `partners` param key. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or timeout. A clear request on Android completes normally after logging a warning and dispatching nothing. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps cross-platform configuration and identity APIs'` verifies that `setSharingFilterForPartners(['partner'])` dispatches RPC method `setSharingFilterForPartners` with `{'partners': ['partner']}`, and that both `null` and `[]` on iOS dispatch `{'partners': null}` — pinning the empty-to-null normalization. `'Android cannot clear the sharing filter through RPC 7.0.1'` verifies that both `null` and `[]` on Android dispatch no RPC at all.

---

## Known Limitations
- Dart and the RPC request models do not verify that individual partner IDs are recognized. The native SDK can ignore or filter unsupported values without returning a per-ID result, so a typo is not observable through the completed Future.
- Clearing the filter is not reachable on Android through RPC 7.0.1. `SetSharingFilterForPartnersRequest` enforces `require(partners.isNotEmpty())`, so the bridge rejects the only payload that would express a clear. Dart logs and skips the call rather than dispatching a request that cannot be served, which means **an Android filter cannot be undone at runtime** — the app must avoid setting it in the first place. The native Android SDK's own `SharingFilter` does accept an empty set, so this is an RPC-layer gap rather than an SDK limitation.

---

## Dependencies
```mermaid
flowchart LR
    F042["F-042 · Partner Postback Sharing Filter"]:::platformIntegration
    classDef platformIntegration fill:#495057,color:#fff
```
