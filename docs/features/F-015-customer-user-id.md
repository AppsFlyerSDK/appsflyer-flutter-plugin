---
id: F-015
name: Customer User ID (CUID)
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
AppsFlyer generates its own device-scoped unique ID (`getAppsFlyerUID`), but businesses need to join AppsFlyer's attribution/reporting data (CSV exports, Postback APIs) against their own internal user records (account ID, CRM ID, etc.). `setCustomerUserId` lets the app register its own developer-defined ID alongside AppsFlyer's, so every report and postback can be cross-referenced against the app's own user database — without it, correlating AppsFlyer attribution data with internal user analytics would require a fragile, manual matching process.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app whenever it knows the user's internal identifier — typically right after login/signup, or as soon as the app's own user-identity system resolves an ID.

---

## Call Chain
```
AppsflyerSdk.setCustomerUserId(id)                                       [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setCustomerUserId", {'id': id})
    → Android: AppsflyerSdkPlugin.onMethodCall("setCustomerUserId") → setCustomerUserId(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setCustomerUserId(userId)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setCustomerUserId") → setCustomerUserId:result:         [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [[AppsFlyerLib shared] setCustomerUserID:userId]
```
Note: the related (but distinct) Dart API `setCustomerIdAndLogSession(id)` invokes the channel method `"setCustomerIdAndLogSession"`, which Android handles with its own `setCustomerIdAndLogSession(call, result)` (calling `AppsFlyerLib.getInstance().setCustomerIdAndLogSession(userId, mContext)`), while iOS routes `"setCustomerIdAndLogSession"` to the *same* `setCustomerUserId:result:` handler as plain `setCustomerUserId` — iOS has no distinct "and log session" native behavior.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCustomerUserId(String)` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setCustomerUserId` native handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `setCustomerUserId:result:` native handler |

---

## Input / Output
| | |
|--|--|
| **Input** | `id` (String) — the developer-defined customer user ID. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setCustomerUserId call` (line 266) asserts the mocked channel receives `setCustomerUserId`. No assertion on the argument value reaching native code beyond the channel dispatch mock.

---

## Known Limitations
- No validation of the `id` string (empty string, whitespace, excessive length) before it is forwarded to native code — a blank ID is passed through unchanged on both platforms.
- iOS silently reuses the plain `setCustomerUserId:` implementation for the separate `setCustomerIdAndLogSession` Dart API, while Android gives it genuinely distinct native behavior (`setCustomerIdAndLogSession(userId, mContext)`, tied to `waitForCustomerUserId`'s delayed-session-log flow) — cross-platform behavior for that related API is not equivalent, which is easy to miss since both share the same underlying `setCustomerUserId` naming.

---

## Dependencies
```mermaid
flowchart LR
    F015["F-015 · Customer User ID (CUID)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
