---
id: F-006
name: Custom Host Configuration
type: sdkCore
platform: both
status: active
last_verified: 2026-08-25
depends_on: []
---

## Business Purpose
Enterprises operating in regulated markets (for example China) or behind private network/CDN setups need the AppsFlyer SDK to send its HTTPS traffic to a non-default host. `setHost` lets the integrator redirect the SDK's network calls to a custom domain and prefix; `getHostName`/`getHostPrefix` let the app (or diagnostics tooling) read back what is configured. Without this, apps requiring a custom collection endpoint could not integrate AppsFlyer in those environments. Use it only when instructed by AppsFlyer support.

---

## Trigger
`setHost` is awaited by the host app before `start()`, whenever the default AppsFlyer collection host must be overridden. `getHostName`/`getHostPrefix` are awaited on demand, for example from a debug screen.

---

## Call Chain
All three are generic RPC calls. Dart performs no value validation on `setHost`. Android RPC requires a non-empty `hostName` but permits an empty `hostPrefixName`; iOS RPC requires both values to be non-empty.

```
AppsFlyerSdk.setHost(String hostPrefixName, String hostName)          [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setHost', {'hostPrefixName': ..., 'hostName': ...})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setHost(...)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] setHost:...

AppsFlyerSdk.getHostName() / AppsFlyerSdk.getHostPrefix()
  → _invokeRpc<String>('getHostName' | 'getHostPrefix')
    → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
      → AppsFlyerLib.getHostName() / getHostPrefix()  (returned on the RPC reply)
    → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
      → [AppsFlyerLib shared] host / hostPrefix, bridged as "" when unset
  → PlatformException is converted to AppsFlyerException
```

AppsFlyerRPC 7.0.13 added `getHostName` and `getHostPrefix` to iOS; before that release both were Android-only and threw on iOS.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setHost(String hostPrefixName, String hostName)`, `getHostName()`, and `getHostPrefix()` routed through RPC without a Dart guard |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Generic RPC dispatch for `setHost`, `getHostName`, and `getHostPrefix` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Generic RPC dispatch for `setHost`, `getHostName`, and `getHostPrefix` |

---

## Input / Output
| | |
|--|--|
| **Input** | `setHost`: `hostPrefixName` (`String`) and `hostName` (`String`), sent under the RPC param keys `hostPrefixName` and `hostName`. Android RPC requires a non-empty `hostName` and permits an empty `hostPrefixName`; iOS RPC requires both values to be non-empty. `getHostName`/`getHostPrefix`: no parameters (the RPC params map is empty). |
| **Output** | `setHost` → `Future<void>` that completes after RPC validation and the synchronous native setter invocation; it does not confirm that the native SDK accepted or used the host. RPC or bridge failures are exposed as `AppsFlyerException`. `getHostName()`/`getHostPrefix()` → `Future<String>` on both platforms; iOS yields an empty string when `setHost` has not been called. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps cross-platform configuration and identity APIs'` verifies that `setHost('prefix', 'example.com')` dispatches RPC method `setHost` with params `{'hostPrefixName': 'prefix', 'hostName': 'example.com'}`. `'maps getters and native return values'` verifies that `getHostName()` and `getHostPrefix()` dispatch their RPC methods with an empty params map and return the mocked native values. `'unexpected null RPC result throws AppsFlyerException'` covers `getHostName()` and `getHostPrefix()` when the native reply is unexpectedly null. `'maps getters and native return values'` also asserts both getters dispatch on iOS, covering the 7.0.13 availability change. `'PlatformException with a numeric RPC code becomes AppsFlyerException'` covers the shared error-conversion path, although it does not invoke `setHost` specifically. There is no plugin test for empty or whitespace-only host values.

---

## Known Limitations
- `getHostName`/`getHostPrefix` cannot distinguish "not configured" from "configured as empty" on iOS: the native `host`/`hostPrefix` properties are nil before `start()` and the RPC layer bridges that to `""`. On Android an unexpected native null reply throws instead of surfacing as `null`.
- Dart does not guard against empty values. Android RPC rejects an empty `hostName` with an RPC error but accepts an empty `hostPrefixName`; iOS RPC rejects either empty value. On Android, a whitespace-only `hostName` passes RPC validation but is silently ignored by the native SDK, so the `Future` can still complete successfully without changing the host.
- Must be called before the SDK establishes its first network connection (before `start()`) to take effect; this ordering is not enforced by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F006["F-006 · Custom Host Configuration"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
