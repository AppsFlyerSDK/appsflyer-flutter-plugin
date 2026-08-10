---
id: F-028
name: App Invite OneLink ID Configuration
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-08-04
depends_on: []
---

## Business Purpose
The User Invite API needs a base OneLink template ID before it can generate invite URLs. `setAppInviteOneLink` provides one cross-platform, awaitable Flutter API for setting or changing that native value.

---

## Trigger
Called explicitly by the host app after `init()` and before the first `generateInviteLink` call, or whenever the application changes the OneLink ID.

---

## Call Chain
The Flutter method is a thin RPC passthrough and has no callback slot or event-stream side effect.

```
AppsFlyerSdk.setAppInviteOneLink(oneLinkId)                            [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setAppInviteOneLink', {'oneLinkId': oneLinkId})
    → Android RPC setAppInviteOneLink → native setAppInviteOneLink
    → iOS RPC setAppInviteOneLink → native appInviteOneLinkID
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public `setAppInviteOneLink(String oneLinkId)` API and RPC mapping |
| Android/iOS RPC modules | Map `oneLinkId` to the native SDK configuration |

---

## Input / Output
| | |
|--|--|
| **Input** | `oneLinkId` (`String`), sent under the RPC key `oneLinkId` on both platforms |
| **Output** | `Future<void>` completes after the RPC layer accepts the native setter. Failures are exposed as `AppsFlyerException`. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `setAppInviteOneLink('one-link')` sends RPC method `setAppInviteOneLink` with `{oneLinkId: 'one-link'}`.

---

## Known Limitations
- The Flutter layer intentionally does not duplicate native OneLink ID validation.
- The former init-time `AppsFlyerOptions.appInviteOneLink` path was removed; F-056 is retained only as a tombstone.

---

## Dependencies
F-027 consumes the configured OneLink ID when generating an invite URL.
