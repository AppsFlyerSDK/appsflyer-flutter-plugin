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
Intended to be called once during application setup through the shared `AppsFlyerSdk.instance`, and before registering the native conversion, deep-link, or session-ready listeners the app needs. Dart does not enforce a single call. Android accepts no `appId`; iOS requires a non-empty value.

---

## Call Chain
All Dart-to-native traffic uses the `af-api` `MethodChannel`. The public method wraps the platform-specific initialization parameters in the standard `{method, params}` RPC envelope.

```
AppsFlyerSdk.instance.init(devKey: ..., appId: ...)                    [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('init', platform-specific params)
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.initFromRpc                       [android/.../AppsflyerSdkPlugin.kt]
        → best-effort setPluginInfo(plugin: flutter, pluginVersion); failure is ignored
        → Android RPC init(devKey)
      → iOS: AppsflyerSdkPlugin.initFromRpc                           [ios/.../AppsflyerSdkPlugin.swift]
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
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Makes the non-blocking `setPluginInfo` call before the required `init` RPC; dev-key validation is left to the RPC layer so its `422` reaches the caller intact |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Makes the non-blocking `setPluginInfo` call before `initialize`, forwards pending launch options, and marks the attribution bridge ready |

---

## Input / Output
| | |
|--|--|
| **Input** | `devKey` (`String`, required by both native RPC layers); `appId` (`String?`, required by the native iOS RPC layer, omitted from the Android RPC request). Dart does not validate either value before transport. |
| **Output** | `Future<void>` that completes after the required initialization operations succeed: Android `init`, or iOS `initialize` plus pending launch-options handling when present. Invalid input is validated by the native RPC layer and surfaced as `AppsFlyerException` when the RPC reports an error. `setPluginInfo` failure is intentionally non-blocking. No session is sent. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies the iOS payload, confirms that Android omits `appId`, allows Android initialization without it, forwards invalid `devKey`/`appId` values to the native RPC layer instead of validating them in Dart, and verifies the singleton entry point.

---

## Known Limitations
- Input validation for `devKey` and `appId` is performed by the native RPC layer. Android rejects an empty `devKey` through `InitRequest` (`422`); iOS rejects a missing or empty `appId` through `AFRPCInitRequest`. Dart forwards the values as supplied and does not validate them before transport.
- Plugin identification is best-effort on both platforms. A `setPluginInfo` failure does not fail `init()`, so successful completion confirms native initialization but not successful plugin-info reporting.
- Initialization alone does not produce conversion, deep-link, session-ready, or Launch events. The relevant native listeners and `start()` must be invoked explicitly.

---

## Dependencies
```mermaid
flowchart LR
    F001["F-001 · SDK Initialization"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
