---
id: F-048
name: Plugin Metadata Reporting to Native SDK
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: ["F-001"]
---

## Business Purpose
AppsFlyer maintains multiple wrapper SDKs on top of its native Android/iOS SDKs (Flutter, React Native, Cordova, Unity, etc.). The `setPluginInfo` RPC tells the native SDK "this install is running through the Flutter plugin, version X" so AppsFlyer's backend, support tooling, and internal dashboards can attribute traffic/bugs to the correct wrapper and version rather than treating every install as a bare native integration. This has no effect on attribution logic or app behavior — it is purely an internal identification tag with no host-app-facing API.

---

## Trigger
Runs automatically and unconditionally as part of the plugin's `init` orchestration, on both platforms. There is no public Dart API, option, or flag that controls or disables it — the plugin dispatches the `setPluginInfo` RPC before the native `init` as a side effect of `AppsflyerSdk.initSdk()`.

---

## Call Chain
```
AppsflyerSdk.initSdk(...)                                              [lib/src/appsflyer_sdk.dart]
  → _executeRpc('init', validatedOptions)
    → MethodChannel "af-api".invokeMethod('executeRpc', {method:'init', params})
      → Android: AppsflyerSdkPlugin.initFromRpc(...)                   [android/.../AppsflyerSdkPlugin.java]
        → executeRpcSync('setPluginInfo', {plugin:"flutter", pluginVersion: PLUGIN_VERSION})   [before init()]
        → executeRpcSync('init', {devKey})
      → iOS: AppsFlyerRPCBridge init orchestration                     [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
        → setPluginInfo RPC with {plugin:"flutter", pluginVersion}, before the native SDK is initialized
```

---

## Files
| File | Role |
|------|------|
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `initFromRpc(...)` — dispatches the `setPluginInfo` RPC with `{plugin:"flutter", pluginVersion: PLUGIN_VERSION}` before the `init` RPC |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsFlyerConstants.java` | `AF_PLUGIN_NAME = "flutter"`, `PLUGIN_VERSION` — the values reported to the native SDK |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Init orchestration dispatching the `setPluginInfo` RPC to `AppsFlyerRPCBridge` before the native SDK init |

The plugin no longer constructs the native `PluginInfo`/`AFSDKPluginFlutter` types directly; it passes `plugin` and `pluginVersion` as RPC params and the `AppsFlyerRpcHandler`/`AppsFlyerRPCBridge` maps them to the native SDK's `setPluginInfo` call.

---

## Input / Output
| | |
|--|--|
| **Input** | None from the host app — no Dart parameter exists. The reported values (`plugin:"flutter"` and `PLUGIN_VERSION`) are fixed by the plugin's source code. |
| **Output** | `void` — fire-and-forget call into the native SDK; nothing is returned to Dart. The metadata is transmitted internally by the native SDK to AppsFlyer's backend as part of its own request payloads. |

---

## Tests
No dedicated test found. The call is not exposed as a distinct Dart method (the `setPluginInfo` RPC is dispatched inside the native init orchestration), so it cannot be observed from `test/appsflyer_sdk_test.dart`'s mocked `af-api` channel, which only sees the single `executeRpc` invocation for `init` — the `setPluginInfo` RPC is issued natively afterward.

---

## Known Limitations
- The reported plugin version constant is maintained per platform and currently aligned at `"7.0.1"` (Dart `AppsflyerConstants.PLUGIN_VERSION`, Android `AppsFlyerConstants.PLUGIN_VERSION`, iOS `kAppsFlyerPluginVersion`). There is no single source of truth tying the three together, so they must be kept in sync manually on each release.
- No public Dart API exists to inspect, override, or disable the reported plugin metadata; it is entirely internal and always fires as part of init with no error handling or confirmation callback.
- The `setPluginInfo` RPC is dispatched before the `init` RPC; if init fails or the SDK is re-initialized, there is no guard against issuing `setPluginInfo` more than once.

---

## Dependencies
```mermaid
flowchart LR
    F048["F-048 · Plugin Metadata Reporting to Native SDK"]:::sdkCore -->|"runs inside the same native call as"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
