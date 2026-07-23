---
id: F-006
name: Custom Host Configuration
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Enterprises operating in regulated markets (e.g. China) or behind private network/CDN setups need the AppsFlyer SDK to send its HTTPS traffic to a non-default host. `setHost` lets the integrator redirect the SDK's network calls to a custom domain/prefix; `getHostName`/`getHostPrefix` let the app (or diagnostics tooling) confirm what is currently configured. Without this, apps requiring a custom collection endpoint could not integrate AppsFlyer at all in those environments.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app before/around SDK start, whenever the default AppsFlyer collection host must be overridden. `getHostName`/`getHostPrefix` are called on demand (e.g. debug screens) to read back the current configuration.

---

## Call Chain
```
AppsflyerSdk.setHost(hostPrefix, hostName)                              [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setHost", {hostPrefix, hostName})
    → Android: AppsflyerSdkPlugin.onMethodCall("setHost") → setHost(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setHost(hostPrefix, hostName)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setHost") → setHost:result:         [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [[AppsFlyerLib shared] setHost:hostName withHostPrefix:hostPrefix]

AppsflyerSdk.getHostName() / getHostPrefix()
  → _methodChannel.invokeMethod("getHostName" | "getHostPrefix")
    → Android: getHostName(result) / getHostPrefix(result) → AppsFlyerLib.getInstance().getHostName()/getHostPrefix()
    → iOS: getHostName:result: / getHostPrefix:result: → [[AppsFlyerLib shared] host] / [[AppsFlyerLib shared] hostPrefix]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setHost`, `getHostName`, `getHostPrefix` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setHost`, `getHostName`, `getHostPrefix` native handlers |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` | `AF_HOST_PREFIX`, `AF_HOST_NAME` argument key constants |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `setHost:result:`, `getHostName:result:`, `getHostPrefix:result:` native handlers |

---

## Input / Output
| | |
|--|--|
| **Input** | `setHost`: `hostPrefix` (String), `hostName` (String). `getHostName`/`getHostPrefix`: none. |
| **Output** | `setHost` → `void` (fire-and-forget). `getHostName()`/`getHostPrefix()` → `Future<String?>` reflecting the currently configured values. |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setHost call` (line 121) asserts the channel receives `setHost` with `hostPrefix`/`hostName` arguments; `check getHostPrefix call` (line 220) and `check getHostName call` (line 226) assert the corresponding method names are invoked. No test asserts the actual return value flowing back from a (mocked) native host name/prefix.

---

## Known Limitations
- **Android bug**: `AppsflyerSdkPlugin.setHost(call, result)` never calls `result.success(...)` or `result.error(...)` — every other handler in the file does. Because Dart's `setHost()` is `void` and does not await the returned `Future`, this is currently harmless to callers, but it means the platform channel's pending reply for that invocation is left unresolved, unlike all other methods in this plugin, and would surface as a bug if a future refactor made `setHost` return/await a value.
- No input validation on `hostPrefix`/`hostName` on either platform — an empty string or malformed host is passed straight to the native SDK, which may fail silently or send traffic nowhere.
- Must be called before the SDK actually establishes its first network connection to take effect; calling it after `startSDK()`/auto-start has already fired a request may be too late — this ordering constraint is not enforced by the Dart or native code.

---

## Dependencies
```mermaid
flowchart LR
    F006["F-006 · Custom Host Configuration"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
