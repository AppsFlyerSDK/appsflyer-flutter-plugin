---
id: F-067
name: Deep-Link Resolution Timeout
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`setDeepLinkTimeout` controls how long the native SDK waits while resolving a deep-link URL. It is resolution configuration, not the timeout for a Flutter RPC call or the separate session-ready deep-link watchdog.

## Trigger
Call before `init()` when the app needs to override the native default (3000 ms on Android, 60000 ms on iOS).

## Call Chain
```
AppsFlyerSdk.setDeepLinkTimeout(timeout)                              [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setDeepLinkTimeout', {timeout})
    → Android RPC: require timeout > 0 → AppsFlyerLib.setDeepLinkTimeout(timeout)
    → iOS RPC: require timeout >= 0 → native deepLinkTimeout property
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public API, milliseconds unit, defaults, and ordering dartdoc |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Positive-value validation and SDK call |
| iOS `AppsFlyerRPC/.../AFRPCTypedRequests.swift` and `AFRPCComplexConfigHandler.swift` | Non-negative validation and SDK property assignment |

## Input / Output
| | |
|--|--|
| **Input** | `timeout` (`int`) in milliseconds. Android requires `> 0`; iOS accepts `0`, though a positive value is needed for cross-platform consistency. |
| **Output** | `Future<void>` completes after validation and synchronous native configuration. It has no native completion callback or request timeout; validation/bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Dart RPC map. Native RPC suites cover each platform's different zero-value rule.

## Known Limitations
- Dart does not pre-validate the value, so `0` succeeds on iOS and fails on Android.
- Calling after `init()` violates the public ordering contract; the bridge does not detect or report that mistake.
- Do not confuse this value with F-002 awaited-request timeouts or the native session-ready service's own bounded deep-link condition.

## Dependencies
No required feature dependency.
