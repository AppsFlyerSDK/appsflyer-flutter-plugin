---
id: F-046
name: Disable Network Data Transfer
type: sdkCore
platform: android
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Carrier/SIM operator name are device-level signals some privacy-conscious apps or regulatory regimes want excluded from what's sent to AppsFlyer, even while the rest of the SDK (attribution, events) stays fully active. `setDisableNetworkData` lets an Android app opt out of collecting the network operator name (carrier) and SIM operator name from the device, without having to disable the SDK (F-017) or anonymize the user (F-013) entirely.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app during startup configuration whenever the app needs to opt out of carrier/SIM-operator-name collection for privacy-compliance reasons — Android only.

---

## Call Chain
```
AppsflyerSdk.setDisableNetworkData(disable)                            [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setDisableNetworkData", disable)
    → Android: AppsflyerSdkPlugin.onMethodCall("setDisableNetworkData") → setDisableNetworkData(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setDisableNetworkData(disable)
```
No iOS branch exists for `"setDisableNetworkData"` in `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m`'s `handleMethodCall:` — the call falls through to `result(FlutterMethodNotImplemented)`.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setDisableNetworkData(bool)` — no `Platform.isAndroid` guard |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setDisableNetworkData(call, result)`, line 520 |
| `doc/API.md` | Documents the method as **"Android Only!"** and describes it as opting out of "collecting the network operator name (carrier) and sim operator name from the device" |

---

## Input / Output
| | |
|--|--|
| **Input** | `disable` (bool) — `true` opts out of network/carrier data collection; `false` keeps default collection behavior. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setDisableNetworkData call` (line 314) asserts the mocked channel receives `'setDisableNetworkData'`. Test runs only through the Dart mock channel and cannot distinguish Android vs. iOS native behavior.

---

## Known Limitations
- **Android-only**: no corresponding native implementation on iOS. Calling this from a Flutter app running on iOS results in a `MissingPluginException`/`FlutterMethodNotImplemented` at the native layer, since the Dart API has no platform guard. The official docs correctly flag it "Android Only!" with a usage example wrapped in `if (Platform.isAndroid)`, but nothing in the Dart API itself enforces or warns about this.
- The Dart method name (`setDisableNetworkData`) is broader-sounding than its actual, narrower scope (carrier/SIM operator name only, per `doc/API.md`) — an integrator relying on the method name alone could over-assume it disables all "network data" transfer generally.

---

## Dependencies
```mermaid
flowchart LR
    F046["F-046 · Disable Network Data Transfer"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
