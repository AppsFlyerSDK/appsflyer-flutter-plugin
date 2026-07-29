---
id: F-003
name: SDK/Plugin Version Retrieval
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Support and QA need a reliable way to answer "which native AppsFlyer SDK build, and which Flutter plugin build, is actually running in this app?" `getSDKVersion()` surfaces the native SDK's own version string (for diagnosing SDK-side bugs against AppsFlyer's release notes); `getVersionNumber()` surfaces the Flutter plugin wrapper's version. Without these, bug reports would rely on the app's `pubspec.yaml`/podspec pin, which does not confirm what was actually compiled into the running binary.

---

## Trigger
Called on demand by host app code — typically diagnostic/support tooling, debug menus, or logging at startup.

---

## Call Chain
`getSDKVersion()` is a generic RPC (`getSdkVersion`); `getVersionNumber()` is pure Dart with no channel call.

```
AppsflyerSdk.getSDKVersion()                                          [lib/src/appsflyer_sdk.dart]
  → _executeRpc<String>('getSdkVersion')
    → af-api MethodChannel "executeRpc" {method:'getSdkVersion'}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.getSdkVersion()   [android/.../AppsflyerSdkPlugin.java]
      → iOS: dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] ...           [ios/.../AppsflyerSdkPlugin.m]
        (iOS unwraps the version from the nested {data:{version}} result)

AppsflyerSdk.getVersionNumber()                                       [lib/src/appsflyer_sdk.dart]
  → returns AppsflyerConstants.PLUGIN_VERSION (pure Dart constant, no channel call)  [lib/src/appsflyer_constants.dart]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `getSDKVersion()` (async RPC round-trip), `getVersionNumber()` (sync, local constant) |
| `lib/src/appsflyer_constants.dart` | `PLUGIN_VERSION = "7.0.0"` constant returned by `getVersionNumber()` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | generic `getSdkVersion` dispatch over `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | generic `getSdkVersion` dispatch; `unwrapValueForMethod` extracts `data.version` |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `getSDKVersion()` → `Future<String?>` — the native AppsFlyer SDK's version string. `getVersionNumber()` → `String` — the Flutter plugin's version constant (`7.0.0`, synchronous). |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `getSDKVersion()` dispatches the `getSdkVersion` RPC and returns the unwrapped version string from the mocked native reply. `getVersionNumber()` is not tested (trivial constant).

---

## Known Limitations
- `AppsflyerConstants.PLUGIN_VERSION` is a manually maintained constant with no CI check tying it to `pubspec.yaml`; keep both at `7.0.0`.
- `getVersionNumber()` reports the *plugin's* version, not the native SDK's — the naming similarity to `getSDKVersion()` is a common source of confusion.

---

## Dependencies
```mermaid
flowchart LR
    F003["F-003 · SDK/Plugin Version Retrieval"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
