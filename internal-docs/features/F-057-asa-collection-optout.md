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
The host app calls `setDisableCollectASA(true)` and, when full Apple Ads attribution suppression is required, `setDisableAppleAdsAttribution(true)` before `start()`. Neither method requires `init()` to have run first. Both are iOS-only; on Android each is ignored with a logged warning and no RPC is dispatched.

---

## Call Chain
Both methods are ordinary fire-and-forget RPC setters that return `Future<void>`. The iOS platform guard runs in Dart before any channel call is made.

```
AppsFlyerSdk.setDisableCollectASA(disable)                            [lib/src/appsflyer_sdk.dart]
  → not iOS: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setDisableCollectASA', {'disable': disable})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge.executeJson
        → native Apple Search Ads collection opt-out
  → PlatformException is converted to AppsFlyerException

# iOS-only companion
AppsFlyerSdk.setDisableAppleAdsAttribution(disable)                   [lib/src/appsflyer_sdk.dart]
  → not iOS: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setDisableAppleAdsAttribution', {'disable': disable})
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableCollectASA(bool disable)` and `setDisableAppleAdsAttribution(bool disable)`, both guarded by an iOS platform check |
| `lib/src/appsflyer_exception.dart` | `AppsFlyerException` for native failures |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Generic `executeRpc` → `dispatchRpc` forwarding to `AppsFlyerRPCBridge`; no per-method handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `disable` (`bool`) sent under the `disable` param key for both methods. |
| **Output** | `Future<void>` completes after RPC validation and the synchronous native SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or timeout. On Android the call is ignored with a logged warning and no RPC is dispatched. |

---

## Tests
`test/appsflyer_sdk_test.dart` covers both the mapping and the platform guard:
- `iOS ASA collection is configured through an explicit setter` asserts that `iosSdk.setDisableCollectASA(true)` dispatches RPC method `setDisableCollectASA` with `{'disable': true}`.
- `maps every iOS-only API` re-asserts the same mapping alongside `setDisableAppleAdsAttribution` with `{'disable': true}`.
- `platform-only void calls are ignored without reaching the native RPC` asserts that `androidSdk.setDisableCollectASA(true)` and `androidSdk.setDisableAppleAdsAttribution(true)` dispatch no RPC.

---

## Known Limitations
- Apple Search Ads has no Android equivalent, so there is no Android behavior to configure; the Dart layer makes the Android call a logged no-op rather than a silent one — a warning is printed and no RPC is dispatched.
- Fully suppressing ASA on iOS requires **both** `setDisableCollectASA(true)` and `setDisableAppleAdsAttribution(true)`.
- No getter exists to confirm whether ASA collection is currently disabled.
- The native API has no completion callback, so a completed `Future` confirms only that the RPC layer accepted the call.

---

## Dependencies
No required feature dependency. Both settings are runtime properties that must be applied before the first `start()` they should affect.
