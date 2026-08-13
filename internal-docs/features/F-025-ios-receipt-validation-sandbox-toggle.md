---
id: F-025
name: iOS Receipt Validation Sandbox Toggle
type: purchaseValidation
platform: ios
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Apple's StoreKit sandbox (TestFlight and Xcode debug builds) issues receipts that Apple's production receipt-validation endpoint rejects, and vice versa. `setUseReceiptValidationSandbox` tells AppsFlyer's native iOS SDK which Apple endpoint to call when it later validates an in-app purchase (F-024), so QA and TestFlight builds can validate sandbox receipts without those calls failing against the production endpoint. Without this toggle, developers testing purchase validation on non-production builds would see every validation call fail against Apple's servers even though the purchase is legitimate in the sandbox.

The companion `setUseUninstallSandbox` toggles the equivalent sandbox/production environment for uninstall-measurement validation.

---

## Trigger
Called by the host app during setup or configuration, before the purchase-validation or uninstall-measurement calls whose environment it affects.

---

## Call Chain
Both toggles are awaitable RPC calls, iOS-only at the native RPC layer. Dart no longer short-circuits them off iOS; wrong-platform calls reach the native RPC dispatcher and surface `AppsFlyerException`.

```
AppsFlyerSdk.setUseReceiptValidationSandbox(bool sandbox)              [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setUseReceiptValidationSandbox', {'sandbox': sandbox})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → iOS: AppsflyerSdkPlugin.executeRpc → dispatchRpc:method:@"setUseReceiptValidationSandbox"
        → [AppsFlyerRPCBridge shared] executeJson:completion: → AFRPCRequestHandler → SDK
      → Android: unknown method → AppsFlyerException (422 interim)
  → successful per-call reply completes Future<void>
  → PlatformException is converted to AppsFlyerException

AppsFlyerSdk.setUseUninstallSandbox(bool sandbox)
  → _invokeVoidRpc('setUseUninstallSandbox', {'sandbox': sandbox})
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setUseReceiptValidationSandbox(bool sandbox)` → RPC `setUseReceiptValidationSandbox` with `{sandbox}`; `setUseUninstallSandbox(bool sandbox)` → RPC `setUseUninstallSandbox` with `{sandbox}`. Both iOS-only at the native RPC layer |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | No per-method handler — generic `executeRpc` → `dispatchRpc` forwards to `AppsFlyerRPCBridge` |

---

## Input / Output
| | |
|--|--|
| **Input** | `sandbox` (`bool`), sent under the `sandbox` params key |
| **Output** | `Future<void>` completes after RPC validation and the synchronous native SDK property assignment. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or request timeout. On a non-iOS platform the call reaches the Android RPC dispatcher and throws `AppsFlyerException` (code `422` interim until the native RPC fix lands). The effect is a stateful flag on the native iOS SDK that changes subsequent `validateAndLogInAppPurchase` (F-024) or uninstall-measurement behavior. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `maps every iOS-only API` asserts that `setUseReceiptValidationSandbox(true)` and `setUseUninstallSandbox(true)` each dispatch their own RPC method with `{'sandbox': true}`.

`platform-only calls are forwarded to the native RPC instead of being swallowed in Dart` still covers other iOS-only APIs. `'platform-only setters surface the native error'` covers both sandbox toggles on Android and expects `AppsFlyerException` with code `422`.

---

## Known Limitations
- iOS-only at the native RPC layer: calling either method on Android throws `AppsFlyerException` (code `422` interim).
- Use the sandbox toggles only for test/sandbox environments or when AppsFlyer support instructs you to do so; production builds normally leave both disabled.
- Neither toggle has example-app coverage.
- The flag is native SDK state with no read-back API, so the Flutter layer cannot report which endpoint is currently selected.

---

## Dependencies
No required feature dependency. F-024 consumes this setting only when the app has explicitly selected the sandbox receipt-validation environment.
