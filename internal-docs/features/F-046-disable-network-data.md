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
The Dart method is Android-only but is not gated in Dart. On iOS the call is still dispatched and throws `AppsFlyerException`, because the iOS RPC layer does not implement the method.

```
AppsFlyerSdk.setDisableNetworkData(isDisable)                          [lib/src/appsflyer_sdk.dart]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('setDisableNetworkData', {'isDisable': isDisable})
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'setDisableNetworkData', params:{isDisable}})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc → AppsFlyerRpcHandler   [android/.../AppsflyerSdkPlugin.kt]
        → AppsFlyerLib.getInstance().setDisableNetworkData(disable)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `Future<void> setDisableNetworkData(bool isDisable)` — dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | RPC bridge entry (`executeRpc`) routing `setDisableNetworkData` to `AppsFlyerRpcHandler` |
| `doc/api-reference.md` | Documents the method as **"Android Only!"** and describes it as opting out of "collecting the network operator name (carrier) and sim operator name from the device" |

---

## Input / Output
| | |
|--|--|
| **Input** | `isDisable` (bool) — `true` opts out of network/carrier data collection; `false` keeps default collection behavior. Sent under the `isDisable` param key. |
| **Output** | On Android, `Future<void>` completes after RPC validation and synchronous SDK invocation, with no native completion callback or timeout. Validation or bridge failures throw `AppsFlyerException`. Off Android the call is still dispatched and throws `AppsFlyerException` once the native RPC layer reports the method as unavailable. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps every Android-only API'` verifies that `setDisableNetworkData(true)` dispatches RPC method `setDisableNetworkData` with `{'isDisable': true}`. No test exercises `setDisableNetworkData` off Android; the shared off-platform contract is covered generically by `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'` and `'platform-only setters surface the native error'`, which use other Android-only setters.

---

## Known Limitations
- **Android-only**: there is no iOS equivalent in the native SDK, and the plugin no longer blocks the call in Dart — calling the Dart method on iOS dispatches the RPC and throws `AppsFlyerException` when the iOS RPC layer reports the method as unavailable.
- The Dart method name (`setDisableNetworkData`) is broader-sounding than its actual, narrower scope (carrier/SIM operator name only, per `doc/api-reference.md`) — an integrator relying on the method name alone could over-assume it disables all "network data" transfer generally.

---

## Dependencies
```mermaid
flowchart LR
    F046["F-046 · Disable Network Data Transfer"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
