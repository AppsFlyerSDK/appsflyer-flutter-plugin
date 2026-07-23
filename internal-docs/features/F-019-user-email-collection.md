---
id: F-019
name: User Email Collection (with encryption)
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Some attribution and cross-device matching scenarios benefit from AppsFlyer knowing the user's email address(es) (e.g. matching web and app sessions for the same customer). Sending raw emails over the network is a privacy concern, so `setUserEmails` supports an optional SHA-256 hash instead of plaintext. Without this API, integrators wanting to correlate identities by email would have no supported channel to hand that data to the native SDK at all.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app once the user's email(s) become known — typically right after login/signup, or whenever the app wants to (re)associate the current session with one or more email addresses.

---

## Call Chain
```
AppsflyerSdk.setUserEmails(emails, cryptType)                          [lib/src/appsflyer_sdk.dart]
  → cryptTypeInt = EmailCryptType.values.indexOf(cryptType) (defaults to 0 / EmailCryptTypeNone if omitted)   [lib/src/appsflyer_constants.dart]
  → _methodChannel.invokeMethod("setUserEmails", {'emails': emails, 'cryptType': cryptTypeInt})
    → Android: AppsflyerSdkPlugin.onMethodCall("setUserEmails") → setUserEmails(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → maps cryptTypeInt (0/1) to AppsFlyerProperties.EmailsCryptType.NONE / SHA256 (throws InvalidParameterException on any other value)
      → AppsFlyerLib.getInstance().setUserEmails(cryptType, emails.toArray(new String[0]))
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setUserEmails") → setUserEmails:result:          [ios/Classes/AppsflyerSdkPlugin.m]
      → maps cryptTypeInt to native EmailCryptType (EmailCryptTypeNone / EmailCryptTypeSHA256)
      → [AppsFlyerLib shared] setUserEmails:cryptType:]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setUserEmails(List<String>, [EmailCryptType?])` — converts the enum to its integer index before sending |
| `lib/src/appsflyer_constants.dart` | `enum EmailCryptType { EmailCryptTypeNone, EmailCryptTypeSHA256 }` — index 0/1 is the wire format sent to native |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setUserEmails(call, result)`, line 983 — maps int to `AppsFlyerProperties.EmailsCryptType`, throws on unrecognized value |
| `ios/Classes/AppsflyerSdkPlugin.m` | `setUserEmails:result:`, line 761 — maps int to native `EmailCryptType` |

---

## Input / Output
| | |
|--|--|
| **Input** | `emails` (`List<String>`, required) — one or more user email addresses. `cryptType` (`EmailCryptType?`, optional) — `EmailCryptTypeNone` (default, index 0) sends plaintext; `EmailCryptTypeSHA256` (index 1) hashes before sending. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setUserEmails call` (line 244) calls `setUserEmails(["user@example.com"], EmailCryptType.EmailCryptTypeSHA256)` and asserts `capturedArguments['emails']` contains the email and `capturedArguments['cryptType']` equals the enum's index (1). The default (omitted `cryptType`, defaulting to index 0) path is not separately tested.

---

## Known Limitations
- The enum-to-int mapping (`EmailCryptType.values.indexOf(cryptType)`) is a fragile contract: if the enum's declared order in `lib/src/appsflyer_constants.dart` is ever changed or a new value is inserted in the middle, the integer sent over the channel silently shifts meaning on both native platforms without any compile-time check tying the three enumerations together.
- Android throws a Java `InvalidParameterException` for any `cryptTypeInt` outside `{0, 1}` — since the only public Dart entry point is the typed enum, this should be unreachable in practice, but a raw/dynamic method channel call bypassing the Dart API could trigger it.
- No corresponding getter exists to read back which emails/crypt type were last set.

---

## Dependencies
```mermaid
flowchart LR
    F019["F-019 · User Email Collection (with encryption)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
