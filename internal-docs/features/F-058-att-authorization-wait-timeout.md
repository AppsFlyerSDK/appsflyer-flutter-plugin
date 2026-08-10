---
id: F-058
name: ATT Authorization Wait Timeout (iOS)
type: sdkCore
platform: ios
status: removed
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
This entry is retained as a tombstone for the former `AppsFlyerOptions.timeToWaitForATTUserAuthorization` init-time option, which asked the native iOS SDK to delay its first session for up to N seconds while the user answered Apple's App Tracking Transparency (ATT) prompt.

The native-aligned SDK 7 Flutter API has **no** ATT surface at all: there is no `waitForATT` method, no ATT-wait-timeout parameter, and no init-time configuration object to carry one. `init()` accepts only `devKey` and `appId`.

The replacement is the explicit SDK 7 session model documented by F-002. Because initialization no longer sends a session, the application controls exactly when the first session is sent: request ATT authorization in application code, and only then call `await AppsFlyerSdk.instance.start()` from the `onSessionReady` listener. This replaces an opaque native timer with ordering the app can observe and test.

---

## Trigger
None. No Dart API accepts an ATT wait interval, and neither platform implementation consumes such a key.

---

## Call Chain
There is no current call chain. The replacement is application-controlled session timing, documented by F-002:

```
AppsFlyerSdk.instance.onSessionReady.listen((_) async {
  // application requests ATT authorization here, then:
  await AppsFlyerSdk.instance.start();
});
  → RPC start {awaitResponse: false} // default; pass awaitResponse: true to await completion
```

---

## Files
| File | Role |
|------|------|
| `doc/migration-guide.md` | Lists `waitForATTUserAuthorization` under removed APIs and directs integrators to control the timing of `start()` in application code |
| `lib/src/appsflyer_sdk.dart` | Contains no ATT symbol; `init()` accepts only `devKey` and `appId`, and `start()` is the explicit session call |

---

## Input / Output
| | |
|--|--|
| **Input** | Removed: `AppsFlyerOptions.timeToWaitForATTUserAuthorization` / the equivalent map init key |
| **Output** | None. Use F-002 `start()`, which returns `Future<void>`. |

---

## Tests
No test references ATT. `test/appsflyer_sdk_test.dart` asserts that `init` sends only `devKey` (Android) or `devKey` and `appId` (iOS), and that `start` forwards the public `awaitResponse` value (default `false`). No test should expect an ATT wait option.

---

## Known Limitations
- Existing SDK 6 integrations that relied on the native wait timer must move ATT sequencing into application code: request authorization, then call `start()`.
- The removed option must not be restored or emulated in Dart. Emulating it would mean adding a Dart-side timer around `start()`, which would hide session timing from the application rather than expose it.
- The Flutter plugin does not wrap `ATTrackingManager`; requesting ATT authorization is the application's responsibility.

---

## Dependencies
No active feature depends on F-058. F-002 (SDK Start) is the supported replacement.
