---
id: F-020
name: AppsFlyer UID Retrieval
type: sdkCore
platform: both
status: active
last_verified: 2026-08-04
depends_on: []
---

## Business Purpose
Every install gets a unique AppsFlyer-generated device/install ID, which is the primary key AppsFlyer uses internally to tie together attribution, in-app events, and reporting for that install. Host apps often need this same ID for their own backend correlation (for example sending it alongside server-side purchase records, or cross-referencing support tickets with AppsFlyer's dashboard and raw-data reports). `getAppsFlyerUID()` is the only supported way to read that ID from Dart.

---

## Trigger
Awaited on demand by the host app — typically after `init()`, to attach the AppsFlyer ID to internal analytics, support diagnostics, or server-side event payloads.

---

## Call Chain
A generic RPC round trip with a typed native return value. Unlike `getHostName`/`getHostPrefix`, this getter is available on both platforms and has no platform guard.

```
AppsFlyerSdk.getAppsFlyerUID()                                        [lib/src/appsflyer_sdk.dart]
  → _invokeRpc<String>('getAppsFlyerUID')
    → MethodChannel('af-api').invokeMethod('executeRpc', {method: 'getAppsFlyerUID', params: {}})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.getInstance().getAppsFlyerUID(context)  (returned on the RPC reply)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → [[AppsFlyerLib shared] getAppsFlyerUID]  (returned on the RPC reply)
  → resolves Future<String?> with the native value
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `getAppsFlyerUID()` — `Future<String?>` round trip over the `getAppsFlyerUID` RPC, with no platform guard and no post-processing of the native value |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | RPC bridge entry (`executeRpc`) routing `getAppsFlyerUID` to `AppsFlyerRpcHandler` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | RPC bridge entry (`executeRpc`) forwarding `getAppsFlyerUID` to `AppsFlyerRPCBridge` |

---

## Input / Output
| | |
|--|--|
| **Input** | None. The RPC params map is empty. |
| **Output** | `Future<String?>` — the AppsFlyer-generated unique ID for this install. It may resolve to `null` if the native SDK returns no value, for example when the ID has not been generated yet. Native errors surface as `AppsFlyerException`. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps getters and native return values'` stubs the mocked `af-api` channel with `'uid'`, asserts that `getAppsFlyerUID()` returns it, and asserts the dispatched RPC method is `getAppsFlyerUID`. `'PlatformException becomes AppsFlyerException'` covers the shared error conversion this getter relies on.

---

## Known Limitations
- **Unlike `getSdkVersion`, an empty or missing ID is not rejected**: `getAppsFlyerUID` returns the native value verbatim, including `null`. Callers must handle a missing ID themselves.
- No documented guarantee about the ID's availability timing relative to `init()`/`start()`. Calling it too early can return an empty string or `null` depending on platform and SDK version, and the Dart API offers no way to await "ID ready."
- The null and empty-string edge cases are not covered by tests on either platform.

---

## Dependencies
```mermaid
flowchart LR
    F020["F-020 · AppsFlyer UID Retrieval"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
