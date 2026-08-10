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
  → non-Android: log warning and return
  → _invokeVoidRpc('setAppId', {appId})
    → Android RPC requires non-empty appId
      → AppsFlyerLib.setAppId(appId)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-guarded API |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic RPC forwarding |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Non-empty validation and SDK setter |

## Input / Output
| | |
|--|--|
| **Input** | Non-empty Android `appId` (`String`). |
| **Output** | On Android, `Future<void>` completes after validation and synchronous native setter invocation, with no callback or timeout. Off Android the call logs, dispatches nothing, and completes normally. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android RPC map and non-Android no-op. Android native tests cover parser and handler forwarding.

## Known Limitations
- Dart does not validate an empty value; Android RPC returns the error as `AppsFlyerException`.
- The method name can be confused with iOS `init(appId:)`; the iOS initialization parameter is a different contract.
- No getter confirms the effective override.

## Dependencies
No required feature dependency; the configured value is consumed by subsequent SDK requests.
