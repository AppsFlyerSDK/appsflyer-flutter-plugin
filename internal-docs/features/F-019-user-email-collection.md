---
id: F-019
name: User Email Collection (hashed)
type: sdkCore
platform: both
status: active
last_verified: 2026-08-04
depends_on: []
---

## Business Purpose
Some attribution and cross-device matching scenarios benefit from AppsFlyer knowing the user's email (e.g. matching web and app sessions for the same customer). Sending raw emails over the network is a privacy concern, so in SDK 7 the plugin exposes a single `setUserEmail(String)` and the native SDK hashes the value (SHA-256) internally before it leaves the device. The old SDK 6 `setUserEmails(List, cryptType)` variant — with its caller-selected encryption/crypt-type — has been **removed**; callers no longer choose a hashing mode. Without this API, integrators wanting to correlate identities by email would have no supported channel to hand that data to the native SDK.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.setUserEmail(...)` once the user's email becomes known — typically right after login/signup, or whenever the app wants to (re)associate the current session with an email address. `clearUserPii()` removes it along with the other `setUser*` values.

---

## Call Chain
`setUserEmail` is an awaitable RPC setter available on both platforms.

```
AppsFlyerSdk.setUserEmail(email)                                      [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setUserEmail', {'email': email})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → native SDK hashes the email (SHA-256) internally, then stores/forwards it
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → native SDK hashes the email (SHA-256) internally, then stores/forwards it
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setUserEmail(String email)` — awaitable RPC setter; `clearUserPii()` clears it |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Forwards `setUserEmail` through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Forwards `setUserEmail` through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `email` (`String`, required) — a single user email address. The SDK hashes it (SHA-256) internally; there is no caller-selectable crypt type. |
| **Output** | `Future<void>` completes when the native request succeeds and throws `AppsFlyerException` for native errors or RPC timeouts. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the cross-platform RPC mapping test that `setUserEmail('hash-me@example.com')` dispatches RPC method `setUserEmail` with `{'email': 'hash-me@example.com'}`. The same test covers the sibling PII setters and `clearUserPii`.

---

## Known Limitations
- Hashing is performed by the native SDK, not the plugin — the plugin passes the raw string across the channel, so it relies on the native SDK's SHA-256 implementation for the privacy guarantee.
- No corresponding getter exists to read back the email that was last set.
- Dart does not validate the address format; a malformed value is only rejected, if at all, by the native RPC layer and surfaces as `AppsFlyerException`.

---

## Dependencies
```mermaid
flowchart LR
    F019["F-019 · User Email Collection (hashed)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
