---
id: F-057
name: ASA (Apple Search Ads) Collection Opt-out
type: sdkCore
platform: ios
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
The native iOS SDK automatically queries Apple's Search Ads Attribution API (ASA) to enrich attribution data for installs originating from Apple Search Ads campaigns. Some apps — for privacy or compliance reasons, or because they do not run Apple Search Ads campaigns and want to avoid the extra API call and data collection — need to opt out of this automatic collection. `setDisableCollectASA` is the iOS-only switch that turns it off. A companion iOS-only method, `setDisableAppleAdsAttribution(bool disable)`, dispatches the `setDisableAppleAdsAttribution` RPC; the iOS SDK needs **both** to fully suppress Apple Search Ads attribution.

---

## Trigger
The host app calls `setDisableCollectASA(true)` and, when full Apple Ads attribution suppression is required, `setDisableAppleAdsAttribution(true)` before `start()`. Neither method requires `init()` to have run first. Both are iOS-only; on Android each is still dispatched and throws `AppsFlyerException`, because the Android RPC layer does not implement the method.

---

## Call Chain
Both methods are ordinary fire-and-forget RPC setters that return `Future<void>`. Neither is gated in Dart, so the channel call is made on every platform and the native RPC layer decides whether the method exists.

```
AppsFlyerSdk.setDisableCollectASA(disable)                            [lib/src/appsflyer_sdk.dart]
  → off iOS: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('setDisableCollectASA', {'disable': disable})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge.executeJson
        → native Apple Search Ads collection opt-out
  → PlatformException is converted to AppsFlyerException

# iOS-only companion
AppsFlyerSdk.setDisableAppleAdsAttribution(disable)                   [lib/src/appsflyer_sdk.dart]
  → off iOS: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('setDisableAppleAdsAttribution', {'disable': disable})
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableCollectASA(bool disable)` and `setDisableAppleAdsAttribution(bool disable)`, both dispatched through RPC without a Dart platform check |
| `lib/src/appsflyer_exception.dart` | `AppsFlyerException` for native failures |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Generic `executeRpc` → `dispatchRpc` forwarding to `AppsFlyerRPCBridge`; no per-method handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `disable` (`bool`) sent under the `disable` param key for both methods. |
| **Output** | `Future<void>` completes after RPC validation and the synchronous native SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or timeout. On Android the call is still dispatched and throws `AppsFlyerException` once the RPC layer reports the method as unavailable. |

---

## Tests
`test/appsflyer_sdk_test.dart` covers both the mapping and the off-platform behavior:
- `iOS ASA collection is configured through an explicit setter` asserts that `iosSdk.setDisableCollectASA(true)` dispatches RPC method `setDisableCollectASA` with `{'disable': true}`.
- `maps every iOS-only API` re-asserts the same mapping alongside `setDisableAppleAdsAttribution` with `{'disable': true}`.
- `platform-only calls are forwarded to the native RPC instead of being swallowed in Dart` asserts that `androidSdk.setDisableCollectASA(true)` still dispatches the `setDisableCollectASA` RPC; the off-platform path of `setDisableAppleAdsAttribution` is not covered separately.

---

## Known Limitations
- Apple Search Ads has no Android equivalent, so there is no Android behavior to configure; the Dart layer does not block the Android call, which therefore reaches the Android RPC layer and throws `AppsFlyerException` rather than doing nothing.
- Fully suppressing ASA on iOS requires **both** `setDisableCollectASA(true)` and `setDisableAppleAdsAttribution(true)`.
- No getter exists to confirm whether ASA collection is currently disabled.
- The native API has no completion callback, so a completed `Future` confirms only that the RPC layer accepted the call.

---

## Dependencies
No required feature dependency. Both settings are runtime properties that must be applied before the first `start()` they should affect.
