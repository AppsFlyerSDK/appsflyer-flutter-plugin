---
id: F-026
name: Additional Custom Data
type: eventsAndRevenue
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Some integrations need to enrich every outbound AppsFlyer SDK request with custom key/value context that doesn't fit any dedicated setter (e.g. app-specific segmentation flags, experiment identifiers, or partner-required metadata) — data that then flows into raw data / Pull-Push API exports alongside attribution and event data for downstream analysis. `setAdditionalData` gives the host app a generic escape hatch to attach arbitrary custom data to the SDK's requests. Without it, any custom context not covered by a named AppsFlyer API would have no way to travel with the SDK's payload.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.setAdditionalData(...)` whenever it needs to attach custom key/value context to subsequent AppsFlyer SDK requests — typically once at startup before `start()`, but callable at any point. Passing an empty map clears previously supplied data.

---

## Call Chain
`setAdditionalData` is an awaitable RPC setter available on both platforms.

```
AppsFlyerSdk.setAdditionalData(customData)                            [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setAdditionalData', {'customData': customData})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.setAdditionalData(...)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → [AppsFlyerRPCBridge shared] executeJson:completion: → AFRPCRequestHandler → SDK
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setAdditionalData(Map<String, dynamic> customData)` — awaitable, platform-agnostic RPC setter; non-null `Map` (pass an empty map to clear) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | No per-method handler — generic `executeRpc` → `dispatchRpc('setAdditionalData', ...)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | No per-method handler — generic `executeRpc` → `dispatchRpc` |
| `doc/api-reference.md` | Public documentation for `setAdditionalData` |

---

## Input / Output
| | |
|--|--|
| **Input** | `customData` (`Map<String, dynamic>`, non-null) — arbitrary key/value pairs; pass an empty map to clear. RPC param key `customData`. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK setter invocation. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or request timeout. Both native SDKs replace the current map, and an empty map clears it. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the cross-platform RPC mapping test that `setAdditionalData({'source': 'flutter'})` dispatches RPC method `setAdditionalData` with `{'customData': {'source': 'flutter'}}`.

---

## Known Limitations
- No documented or enforced key/value shape — arbitrary nested values are passed straight through to the native SDK with no serialization validation in this plugin layer; malformed values surface only as a native RPC failure, reported as `AppsFlyerException`.
- No API reads the current map back. Each call replaces the native runtime value rather than merging it; callers that need additive updates must merge locally and resend the full map.
- The value is retained across foreground cycles in the same process but must be reapplied after a cold start.

---

## Dependencies
```mermaid
flowchart LR
    F026["F-026 · Additional Custom Data"]:::eventsAndRevenue
    classDef eventsAndRevenue fill:#12B886,color:#fff
```
