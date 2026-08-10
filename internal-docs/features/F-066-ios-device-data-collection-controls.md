---
id: F-066
name: iOS Device Data Collection Controls
type: sdkCore
platform: ios
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Two iOS-only privacy controls govern device metadata: `setDisableIDFVCollection` opts out of Identifier for Vendor collection, and `setShouldCollectDeviceName` opts into device-name collection, which is disabled by default.

## Trigger
Apply the app's selected values before the first `start()` they should affect. Device-name collection should be enabled only when the app's privacy disclosures and consent basis cover it.

## Call Chain
```
AppsFlyerSdk.setDisableIDFVCollection(disable)
AppsFlyerSdk.setShouldCollectDeviceName(collect)                      [lib/src/appsflyer_sdk.dart]
  → non-iOS: log warning and return
  → _invokeVoidRpc(method, {disable|collect})
    → iOS simple-config RPC handler → native SDK property assignment
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public iOS-guarded APIs and parameter keys |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Generic RPC forwarding |
| iOS `AppsFlyerRPC/.../AFRPCTypedRequests.swift` and `AFRPCSimpleConfigHandler.swift` | Boolean parsing and SDK assignments |
| iOS `AppsFlyerLib/AppsFlyerLib.h` and `AppsFlyerLib.m` | Native properties/default behavior |

## Input / Output
| | |
|--|--|
| **Input** | `disable` (`bool`) for IDFV; `collect` (`bool`) for device name. |
| **Output** | `Future<void>` completes after RPC validation and synchronous native property assignment, with no callback or timeout. Off iOS each call logs, dispatches nothing, and completes normally. |

## Tests
`test/appsflyer_sdk_test.dart` verifies both iOS RPC maps and the Android no-op guards. It does not verify actual identifier/name collection.

## Known Limitations
- Neither setting has a public getter.
- These are native runtime settings; reapply the desired values after a cold start and before the first Launch.
- The Flutter plugin does not add consent UI or privacy-manifest declarations for the host app.

## Dependencies
No required feature dependency.
