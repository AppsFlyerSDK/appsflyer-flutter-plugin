---
id: F-028
name: App Invite OneLink ID Configuration
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-056"]
---

## Business Purpose
The User-Invite-API (F-027) needs to know which OneLink template/ID to base generated invite links on. `setAppInviteOneLinkID` lets the host app set (or change) that base OneLink ID at runtime, independent of SDK initialization — useful for apps that resolve the correct OneLink ID dynamically (e.g. per region, per experiment, or fetched from a remote config) after the SDK has already started. Without it, invite links generated via `generateInviteLink` would have no base link to attach referrer metadata to, and the referral/growth loop would not function.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called explicitly by the host app at any point after SDK initialization, typically before the first call to `generateInviteLink` (F-027), whenever the app determines (or changes) which OneLink ID should back invite links.

---

## Call Chain
```
AppsflyerSdk.setAppInviteOneLinkID(oneLinkID, callback)                          [lib/src/appsflyer_sdk.dart]
  → startListening(callback, "setAppInviteOneLinkIDCallback")                    [lib/src/callbacks.dart]
  → _methodChannel.invokeMethod("setAppInviteOneLinkID", {'oneLinkID': oneLinkID})
    → Android: AppsflyerSdkPlugin.onMethodCall("setAppInviteOneLinkID") → setAppInivteOneLinkID(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setAppInviteOneLink(oneLinkId) → runOnUIThread(..., "setAppInviteOneLinkIDCallback", AF_SUCCESS)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setAppInviteOneLinkID") → setAppInviteOneLinkID:result:          [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [AppsFlyerLib shared].appInviteOneLinkID = oneLinkID → _streamHandler sendResponseToFlutter:...
  → Dart: callbacks.dart _methodCallHandler("callListener") → _callbacksById["setAppInviteOneLinkIDCallback"](data)   [lib/src/callbacks.dart]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setAppInviteOneLinkID(String, Function)` — public API; registers the callback and invokes the method channel |
| `lib/src/callbacks.dart` | `startListening()` / `_methodCallHandler` — generic callback-channel plumbing shared with other async APIs |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setAppInivteOneLinkID(call, result)` (note the native method's typo — "Inivte") — forwards to `AppsFlyerLib.getInstance().setAppInviteOneLink(oneLinkId)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `setAppInviteOneLinkID:result:` — sets `[AppsFlyerLib shared].appInviteOneLinkID` |

---

## Input / Output
| | |
|--|--|
| **Input** | `oneLinkID` (`String`), `callback` (`Function`) invoked with the async result |
| **Output** | Android: if `oneLinkID` is `null` or empty, `result.success(null)` is returned and the native setter is **not** called (no error surfaced); otherwise the native SDK's OneLink ID is updated and, if a callback was registered, `{"status": "success"}` is delivered via the callback channel. iOS: always sets `appInviteOneLinkID` (even if `nil`/empty) and, if a callback was registered, delivers `{"status": "success"}`. Neither native call ever reports failure — the callback fires only on success. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setAppInviteOneLinkID call` (line 180) only asserts that `setAppInviteOneLinkID("oneLinkID", (msg) {})` dispatches the `"setAppInviteOneLinkID"` method over the mocked channel; it does not assert the `oneLinkID` argument's value, the callback payload, or exercise either native implementation.

---

## Known Limitations
- **Android silently no-ops on empty/null `oneLinkID`**: `setAppInivteOneLinkID` in `AppsflyerSdkPlugin.java` checks `if (oneLinkId == null || oneLinkId.length() == 0)` and simply calls `result.success(null)` without setting anything or notifying any registered callback — the host app has no way to detect that the OneLink ID was not actually applied.
- **iOS has no equivalent empty-string guard**: `setAppInviteOneLinkID:result:` on iOS assigns `oneLinkID` to `appInviteOneLinkID` unconditionally, so passing an empty string behaves differently across platforms (Android ignores it, iOS sets it).
- **No failure callback path exists on either platform** — the registered callback (mapped to `"setAppInviteOneLinkIDCallback"`) is only ever invoked with a success payload; there is no way to be notified of a rejected/invalid OneLink ID from the native SDK.
- Native Android method name (`setAppInivteOneLinkID`) contains a typo, though this is internal and does not affect the public Dart API or the method-channel string name.

---

## Dependencies
```mermaid
flowchart LR
    F028["F-028 · App Invite OneLink ID Configuration"]:::oneLinkAndGrowth
    F056["F-056 · App Invite Link OneLink ID (init-time)"]:::oneLinkAndGrowth
    F028 -->|"shares same native OneLink-ID property, last write wins"| F056
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
