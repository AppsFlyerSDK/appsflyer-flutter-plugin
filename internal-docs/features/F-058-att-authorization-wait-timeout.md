---
id: F-058
name: ATT Authorization Wait Timeout (iOS)
type: sdkCore
platform: ios
status: active
last_verified: 2026-07-29
depends_on: ["F-001"]
---

## Business Purpose
Since iOS 14.5, apps must show Apple's App Tracking Transparency (ATT) prompt before collecting the IDFA. If the AppsFlyer SDK starts (and fires its first session/attribution request) before the user responds to that prompt, it may miss the IDFA and under-report attribution. `timeToWaitForATTUserAuthorization` lets the host app delay the SDK's `start()` call for up to N seconds so it can wait for the user to accept, decline, or time out on the consent dialog before the first session is sent — improving IDFA-based attribution accuracy without requiring the app to manually gate SDK start behind a callback.

---

## Trigger
Set once by the host app as part of `AppsFlyerOptions` (or the raw options `Map`), read only on iOS (`Platform.isIOS`), and applied natively during the `init` orchestration before the SDK's `start`.

---

## Call Chain
```
AppsFlyerOptions(timeToWaitForATTUserAuthorization: 50.0)               [lib/src/appsflyer_options.dart]
  → AppsflyerSdk.initSdk(...)                                          [lib/src/appsflyer_sdk.dart]
    → _validateAFOptions / _validateMapOptions
      → if (Platform.isIOS) { assert(value is double);
          validatedOptions[AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION] = value }
      → _executeRpc('init', validatedOptions)
        → MethodChannel "af-api".invokeMethod('executeRpc', {method:'init', params})
          → iOS: AppsFlyerRPCBridge init orchestration reads timeToWaitForATTUserAuthorization and calls
              [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:...] before start   [ios/.../AppsflyerSdkPlugin.m]
          → Android: value is never sent — no Android equivalent exists (ATT is an iOS-only framework)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_options.dart` | `AppsFlyerOptions.timeToWaitForATTUserAuthorization` (`double?`, optional named constructor param) |
| `lib/src/appsflyer_sdk.dart` | `_validateAFOptions` / `_validateMapOptions` — reads the value **only** when `Platform.isIOS`, asserts it is a `double`, copies into the validated options map |
| `lib/src/appsflyer_constants.dart` | `AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION = "timeToWaitForATTUserAuthorization"` — shared Dart↔native key |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Init orchestration reads the interval and calls `waitForATTUserAuthorizationWithTimeoutInterval:` before `start` |
| `doc/installation-guide.md`, `doc/advanced-features.md`, `doc/api-reference.md` | Document the option as delaying SDK start "for x seconds until the user either accepts the consent dialog, declines it, or the timer runs out" |

---

## Input / Output
| | |
|--|--|
| **Input** | `timeToWaitForATTUserAuthorization` (`double?`, seconds) via `AppsFlyerOptions` or the equivalent Map key; only read/applied when `Platform.isIOS` |
| **Output** | `void` — delays the native SDK's internal `start()`/first session dispatch by up to the given interval (or until ATT authorization resolves, whichever comes first); no value or confirmation returned to Dart. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart`'s init test does not set `timeToWaitForATTUserAuthorization`, and because Dart tests do not run with `Platform.isIOS == true`, the entire `if (Platform.isIOS) { ... }` validation branch (including the `assert(timeToWaitForATTUserAuthorization is double)` check and the iOS App ID regex validation alongside it) is untested.

---

## Known Limitations
- Android has no equivalent: the key is never sent from Dart (the `Platform.isIOS` guard lives in `_validateAFOptions`/`_validateMapOptions`), so the Android bridge never sees it.
- A value of exactly `0` is treated as "not set", so a host app cannot explicitly pass `0.0` to mean "no wait" versus simply omitting the option — both behave identically.
- The Dart-side `assert(timeToWaitForATTUserAuthorization is double)` is stripped in release builds, so passing a non-double dynamic value (e.g. via the raw `Map` options path) would silently misbehave in production rather than failing fast.

---

## Dependencies
```mermaid
flowchart LR
    F058["F-058 · ATT Authorization Wait Timeout (iOS)"]:::sdkCore -->|"applied only during"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
