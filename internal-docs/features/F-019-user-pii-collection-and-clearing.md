---
id: F-019
name: User PII Collection and Clearing
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Some attribution and cross-device matching workflows use user-provided identity data. SDK 7 exposes separate setters for email, phone, first name, last name, and Facebook App-Scoped ID, plus `clearUserPii()` to remove all values set through those APIs. The native SDK hashes email, phone, and names with SHA-256 before network transmission; the Facebook login ID is intentionally sent unhashed for partner matching. The removed SDK 6 `setUserEmails(List, cryptType)` surface no longer lets callers select a hashing mode.

---

## Trigger
The host app calls only the setters covered by its privacy policy and consent state, typically after login or signup and before the first `start()` that should carry the values. Call `clearUserPii()` when the user logs out, withdraws consent, requests deletion of the locally held SDK identity values, or before switching accounts. Reapply required values after a cold start.

---

## Call Chain
All methods are synchronous native setters exposed as `Future<void>` through the shared RPC path.

```
AppsFlyerSdk.setUserEmail / setUserPhone / setUserFirstName /
              setUserLastName / setUserFbLoginId / clearUserPii      [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc(method, method-specific params)
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → native SDK hashes email/phone/names; stores Facebook ID as supplied
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → native SDK hashes email/phone/names; stores Facebook ID as supplied
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public PII setters and `clearUserPii()` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Forwards all PII methods through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Forwards all PII methods through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `setUserEmail(email)`; `setUserPhone(countryCode, phoneNumber)`; `setUserFirstName(firstName)`; `setUserLastName(lastName)`; `setUserFbLoginId(int fbLoginId)` where `0` clears only that ID; and parameterless `clearUserPii()`. Raw values cross the Flutter channel and native RPC boundary. Email, phone, and names are hashed by the native SDK; Facebook login ID is not hashed. Android RPC rejects empty string values, while iOS RPC currently performs type-only checks. |
| **Output** | Each method returns `Future<void>` and completes after native RPC validation and the synchronous SDK setter/clear invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or request timeout. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the cross-platform RPC mapping test that `setUserEmail('hash-me@example.com')` dispatches RPC method `setUserEmail` with `{'email': 'hash-me@example.com'}`. The same test covers the sibling PII setters and `clearUserPii`.

---

## Known Limitations
- Hashing is performed by the native SDK, not Dart or the Flutter channel. Raw PII therefore exists in Dart and crosses the in-process channel/RPC serialization boundary before hashing.
- The Facebook App-Scoped ID is intentionally not hashed. `clearUserPii()` clears all values managed by this feature; pass `0` to `setUserFbLoginId` to clear only that ID.
- No getter exposes the last configured values. The Flutter plugin does not persist them across process launches.
- Dart does not validate formats. Android rejects empty string values; iOS accepts empty strings at the RPC layer, so malformed values can be handled differently by the native SDKs.

---

## Dependencies
```mermaid
flowchart LR
    F019["F-019 · User PII Collection and Clearing"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
