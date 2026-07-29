---
id: F-030
name: Custom/Branded OneLink Domains
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Apps that use a custom/branded domain for their OneLinks (instead of the default `*.onelink.me` domain) need the native SDK to recognize those domains as valid AppsFlyer deep-link/OneLink hosts — otherwise links on the branded domain would not be resolved/attributed correctly by the SDK when the app is opened via one of them. `setOneLinkCustomDomain` registers the list of branded domains with the native AppsFlyer SDK so it can correctly parse and attribute links served from them.

---

## Trigger
Called by the host app during setup/configuration, before relying on branded-domain OneLinks being correctly resolved. Not tied to any specific runtime event.

---

## Call Chain
Since the SDK 7 / RPC migration this is a generic RPC call (no per-method channel handler): the Dart wrapper sends `{method:'setOneLinkCustomDomain', params:{domains:[...]}}` through the single `executeRpc` entry point (note the list is **wrapped in a `domains` map key**, not passed as the raw argument), and each platform's native RPC bridge parses it into a typed request and forwards it to the SDK.
```
AppsflyerSdk.setOneLinkCustomDomain(List<String> brandDomains)                    [lib/src/appsflyer_sdk.dart]
  → _executeRpc('setOneLinkCustomDomain', {'domains': brandDomains})   // MethodChannel af-api → executeRpc
    → Android: AppsFlyerRpcHandler.execute(json)                                          [plugin_bridge/.../AppsFlyerRpcHandler.kt]
      → JsonRpcRequestParser → SetOneLinkCustomDomainRequest(domains)  // init: require(domains.isNotEmpty())
      → AppsFlyerLib.getInstance().setOneLinkCustomDomain(*domains.toTypedArray())
      → RpcResponse.Success
    → iOS: AppsFlyerRPCBridge / AFRPCRequestHandler                                        [AppsFlyerRPC framework]
      → AFRPCParser → AFRPCSetOneLinkCustomDomainsRequest(domains)  // guard: !domains.isEmpty else validationError
      → AFRPCComplexConfigHandler → sdk.oneLinkCustomDomains = domains  ([AppsFlyerLib shared])
      → SDKSuccess("oneLinkCustomDomains set with N domain(s)")
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setOneLinkCustomDomain(List<String> brandDomains)` — thin passthrough that sends the generic RPC `setOneLinkCustomDomain` with `{domains}`. Fire-and-forget (`void`); does not validate the list (see CR-036). |
| `android/.../plugin_bridge` (native SDK, not the Flutter plugin) | `SetOneLinkCustomDomainRequest(domains)` — `init { require(domains.isNotEmpty()) }`; handler → `AppsFlyerLib.getInstance().setOneLinkCustomDomain(*domains.toTypedArray())` |
| `AppsFlyerRPC` framework (native iOS SDK, not the Flutter plugin) | `AFRPCSetOneLinkCustomDomainsRequest(domains)` — guards `!domains.isEmpty` else `validationError`; `AFRPCComplexConfigHandler` → `sdk.oneLinkCustomDomains = domains` |
| `android/.../AppsflyerSdkPlugin.java` / `ios/.../AppsflyerSdkPlugin.m` | No per-method handler — the generic `executeRpc` dispatch forwards the JSON envelope to the native RPC bridge above. |

---

## Input / Output
| | |
|--|--|
| **Input** | `brandDomains` (`List<String>`) — sent wrapped in the RPC params map under the `domains` key (`{'domains': brandDomains}`) |
| **Output** | `void` — the Dart wrapper discards the `_executeRpc` Future (fire-and-forget). Native returns an RPC success/error, but Dart does not surface it (see CR-036). |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'setOneLinkCustomDomain maps to domains'` verifies the Dart wrapper dispatches the `setOneLinkCustomDomain` RPC with the `domains` param. Native contract (empty-list rejection, SDK forwarding) is covered by the native SDK's own bridge tests (`RpcRequestValidationTest` / `AppsFlyerRPCParseNewMethodsTests`).

---

## Known Limitations
- **Empty list is rejected, but the Dart wrapper swallows it (CR-036)**: both native bridges reject an empty `domains` list (Android `require(domains.isNotEmpty())`, iOS `validationError`). The Dart method is fire-and-forget `void` (discards the `_executeRpc` Future — CR-007 class), so `setOneLinkCustomDomain([])` surfaces only as a swallowed unhandled async error with no caller feedback, and nothing is set. Dart does not pre-validate the list.
- Neither the plugin nor the bridge validates the domain strings for well-formedness (e.g. valid host names) — malformed entries are the native SDK's responsibility to reject.
- No success/confirmation is surfaced to Dart — the call is fire-and-forget, so a Dart caller cannot detect misconfiguration.

---

## Dependencies
```mermaid
flowchart LR
    F030["F-030 · Custom/Branded OneLink Domains"]:::oneLinkAndGrowth
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
