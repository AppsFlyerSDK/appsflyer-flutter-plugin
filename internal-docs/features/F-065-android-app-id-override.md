---
id: F-065
name: Android App ID Override
type: platformIntegration
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`setAppId` overrides the Android app ID reported by the native SDK for specialized distribution or attribution configurations. It is unrelated to the required iOS Apple App ID passed to `init()`.

## Trigger
Called on Android before the first `start()` when the integration explicitly needs a reporting app-ID override.

## Call Chain
```
AppsFlyerSdk.setAppId(appId)                                         [lib/src/appsflyer_sdk.dart]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeVoidRpc('setAppId', {appId})
    → Android RPC requires non-empty appId
      → AppsFlyerLib.setAppId(appId)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-only API, dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic RPC forwarding |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Non-empty validation and SDK setter |

## Input / Output
| | |
|--|--|
| **Input** | Non-empty Android `appId` (`String`). |
| **Output** | On Android, `Future<void>` completes after validation and synchronous native setter invocation, with no callback or timeout. Off Android the call is still dispatched and throws `AppsFlyerException` once the native RPC layer reports the method as unavailable. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android RPC map and, in `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'`, that a non-Android call is forwarded to the RPC layer rather than swallowed. Android native tests cover parser and handler forwarding.

## Known Limitations
- Dart does not validate an empty value; Android RPC returns the error as `AppsFlyerException`.
- The method name can be confused with iOS `init(appId:)`; the iOS initialization parameter is a different contract.
- No getter confirms the effective override.

## Dependencies
No required feature dependency; the configured value is consumed by subsequent SDK requests.
