---
id: F-001
name: SDK Initialization
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`AppsFlyerSdk.init` configures the native AppsFlyer SDK 7 instance with the developer key and, on iOS, the Apple App ID. Before initialization, the platform bridge makes a best-effort call that identifies the integration as the Flutter plugin; failure of this reporting step does not abort initialization. Initialization does not register optional native listeners and does not send a session; those operations remain explicit public API calls.

---

## Trigger
Intended to be called once during application setup through the shared `AppsFlyerSdk.instance`, after subscribing to the event streams the app needs and before registering native conversion, deep-link, or session-ready listeners. Dart does not enforce a single call. Android accepts no `appId`; iOS requires a non-empty value.

---

## Call Chain
All Dart-to-native traffic uses the `af-api` `MethodChannel`. The public method wraps the platform-specific initialization parameters in the standard `{method, params}` RPC envelope.

```
AppsFlyerSdk.instance.init(devKey: ..., appId: ...)                    [lib/src/appsflyer_sdk.dart]
  → empty devKey, or missing/empty appId on iOS → ArgumentError (no RPC dispatched)
  → _invokeVoidRpc('init', platform-specific params)
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.initFromRpc                       [android/.../AppsflyerSdkPlugin.java]
        → best-effort setPluginInfo(plugin: flutter, pluginVersion); failure is ignored
        → Android RPC init(devKey)
      → iOS: AppsflyerSdkPlugin.initFromRpc                           [ios/.../AppsflyerSdkPlugin.m]
        → best-effort setPluginInfo(plugin: flutter, pluginVersion); failure is ignored
        → iOS RPC initialize(devKey, appId)
        → handle pending launch options, when present
        → mark the attribution bridge ready and flush queued lifecycle requests
```

Listener registration is intentionally not part of this sequence. The app separately calls `registerConversionListener`, `registerDeepLinkListener`, and/or `registerSessionReadyListener` after initialization.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `AppsFlyerSdk.instance`, `init`, `_invokeVoidRpc`, and `_invokeRpc` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Makes the non-blocking `setPluginInfo` call before the required `init` RPC; dev-key validation is left to the RPC layer so its `422` reaches the caller intact |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Makes the non-blocking `setPluginInfo` call before `initialize`, forwards pending launch options, and marks the attribution bridge ready |

---

## Input / Output
| | |
|--|--|
| **Input** | `devKey` (`String`, required and checked for non-empty on both platforms); `appId` (`String?`, required and checked for non-empty on iOS, omitted from the Android RPC request) |
| **Output** | `Future<void>` that completes after the required initialization operations succeed: Android `init`, or iOS `initialize` plus pending launch-options handling when present. Invalid input throws `ArgumentError` before any RPC is dispatched. Failures from the required native/RPC operations are exposed as `AppsFlyerException`; `setPluginInfo` failure is intentionally non-blocking. No session is sent. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies the iOS payload, confirms that Android omits `appId`, allows Android initialization without it, rejects a missing/empty iOS `appId`, rejects an empty `devKey` on both platforms without dispatching an RPC, and verifies the singleton entry point.

---

## Known Limitations
- Dart checks only that `devKey` is non-empty and, on iOS, that `appId` is present. Both RPC layers enforce the same rules and report a violation as code `422` — Android through `require(devKey.isNotEmpty())` in `InitRequest`, iOS through `AFRPCInitRequest`. The Dart checks are a fail-fast convenience that avoids a channel round trip and names the offending parameter; they are not the only line of defense. Any stricter validation stays in the RPC/native SDK layers.
- Plugin identification is best-effort on both platforms. A `setPluginInfo` failure does not fail `init()`, so successful completion confirms native initialization but not successful plugin-info reporting.
- Initialization alone does not produce conversion, deep-link, session-ready, or Launch events. The relevant native listeners and `start()` must be invoked explicitly.

---

## Dependencies
```mermaid
flowchart LR
    F001["F-001 · SDK Initialization"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
