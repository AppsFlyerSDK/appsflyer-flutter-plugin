---
id: F-063
name: Custom Install ID
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`setInstallId` replaces the SDK-generated AppsFlyer install ID with an app-supplied identifier for integrations that must correlate an existing install identity. This is an opt-in capability with deliberately different platform ordering.

## Trigger
- iOS: set `AppsFlyerAllowCustomInstallId = YES` in `Info.plist` and call `setInstallId` before `init()` and before the first `getAppsFlyerUID()`.
- Android: add `<meta-data android:name="APPSFLYER_ALLOW_CUSTOM_INSTALL_ID" android:value="true" />`, call `init()`, then call `setInstallId` before `start()`.

## Call Chain
```
AppsFlyerSdk.setInstallId(installId)                                  [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setInstallId', {installId})
    → platform RPC requires a non-empty string
      → native AppsFlyer SDK setInstallId
        → accepted value becomes the value returned by getAppsFlyerUID()
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public cross-platform API and ordering dartdoc |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Non-empty validation and SDK forwarding |
| Android `sdk_main/.../AppsFlyerLibCore.java` | Init/manifest guards and persistent install-ID update |
| iOS `AppsFlyerRPC/.../AFRPCTypedRequests.swift` and `AFRPCComplexConfigHandler.swift` | Non-empty validation and SDK forwarding |
| iOS `AppsFlyerLib/AppsFlyerLib.h` and `AppsFlyerLib.m` | Info.plist/order guards and native storage |

## Input / Output
| | |
|--|--|
| **Input** | Non-empty `installId` (`String`) plus the platform opt-in flag and ordering above. |
| **Output** | `Future<void>` confirms RPC validation and synchronous SDK invocation only. A missing opt-in flag or wrong native ordering is silently ignored by the SDK and is not returned as an error; bridge validation failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Dart RPC map. Native SDK tests cover the Android opt-in guard; the Flutter suite does not prove either platform's manifest/Info.plist setup.

## Known Limitations
- This API changes install identity and should be used only for a deliberate migration/correlation design, not as a routine per-user identifier.
- The Future cannot distinguish an applied value from a native silent no-op. Verify `getAppsFlyerUID()` in integration testing.
- Ordering differs by platform and cannot be represented as one cross-platform call sequence.

## Dependencies
No single dependency is valid on both platforms because iOS requires the call before F-001 while Android requires it after F-001.
