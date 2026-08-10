---
id: F-061
name: Manual Location Logging
type: eventsAndRevenue
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`logLocation` reports a latitude/longitude pair as the native SDK's location event when an app has a permitted business reason to send location data. It is an explicit app call; the Flutter plugin does not request location permission or collect coordinates itself.

## Trigger
Called after SDK setup when the app has coordinates and the required user permission/consent. The caller is responsible for platform permission handling and privacy disclosure.

## Call Chain
```
AppsFlyerSdk.logLocation(latitude:, longitude:)                       [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('logLocation', {latitude, longitude})
    → MethodChannel('af-api').invokeMethod('executeRpc', envelope)
      → Android RPC validates ranges → AppsFlyerLib.logLocation(context, latitude, longitude)
      → iOS RPC validates ranges → AppsFlyerLib.logLocation(longitude: longitude, latitude: latitude)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public named-parameter API and RPC map |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic Android RPC forwarding |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Generic iOS RPC forwarding |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Range validation and SDK call |
| iOS `AppsFlyerRPC/.../AFRPCTypedRequests.swift` and `AFRPCDataHandler.swift` | Range validation and SDK call, including native longitude-first ordering |

## Input / Output
| | |
|--|--|
| **Input** | `latitude` (`double`, -90...90) and `longitude` (`double`, -180...180). Both native RPC parsers reject out-of-range values. |
| **Output** | `Future<void>` completes after RPC validation and synchronous native SDK invocation. It does not confirm event upload and has no request timeout. Validation/bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the complete Dart RPC map for `logLocation`. Native RPC suites cover range parsing and handler forwarding; the Dart test does not verify upload.

## Known Limitations
- Dart performs no range validation, so invalid coordinates fail only after the channel round trip.
- Raw coordinates cross the Flutter channel. Permission, consent, minimization, and retention decisions belong to the host app and native SDK policy, not this bridge.

## Dependencies
No required feature dependency.
