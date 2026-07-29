---
id: F-046
name: Disable Network Data Transfer
type: sdkCore
platform: android
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Carrier/SIM operator name are device-level signals some privacy-conscious apps or regulatory regimes want excluded from what's sent to AppsFlyer, even while the rest of the SDK (attribution, events) stays fully active. `setDisableNetworkData` lets an Android app opt out of collecting the network operator name (carrier) and SIM operator name from the device, without having to disable the SDK (F-017) or anonymize the user (F-013) entirely.

---

## Trigger
Called by the host app during startup configuration whenever the app needs to opt out of carrier/SIM-operator-name collection for privacy-compliance reasons — Android only.

---

## Call Chain
The Dart method is guarded by `Platform.isAndroid`, so it is a no-op on iOS (no RPC is dispatched).

```
AppsflyerSdk.setDisableNetworkData(disable)                            [lib/src/appsflyer_sdk.dart]
  → if (Platform.isAndroid) _executeRpc('setDisableNetworkData', {'isDisable': disable})
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'setDisableNetworkData', params:{isDisable}})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler   [android/.../AppsflyerSdkPlugin.java]
        → AppsFlyerLib.getInstance().setDisableNetworkData(disable)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableNetworkData(bool)` — guarded by `Platform.isAndroid` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | RPC bridge entry (`executeRpc`) routing `setDisableNetworkData` to `AppsFlyerRpcHandler` |
| `doc/api-reference.md` | Documents the method as **"Android Only!"** and describes it as opting out of "collecting the network operator name (carrier) and sim operator name from the device" |

---

## Input / Output
| | |
|--|--|
| **Input** | `disable` (bool) — `true` opts out of network/carrier data collection; `false` keeps default collection behavior. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setDisableNetworkData call` asserts the mocked `af-api` channel receives `executeRpc` with method `setDisableNetworkData` (host tests exercise the Android branch).

---

## Known Limitations
- **Android-only**: the Dart method is guarded by `Platform.isAndroid`, so on iOS it silently does nothing (no RPC is dispatched). There is no iOS equivalent in the native SDK.
- The Dart method name (`setDisableNetworkData`) is broader-sounding than its actual, narrower scope (carrier/SIM operator name only, per `doc/api-reference.md`) — an integrator relying on the method name alone could over-assume it disables all "network data" transfer generally.

---

## Dependencies
```mermaid
flowchart LR
    F046["F-046 · Disable Network Data Transfer"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
