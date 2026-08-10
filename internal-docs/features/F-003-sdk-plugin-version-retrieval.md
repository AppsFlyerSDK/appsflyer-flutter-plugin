---
id: F-003
name: SDK/Plugin Version Retrieval
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Support and QA need a reliable way to answer "which native AppsFlyer SDK build, and which Flutter plugin build, is actually running in this app?" `getSdkVersion()` surfaces the native SDK's own version string (for diagnosing SDK-side bugs against AppsFlyer's release notes); the `pluginVersion` getter surfaces the Flutter plugin wrapper's version. Without these, bug reports would rely on the app's `pubspec.yaml`/podspec pin, which does not confirm what was actually compiled into the running binary.

---

## Trigger
Called on demand by host app code — typically diagnostic/support tooling, debug menus, or logging at startup.

---

## Call Chain
`getSdkVersion()` is a correlated RPC (`getSdkVersion`); `pluginVersion` is a synchronous Dart getter with no channel call.

```
AppsFlyerSdk.getSdkVersion()                                          [lib/src/appsflyer_sdk.dart]
  → _invokeRpc<String>('getSdkVersion')
    → MethodChannel('af-api').invokeMethod('executeRpc', {method:'getSdkVersion', params:{}})
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.getSdkVersion()   [android/.../AppsflyerSdkPlugin.kt]
      → iOS: dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] ...           [ios/.../AppsflyerSdkPlugin.swift]
        (iOS unwraps the version from the nested {data:{version}} result)
  → null or empty reply is rejected with AppsFlyerException (code 500)
  → PlatformException is converted to AppsFlyerException

AppsFlyerSdk.pluginVersion                                            [lib/src/appsflyer_sdk.dart]
  → returns _AppsFlyerConstants.PLUGIN_VERSION (pure Dart constant, no channel call) [lib/src/appsflyer_constants.dart]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `Future<String> getSdkVersion()` (async RPC round-trip), `String get pluginVersion` (sync, local constant) |
| `lib/src/appsflyer_constants.dart` | `_AppsFlyerConstants.PLUGIN_VERSION = "7.0.1"` constant returned by `pluginVersion` |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | generic `getSdkVersion` dispatch over `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | generic `getSdkVersion` dispatch; `unwrapValueForMethod` extracts `data.version` |

---

## Input / Output
| | |
|--|--|
| **Input** | None |
| **Output** | `getSdkVersion()` → `Future<String>` — the native AppsFlyer SDK's version string. `pluginVersion` → `String` — the Flutter plugin's version constant (`7.0.1`, synchronous). |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps getters and native return values'` verifies that `getSdkVersion()` dispatches RPC method `getSdkVersion` with empty params and returns the version string from the mocked native reply.

---

## Known Limitations
- `_AppsFlyerConstants.PLUGIN_VERSION` is a separate compiled constant rather than a runtime read of `pubspec.yaml`. The RC and production-promotion workflows rewrite the Dart constant alongside the package version, but no general validation check guarantees that they remain equal when changes are made outside those workflows.
- The same release workflows still target the obsolete `ios/Classes/AppsflyerSdkPlugin.h` path when updating the native iOS plugin-version constant. The current constant is `kAppsFlyerPluginVersion` in `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift`, so native iOS `setPluginInfo` can report a stale plugin version until the release tooling is corrected. This does not change the Dart `pluginVersion` getter.
- `pluginVersion` reports the *plugin's* version, not the native SDK's — integrators looking for the native version must use `getSdkVersion()`.

---

## Dependencies
```mermaid
flowchart LR
    F003["F-003 · SDK/Plugin Version Retrieval"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
