---
id: F-006
name: Custom Host Configuration
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Enterprises operating in regulated markets (for example China) or behind private network/CDN setups need the AppsFlyer SDK to send its HTTPS traffic to a non-default host. `setHost` lets the integrator redirect the SDK's network calls to a custom domain and prefix; `getHostName`/`getHostPrefix` let the app (or diagnostics tooling) read back what is configured on Android. Without this, apps requiring a custom collection endpoint could not integrate AppsFlyer in those environments. Use it only when instructed by AppsFlyer support.

---

## Trigger
`setHost` is awaited by the host app before `start()`, whenever the default AppsFlyer collection host must be overridden. `getHostName`/`getHostPrefix` are awaited on demand (for example from a debug screen) and only on Android.

---

## Call Chain
All three are generic RPC calls. Dart performs no value validation on `setHost`; the two getters are gated by an Android platform check — off Android they log a warning and return `null` without dispatching an RPC. Android RPC requires a non-empty `hostName` but permits an empty `hostPrefixName`; iOS RPC requires both values to be non-empty.

```
AppsFlyerSdk.setHost(String hostPrefixName, String hostName)          [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setHost', {'hostPrefixName': ..., 'hostName': ...})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setHost(...)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] setHost:...

AppsFlyerSdk.getHostName() / AppsFlyerSdk.getHostPrefix()   (Android only)
  → not Android: log warning, return null (no RPC dispatched)
  → _invokeRpc<String>('getHostName' | 'getHostPrefix')
    → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
      → AppsFlyerLib.getHostName() / getHostPrefix()  (returned on the RPC reply)
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setHost(String hostPrefixName, String hostName)`, plus the Android-gated `getHostName()` and `getHostPrefix()` |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic RPC dispatch for `setHost`, `getHostName`, and `getHostPrefix` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Generic RPC dispatch for `setHost` |

---

## Input / Output
| | |
|--|--|
| **Input** | `setHost`: `hostPrefixName` (`String`) and `hostName` (`String`), sent under the RPC param keys `hostPrefixName` and `hostName`. Android RPC requires a non-empty `hostName` and permits an empty `hostPrefixName`; iOS RPC requires both values to be non-empty. `getHostName`/`getHostPrefix`: no parameters (the RPC params map is empty). |
| **Output** | `setHost` → `Future<void>` that completes after RPC validation and the synchronous native setter invocation; it does not confirm that the native SDK accepted or used the host. RPC or bridge failures are exposed as `AppsFlyerException`. `getHostName()`/`getHostPrefix()` → `Future<String?>` on Android; on any other platform they log a warning and return `null` without dispatching an RPC. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps cross-platform configuration and identity APIs'` verifies that `setHost('prefix', 'example.com')` dispatches RPC method `setHost` with params `{'hostPrefixName': 'prefix', 'hostName': 'example.com'}`. `'maps getters and native return values'` verifies that `getHostName()` and `getHostPrefix()` dispatch their RPC methods with an empty params map and return the mocked native values. `'platform-only value calls return a safe default off-platform'` asserts that `getHostName()` and `getHostPrefix()` return `null` on iOS without dispatching an RPC. `'PlatformException with a numeric RPC code becomes AppsFlyerException'` covers the shared error-conversion path, although it does not invoke `setHost` specifically. There is no plugin test for empty or whitespace-only host values.

---

## Known Limitations
- `getHostName`/`getHostPrefix` are Android-only, because the iOS RPC layer exposes no getter. On iOS each logs a warning and returns `null` without dispatching an RPC, so a `null` result cannot be distinguished from "no host configured".
- Dart does not guard against empty values. Android RPC rejects an empty `hostName` with an RPC error but accepts an empty `hostPrefixName`; iOS RPC rejects either empty value. On Android, a whitespace-only `hostName` passes RPC validation but is silently ignored by the native SDK, so the `Future` can still complete successfully without changing the host.
- Must be called before the SDK establishes its first network connection (before `start()`) to take effect; this ordering is not enforced by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F006["F-006 · Custom Host Configuration"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
