---
id: F-069
name: Android Facebook Attribution ID Retrieval
type: platformIntegration
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`getAttributionId()` exposes the Facebook attribution ID visible to the Android native SDK, when available. It is a diagnostic/integration getter and is separate from F-032 Facebook deferred app links.

## Trigger
Called on demand on Android when the app needs the native Facebook attribution identifier.

## Call Chain
```
AppsFlyerSdk.getAttributionId()                                      [lib/src/appsflyer_sdk.dart]
  → non-Android: log warning and return null
  → _invokeRpc<String>('getAttributionId', {})
    → Android AppsFlyerRpcHandler → AppsFlyerLib.getAttributionId(context)
      → nullable string reply
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-guarded nullable getter |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic RPC forwarding and reply serialization |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Getter request and native SDK call |

## Input / Output
| | |
|--|--|
| **Input** | None; the RPC params map is empty. |
| **Output** | `Future<String?>` with the native value or `null`. Off Android it logs a warning and returns `null` without dispatching RPC. Bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android native-return mapping and the off-platform `null` guard. Android handler tests verify the context-based SDK call.

## Known Limitations
- `null` can mean unavailable on Android or unsupported platform; the log is the only distinction for the latter.
- The Flutter plugin does not fetch, generate, validate, or persist this ID itself.

## Dependencies
No required feature dependency.
