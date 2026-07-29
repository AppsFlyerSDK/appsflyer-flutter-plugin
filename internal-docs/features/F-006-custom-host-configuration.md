---
id: F-006
name: Custom Host Configuration
type: sdkCore
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Enterprises operating in regulated markets (e.g. China) or behind private network/CDN setups need the AppsFlyer SDK to send its HTTPS traffic to a non-default host. `setHost` lets the integrator redirect the SDK's network calls to a custom domain/prefix; `getHostName`/`getHostPrefix` let the app (or diagnostics tooling) read back what is configured (Android only). Without this, apps requiring a custom collection endpoint could not integrate AppsFlyer in those environments.

---

## Trigger
Called by the host app before `startSDK()`, whenever the default AppsFlyer collection host must be overridden. `getHostName`/`getHostPrefix` are called on demand (e.g. debug screens) on Android.

---

## Call Chain
All three are generic RPCs. `setHost` is a Dart-side no-op if either argument is empty.

```
AppsflyerSdk.setHost(hostPrefix, hostName)                            [lib/src/appsflyer_sdk.dart]
  → no-op if hostPrefix.isEmpty || hostName.isEmpty
  → _executeRpc('setHost', {hostPrefixName, hostName})
    → af-api "executeRpc" {method:'setHost', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setHost(...)   [android/.../AppsflyerSdkPlugin.java]
      → iOS: dispatchRpc → AppsFlyerRPCBridge → [AppsFlyerLib shared] setHost:...  [ios/.../AppsflyerSdkPlugin.m]

AppsflyerSdk.getHostName() / getHostPrefix()   (Android only; return null on iOS)
  → _executeRpc<String>('getHostName' | 'getHostPrefix')
    → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.getHostName()/getHostPrefix()
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setHost` (empty-guard), `getHostName`, `getHostPrefix` (Android-gated) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | generic RPC dispatch for `setHost` / `getHostName` / `getHostPrefix` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | generic RPC dispatch for `setHost` |

---

## Input / Output
| | |
|--|--|
| **Input** | `setHost`: `hostPrefix` (String), `hostName` (String) — both must be non-empty (RPC param keys `hostPrefixName`/`hostName`). `getHostName`/`getHostPrefix`: none. |
| **Output** | `setHost` → `void`. `getHostName()`/`getHostPrefix()` → `Future<String?>` on Android; **`null` on iOS** (no native RPC-reachable getter). |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `setHost` dispatches the `setHost` RPC with the SDK 7 param names (`hostPrefixName`, `hostName`), and that `setHost` is a no-op when either the prefix or the host is empty.

---

## Known Limitations
- `getHostName`/`getHostPrefix` are Android-only and resolve to `null` on iOS.
- Must be called before the SDK establishes its first network connection (before `startSDK()`) to take effect; this ordering is not enforced by the plugin.

---

## Dependencies
```mermaid
flowchart LR
    F006["F-006 · Custom Host Configuration"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
