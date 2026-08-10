---
id: F-068
name: Deep-Link URL Parameter Appending
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`appendParametersToDeepLinkingURL` configures parameters that the native SDK adds to matching deep-link URLs before resolution. It supports integrations that need stable attribution or routing parameters on links containing a known substring.

## Trigger
Called during startup configuration before the matching URL is resolved, whether resolution comes from lifecycle entry points or `performDeepLinking`.

## Call Chain
```
AppsFlyerSdk.appendParametersToDeepLinkingURL(contains, parameters)   [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('appendParametersToDeepLinkingURL', {contains, parameters})
    → platform RPC validates request
      → native SDK appendParametersToDeepLinkingURL(contains, parameters)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public API and string-map serialization |
| Android `plugin_bridge/.../RpcRequest.kt` and `AppsFlyerRpcHandler.kt` | Request parsing and SDK call |
| iOS `AppsFlyerRPC/.../AFRPCTypedRequests.swift` and `AFRPCDeepLinkHandler.swift` | Request validation and SDK call |

## Input / Output
| | |
|--|--|
| **Input** | Non-empty `contains` substring and `Map<String, String> parameters`. Android permits an empty map; iOS rejects one. |
| **Output** | `Future<void>` completes after validation and synchronous native configuration, with no callback or timeout. Validation/bridge failures surface as `AppsFlyerException`. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the complete Dart RPC map. Native suites cover parser/handler behavior; there is no Flutter integration test that resolves a matching URL and inspects the rewritten result.

## Known Limitations
- Dart does not enforce the platform difference for an empty parameter map.
- The Future confirms configuration only, not that a later URL matched or resolved.
- Matching and merge precedence are owned by the native SDK; the Flutter plugin does not inspect or sanitize URL values.

## Dependencies
No required feature dependency.
