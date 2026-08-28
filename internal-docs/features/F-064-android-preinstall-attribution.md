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
  → RPC {mediaSource, campaign, siteId}
    → Android: AppsFlyerLib.setPreinstallAttribution(...)
    → iOS: native RPC reports method not found → AppsFlyerException

isPreInstalledApp()
  → _invokeRpc<bool>('isPreInstalledApp')
    → Android: AppsFlyerLib.isPreInstalledApp(context) → boolean reply
    → iOS: native RPC reports method not found → AppsFlyerException (404)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-only setter and `isPreInstalledApp()` getter, both routed through RPC without a Dart guard |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic RPC forwarding |
| Android `plugin_bridge/.../RpcRequest.kt`, `JsonRpcRequestParser.kt`, and `AppsFlyerRpcHandler.kt` | Validation, mapping, native calls, and getter reply |

## Input / Output
| | |
|--|--|
| **Input** | `mediaSource` is required and non-empty; `campaign` and `siteId` are optional strings defaulting to `''`. `isPreInstalledApp()` has no input. |
| **Output** | The setter returns `Future<void>` after synchronous SDK invocation; the getter returns `Future<bool>`. Off Android both throw `AppsFlyerException` when the native RPC layer reports the method as unavailable. On Android an unexpected native null reply also throws instead of being reported as `false`. Bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the setter map and the getter return value. `'platform-only getters surface the native method-not-found error'` covers `isPreInstalledApp()` on iOS; the setter's off-platform path has no dedicated test. Android native parser/handler tests cover validation and forwarding.

## Known Limitations
- Dart does not validate an empty media source; Android RPC rejects it after the channel round trip.
- The setter Future does not confirm that the campaign was included in a Launch. It must run before the relevant `start()`.
- Off-platform calls throw `AppsFlyerException` instead of returning `false`. Unexpected native null replies on Android do the same.

## Dependencies
No required feature dependency; this is configuration consumed by a later F-002 Launch.
