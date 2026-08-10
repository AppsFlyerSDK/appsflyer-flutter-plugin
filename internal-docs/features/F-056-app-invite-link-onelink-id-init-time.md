---
id: F-056
name: App Invite OneLink ID (init-time option)
type: oneLinkAndGrowth
platform: both
status: removed
last_verified: 2026-08-04
depends_on: []
---

## Business Purpose
This entry is retained as a tombstone for the former `AppsFlyerOptions.appInviteOneLink` and map-based init option. The native-aligned SDK 7 Flutter API no longer accepts a configuration object or an init-time OneLink ID.

Use the active F-028 API, `await AppsFlyerSdk.instance.setAppInviteOneLink(oneLinkId)`, before generating invite links.

---

## Trigger
None. The init-time option is not part of the current public API and is not consumed by either Flutter platform implementation.

---

## Call Chain
There is no current call chain. The replacement is documented by F-028:

```
AppsFlyerSdk.setAppInviteOneLink(oneLinkId)
  → RPC setAppInviteOneLink {oneLinkId}
```

---

## Files
| File | Role |
|------|------|
| `doc/migration-guide.md` | Documents removal of `AppsFlyerOptions.appInviteOneLink` and its replacement |
| `lib/src/appsflyer_sdk.dart` | Contains the active `setAppInviteOneLink(String oneLinkId)` API; `init()` accepts only `devKey` and `appId` |

---

## Input / Output
| | |
|--|--|
| **Input** | Removed: `AppsFlyerOptions.appInviteOneLink` / map init option |
| **Output** | None. Use F-028, which returns `Future<void>`. |

---

## Tests
Current RPC mapping tests cover the replacement `setAppInviteOneLink` API. No test should expect an init-time OneLink option.

---

## Known Limitations
- Existing SDK 6 integrations must move the OneLink ID into an explicit `setAppInviteOneLink` call.
- The removed init-time option must not be restored or simulated in Dart because the approved SDK 7 API keeps initialization limited to native initialization parameters.

---

## Dependencies
No active feature depends on F-056. F-028 is the supported replacement.
