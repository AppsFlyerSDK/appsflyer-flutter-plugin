---
id: F-024
name: In-App Purchase Validation V2 (cross-platform)
type: purchaseValidation
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`validateAndLogInAppPurchase` is the single cross-platform entry point for server-side purchase validation. It lets AppsFlyer verify purchase and subscription revenue against the store (Google Play or App Store). With `awaitResponse: true`, it returns the validation result — or throws a structured error — directly on the `Future`, so the app can react at the call site. It replaces the removed platform-split V1 APIs (F-023).

The store contract is selected by the type of the supplied `AFPurchaseDetails`, not by a runtime platform check, so an app that ships the wrong store's purchase model fails loudly instead of sending an unusable payload.

---

## Trigger
Called by the host app after it detects a completed purchase or subscription renewal from the platform store. On Android, the host can select whether the RPC awaits the validation result through `awaitResponse`; iOS always awaits it.

---

## Call Chain
Both platforms dispatch the same RPC method name, `validateAndLogInAppPurchase`, but the purchase parameter shape is produced by the platform-specific `AFPurchaseDetails` implementation. Android uses a flat schema and iOS uses nested `product` and `transaction` objects. `AppsFlyerSdk` appends the public `awaitResponse` value only to the Android payload because the iOS RPC does not expose that field.

```
AppsFlyerSdk.validateAndLogInAppPurchase(                                  [lib/src/appsflyer_sdk.dart]
  purchase, {additionalParameters, awaitResponse})
  → purchase.toRpcMap(platform: _platform, additionalParameters: ...)       [lib/src/af_purchase_details.dart]
      → AFAndroidPurchaseDetails: {purchaseType, purchaseToken, productId,
                                   additionalParameters}
      → AFIOSPurchaseDetails:     {product: {productId},
                                   transaction: {transactionId, purchaseType},
                                   additionalParameters}
      → wrong platform for the model, including any non-mobile platform → ArgumentError
  → Android only: append {awaitResponse}
  → _invokeRpc<Map<Object?, Object?>>('validateAndLogInAppPurchase', params)
    → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.executeRpc → dispatchRpc('validateAndLogInAppPurchase', ...)
        → AppsFlyerRpcHandler.execute(json) → AppsFlyerLib.validateAndLogInAppPurchase(...)
      → iOS: AppsflyerSdkPlugin.executeRpc → dispatchRpc:method:@"validateAndLogInAppPurchase"
        → [AppsFlyerRPCBridge shared] executeJson:completion: → AFRPCRequestHandler → SDK
        → unwrapValueForMethod: returns the `data` map (or {}) for this method
  → successful per-call reply completes the Future with the validation-result map
  → PlatformException is converted to AppsFlyerException
```

A `null` native reply is normalized to an empty map rather than propagated as `null`.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `validateAndLogInAppPurchase(AFPurchaseDetails purchase, {Map<String, String>? additionalParameters, bool awaitResponse = true})` → `Future<Map<String, dynamic>>`; delegates purchase parameter building to the model, appends `awaitResponse` for Android, and invokes the RPC |
| `lib/src/af_purchase_details.dart` | `sealed class AFPurchaseDetails` (closed to `AFAndroidPurchaseDetails` and `AFIOSPurchaseDetails`), `AFPurchaseType`, and the per-platform `toRpcMap` contracts |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | No per-method handler — generic `executeRpc` → `dispatchRpc('validateAndLogInAppPurchase', ...)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | No per-method handler; generic dispatch, with `unwrapValueForMethod:` returning the `data` map for `validateAndLogInAppPurchase` |

---

## Input / Output
| | |
|--|--|
| **Input** | `purchase` (`AFPurchaseDetails`) — `AFAndroidPurchaseDetails(purchaseType, productId, purchaseToken)` for Google Play or `AFIOSPurchaseDetails(purchaseType, productId, transactionId)` for the App Store; `additionalParameters` (`Map<String, String>?`, optional); `awaitResponse` (`bool`, optional, default `true`; mapped only to Android RPC). `AFPurchaseType` serializes as `"one_time_purchase"` / `"subscription"` on Android and `"oneTimePurchase"` / `"subscription"` on iOS. |
| **Output** | `Future<Map<String, dynamic>>` — with the default `awaitResponse: true`, completes with the native validation-result map. Android waits up to 5 seconds; `false` starts validation without a callback and completes with an empty map. The current iOS RPC 7.0.12 does not expose the flag, always awaits validation, and uses a 30-second timeout. Native and bridge failures throw `AppsFlyerException`. Passing the wrong platform's model throws `ArgumentError`, including on a non-mobile platform. |

---

## Tests
`test/appsflyer_sdk_test.dart`:
- `purchase validation sends the Android contract` — asserts the flat Android parameter map (`purchaseType: 'one_time_purchase'`, `purchaseToken`, `productId`, `additionalParameters`, `awaitResponse: true`) and that the mocked result map is returned to the caller.
- `purchase validation sends the iOS contract` — asserts the nested iOS parameter map (`product.productId`, `transaction.transactionId`, `transaction.purchaseType`, `additionalParameters`) without an unsupported `awaitResponse` field.
- `purchase validation forwards awaitResponse only to Android` — asserts that an explicit `false` reaches Android RPC and that the unsupported field is omitted from the iOS payload.
- `purchase details reject the wrong platform` — asserts `ArgumentError` when an Android model is used on iOS and vice versa, and when either model is serialized on a non-mobile target platform (`macOS`, `windows`).

---

## Known Limitations
- The platform/model pairing is enforced at runtime by `toRpcMap`, not by the type system, so a mismatched model compiles and only throws `ArgumentError` when the call is made.
- The purchase-type wire values differ between platforms (`one_time_purchase` on Android, `oneTimePurchase` on iOS) because each native RPC parser expects its own casing; the Dart enum hides this, but the payloads are not interchangeable.
- The returned validation-result map is untyped (`Map<String, dynamic>`) and passed through from the native reply, so its keys are defined by the native SDK rather than by the Flutter API.
- The Android RPC honors `awaitResponse: false`; the current iOS RPC 7.0.12 exposes neither this field nor a fire-and-forget branch for purchase validation. Full behavioral parity requires iOS RPC support.
- A timeout fails the Dart Future but does not cancel the store/server validation already started by the native SDK. A late result is not delivered through a second Flutter callback.

---

## Dependencies
No required feature dependency. F-025 is an optional iOS environment switch used only for sandbox validation.
