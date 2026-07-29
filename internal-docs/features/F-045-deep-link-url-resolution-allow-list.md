---
id: F-045
name: Deep-Link URL Resolution Allow-list
type: deepLinking
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Advertisers sometimes wrap an AppsFlyer OneLink inside another Universal Link/App Link domain they control. Opening that wrapper link launches the app correctly, but by default the native SDK has no reason to treat the wrapper's own domain as something it should resolve for deep-link data — so the OneLink attribution/deep-link payload underneath never surfaces. `setResolveDeepLinkURLs` lets an app explicitly tell the SDK which additional URL/domains it should attempt to resolve as deep links, so wrapped OneLinks still deliver correct attribution and deep-link data to the app.

---

## Trigger
Called explicitly by the integrating Dart app, typically once at startup (independent of `initSdk`/SDK-start ordering — no code enforces call ordering relative to `initSdk`), whenever the app needs to configure which wrapped/custom domains the SDK should resolve as deep links.

---

## Call Chain
Since the SDK 7 / RPC migration this is a generic RPC call (no per-method channel handler): the Dart wrapper sends `{method:'setResolveDeepLinkURLs', params:{urls:[...]}}` through the single `executeRpc` entry point, and each platform's native RPC bridge parses it into a typed request and forwards it to the SDK.
```
AppsflyerSdk.setResolveDeepLinkURLs(List<String> urls)                                     [lib/src/appsflyer_sdk.dart]
  → _executeRpc('setResolveDeepLinkURLs', {'urls': urls})   // MethodChannel af-api → executeRpc
    → Android: AppsFlyerRpcHandler.execute(json)                                          [plugin_bridge/.../AppsFlyerRpcHandler.kt]
      → JsonRpcRequestParser → SetResolveDeepLinkURLsRequest(urls)  // init: require(urls.isNotEmpty())
      → handleSetResolveDeepLinkURLs → AppsFlyerLib.getInstance().setResolveDeepLinkURLs(*urls.toTypedArray())
      → RpcResponse.Success
    → iOS: AppsFlyerRPCBridge / AFRPCRequestHandler                                        [AppsFlyerRPC framework]
      → AFRPCParser → AFRPCSetResolveDeepLinkURLsRequest(urls)  // guard: !urls.isEmpty else validationError
      → AFRPCComplexConfigHandler → sdk.resolveDeepLinkURLs = urls  ([AppsFlyerLib shared])
      → SDKSuccess("resolveDeepLinkURLs set with N URL(s)")
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setResolveDeepLinkURLs(List<String> urls)` — thin passthrough that sends the generic RPC `setResolveDeepLinkURLs` with `{urls}`. Fire-and-forget (`void`); does not validate `urls` (see CR-033). |
| `android/.../plugin_bridge` (native SDK, not the Flutter plugin) | `SetResolveDeepLinkURLsRequest(urls)` — `init { require(urls.isNotEmpty()) }`; `AppsFlyerRpcHandler.handleSetResolveDeepLinkURLs` → `AppsFlyerLib.getInstance().setResolveDeepLinkURLs(*urls.toTypedArray())` |
| `AppsFlyerRPC` framework (native iOS SDK, not the Flutter plugin) | `AFRPCSetResolveDeepLinkURLsRequest(urls)` — guards `!urls.isEmpty` else `validationError`; `AFRPCComplexConfigHandler` → `sdk.resolveDeepLinkURLs = urls` |
| `android/.../AppsflyerSdkPlugin.java` / `ios/.../AppsflyerSdkPlugin.m` | No per-method handler — the generic `executeRpc` dispatch forwards the JSON envelope to the native RPC bridge above. |
| `doc/api-reference.md` / `doc/deep-linking.md` | Document the API (`setResolveDeepLinkURLs`) with the wrapped-OneLink rationale and a usage example; not restricted to a single platform |

---

## Input / Output
| | |
|--|--|
| **Input** | `List<String> urls` — the domains/URLs (e.g. `"clickdomain.com"`) the SDK should attempt to resolve as deep links. |
| **Output** | None (`result.success(null)`/`result(nil)`) — this configures internal native SDK state; it does not itself deliver deep-link data. Once configured, subsequently opened URLs matching these domains become eligible for the same deep-link resolution flow that ordinarily feeds F-037 (UDL) and F-035 (GCD) callbacks. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'setResolveDeepLinkURLs maps to urls'` verifies the Dart wrapper dispatches the `setResolveDeepLinkURLs` RPC with the `urls` param. Native contract (empty-list rejection, SDK forwarding) is covered by the native SDK's own bridge tests (`RpcRequestValidationTest` / `AppsFlyerRPCParseNewMethodsTests`).

---

## Known Limitations
- **Both platforms implemented**: `setResolveDeepLinkURLs` has a real native implementation on both Android (`AppsFlyerLib.getInstance().setResolveDeepLinkURLs(String[])`) and iOS (`sdk.resolveDeepLinkURLs = [...]`); the docs do not flag any platform restriction, and both RPC bridges are wired.
- **Empty list is rejected, but the Dart wrapper swallows it (CR-033)**: both native bridges reject an empty `urls` list (Android `require(urls.isNotEmpty())`, iOS `validationError`). The Dart method is fire-and-forget `void` (discards the `_executeRpc` Future — CR-007 class), so `setResolveDeepLinkURLs([])` surfaces only as a swallowed unhandled async error with no caller feedback, and nothing is set. Dart does not pre-validate the list (Cordova, by contrast, guards client-side and silently returns on empty).
- No ordering guarantee relative to `initSdk`/`startSDK` is enforced or documented; whether URLs must be registered before the SDK starts resolving deep links (to catch a cold-start wrapped link) is not verified by code inspection alone.

---

## Dependencies
```mermaid
flowchart LR
    F045["F-045 · Deep-Link URL Resolution Allow-list"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
