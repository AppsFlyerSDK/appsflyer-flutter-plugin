---
id: F-046
name: Disable Network Data Transfer
type: sdkCore
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Carrier/SIM operator name are device-level signals some privacy-conscious apps or regulatory regimes want excluded from what's sent to AppsFlyer, even while the rest of the SDK (attribution, events) stays fully active. `setDisableNetworkData` lets an Android app opt out of collecting the network operator name (carrier) and SIM operator name from the device, without having to disable the SDK (F-017) or anonymize the user (F-013) entirely.

---

## Trigger
Called by the host app during startup configuration whenever the app needs to opt out of carrier/SIM-operator-name collection for privacy-compliance reasons — Android only.

---

## Call Chain
The Dart method is Android-only. On iOS the call is ignored with a logged warning and no RPC is dispatched.

```
AppsFlyerSdk.setDisableNetworkData(isDisable)                          [lib/src/appsflyer_sdk.dart]
  → not Android: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setDisableNetworkData', {'isDisable': isDisable})
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'setDisableNetworkData', params:{isDisable}})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler   [android/.../AppsflyerSdkPlugin.java]
        → AppsFlyerLib.getInstance().setDisableNetworkData(disable)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `Future<void> setDisableNetworkData(bool isDisable)` — guarded by an Android platform check |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | RPC bridge entry (`executeRpc`) routing `setDisableNetworkData` to `AppsFlyerRpcHandler` |
| `doc/api-reference.md` | Documents the method as **"Android Only!"** and describes it as opting out of "collecting the network operator name (carrier) and sim operator name from the device" |

---

## Input / Output
| | |
|--|--|
| **Input** | `isDisable` (bool) — `true` opts out of network/carrier data collection; `false` keeps default collection behavior. Sent under the `isDisable` param key. |
| **Output** | On Android, `Future<void>` completes after RPC validation and synchronous SDK invocation, with no native completion callback or timeout. Validation or bridge failures throw `AppsFlyerException`. Off Android the call is ignored with a logged warning and no RPC is dispatched. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setDisableNetworkData(true)` dispatches RPC method `setDisableNetworkData` with `{'isDisable': true}`. `'platform-only void calls are ignored without reaching the native RPC'` calls `setDisableNetworkData(true)` on iOS and asserts that no RPC method is dispatched.

---

## Known Limitations
- **Android-only**: calling the Dart method on iOS is a no-op, but a logged one — the plugin emits a `debugPrint` warning and dispatches no RPC. There is no iOS equivalent in the native SDK.
- The Dart method name (`setDisableNetworkData`) is broader-sounding than its actual, narrower scope (carrier/SIM operator name only, per `doc/api-reference.md`) — an integrator relying on the method name alone could over-assume it disables all "network data" transfer generally.

---

## Dependencies
```mermaid
flowchart LR
    F046["F-046 · Disable Network Data Transfer"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
