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
  → _invokeNullableRpc<String?>('getAttributionId', {})
    → Android AppsFlyerRpcHandler → AppsFlyerLib.getAttributionId(context)
      → nullable string reply
    → iOS: native RPC reports method not found → AppsFlyerException (404)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-only nullable getter routed through RPC without a Dart guard |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic RPC forwarding and reply serialization |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Getter request and native SDK call |

## Input / Output
| | |
|--|--|
| **Input** | None; the RPC params map is empty. |
| **Output** | `Future<String?>` with the native value or `null`. Off Android it throws `AppsFlyerException` when the native RPC layer reports the method as unavailable. Bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android native-return mapping. `'symmetric platform-only getters surface RPC method-not-found off-platform'` covers the iOS wrong-platform path. Android handler tests verify the context-based SDK call.

## Known Limitations
- `null` on Android means unavailable; wrong-platform calls throw `AppsFlyerException` instead of returning `null`.
- The Flutter plugin does not fetch, generate, validate, or persist this ID itself.

## Dependencies
No required feature dependency.
