---
id: F-064
name: Android Preinstall Attribution and Detection
type: platformIntegration
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
OEM and manufacturer-distributed apps can explicitly label a preinstall campaign with `setPreinstallAttribution` and query native preinstall detection with `isPreInstalledApp()`.

## Trigger
Call `setPreinstallAttribution` on Android before the first `start()` when the app has OEM campaign metadata. Call `isPreInstalledApp()` when the app needs the native SDK's current preinstall classification.

## Call Chain
```
setPreinstallAttribution(mediaSource, campaign:, siteId:)
  → Android guard → RPC {mediaSource, campaign, siteId}
    → AppsFlyerLib.setPreinstallAttribution(...)

isPreInstalledApp()
  → _invokeRpc<bool>('isPreInstalledApp')
    → Android: AppsFlyerLib.isPreInstalledApp(context) → boolean reply
    → iOS: native RPC reports method not found → AppsFlyerException (404)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-only setter with an off-platform guard; `isPreInstalledApp()` routes through RPC without a Dart guard |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic RPC forwarding |
| Android `plugin_bridge/.../RpcRequest.kt`, `JsonRpcRequestParser.kt`, and `AppsFlyerRpcHandler.kt` | Validation, mapping, native calls, and getter reply |

## Input / Output
| | |
|--|--|
| **Input** | `mediaSource` is required and non-empty; `campaign` and `siteId` are optional strings defaulting to `''`. `isPreInstalledApp()` has no input. |
| **Output** | The setter returns `Future<void>` after synchronous SDK invocation; the getter returns `Future<bool>`. Off Android the setter is a logged no-op; the getter throws `AppsFlyerException` when the native RPC layer reports the method as unavailable. Bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the setter map, getter return value, and the setter off-platform guard. `'symmetric platform-only getters surface RPC method-not-found off-platform'` covers `isPreInstalledApp()` on iOS. Android native parser/handler tests cover validation and forwarding.

## Known Limitations
- Dart does not validate an empty media source; Android RPC rejects it after the channel round trip.
- The setter Future does not confirm that the campaign was included in a Launch. It must run before the relevant `start()`.
- Off-platform `false` from `isPreInstalledApp()` is no longer returned; wrong-platform calls throw `AppsFlyerException` instead.

## Dependencies
No required feature dependency; this is configuration consumed by a later F-002 Launch.
