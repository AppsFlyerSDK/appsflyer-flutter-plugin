---
id: F-015
name: Customer User ID (CUID)
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
AppsFlyer generates its own device-scoped unique ID (`getAppsFlyerUID`), but businesses need to join AppsFlyer's attribution/reporting data against their own internal user records. `setCustomerUserId` registers the app's developer-defined ID alongside AppsFlyer's, so every report and postback can be cross-referenced against the app's user database. In SDK 7, set the CUID **before** `startSDK()` to attribute the first session with it (the SDK-6 `setCustomerIdAndLogSession` / `waitForCustomerUserId` pair has been removed — see [`doc/migration-guide.md`](/doc/migration-guide.md)).

---

## Trigger
Called by the host app whenever it knows the user's internal identifier — typically right after login/signup, or before `startSDK()` to gate the first session on the CUID.

---

## Call Chain
Generic RPC on both platforms.

```
AppsflyerSdk.setCustomerUserId(id)                                    [lib/src/appsflyer_sdk.dart]
  → _executeRpc('setCustomerUserId', {customerId: id})
    → af-api "executeRpc" {method:'setCustomerUserId', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setCustomerUserId(...)  [android/.../AppsflyerSdkPlugin.java]
      → iOS: dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] setCustomerUserID:...  [ios/.../AppsflyerSdkPlugin.m]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCustomerUserId(String)` — dispatches the RPC with the `customerId` param |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | generic `setCustomerUserId` dispatch over `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | generic `setCustomerUserId` dispatch over `AppsFlyerRPCBridge` |

---

## Input / Output
| | |
|--|--|
| **Input** | `id` (String) — the developer-defined customer user ID. RPC param key `customerId`. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `setCustomerUserId` dispatches the `setCustomerUserId` RPC with the value under the `customerId` param.

---

## Known Limitations
- No validation of the `id` string (empty, whitespace, length) before it is forwarded to native code.
- To associate the first session with the CUID, it must be set before `startSDK()`; there is no dedicated "set CUID and log session" API in SDK 7.

---

## Dependencies
```mermaid
flowchart LR
    F015["F-015 · Customer User ID (CUID)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
