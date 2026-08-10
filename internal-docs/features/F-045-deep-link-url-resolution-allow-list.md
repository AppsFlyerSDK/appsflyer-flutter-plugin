---
id: F-045
name: Deep-Link URL Resolution Allow-list
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Advertisers sometimes wrap an AppsFlyer OneLink inside another Universal Link/App Link domain they control. Opening that wrapper link launches the app correctly, but by default the native SDK has no reason to treat the wrapper's own domain as something it should resolve for deep-link data — so the OneLink attribution/deep-link payload underneath never surfaces. `setResolveDeepLinkURLs` lets an app explicitly tell the SDK which additional URL/domains it should attempt to resolve as deep links, so wrapped OneLinks still deliver correct attribution and deep-link data to the app.

---

## Trigger
Awaited explicitly by the integrating Dart app, typically once at startup, whenever the app needs to configure which wrapped/custom domains the SDK should resolve as deep links. Nothing in the Flutter layer enforces ordering relative to `init()` or `start()`, and the dartdoc states no ordering requirement.

The sibling API for branded OneLink domains is `setOneLinkCustomDomain(List<String> domains)`, which follows the same RPC shape with a `domains` parameter.

---

## Call Chain
This is a generic RPC call (no per-method channel handler): the Dart wrapper sends `{method: 'setResolveDeepLinkURLs', params: {urls: [...]}}` through the single `executeRpc` entry point, and each platform's native RPC bridge parses it into a typed request and forwards it to the SDK.

```
AppsFlyerSdk.setResolveDeepLinkURLs(List<String> urls)                                     [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('setResolveDeepLinkURLs', {'urls': urls})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → SetResolveDeepLinkURLsRequest(urls)  // init: require(urls.isNotEmpty())
        → AppsFlyerLib.getInstance().setResolveDeepLinkURLs(*urls.toTypedArray())
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
        → AFRPCSetResolveDeepLinkURLsRequest(urls)  // guard: !urls.isEmpty else validationError
        → sdk.resolveDeepLinkURLs = urls  ([AppsFlyerLib shared])
  → successful reply completes Future<void>
  → PlatformException is converted to AppsFlyerException
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setResolveDeepLinkURLs(List<String> urls)` — awaitable passthrough that sends the generic RPC `setResolveDeepLinkURLs` with `{urls}`; performs no Dart-side validation |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic `executeRpc` dispatch — forwards the JSON envelope to the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Generic `executeRpc` dispatch — forwards the JSON envelope to the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `urls` (`List<String>`) — the domains/URLs (for example `"click.example.com"`) the SDK should attempt to resolve as deep links. The native bridges require a non-empty list. |
| **Output** | `Future<void>` completes after native RPC validation and the synchronous SDK setter invocation. An empty list or bridge failure throws `AppsFlyerException`; there is no native completion callback or timeout. Configuring the allow-list does not itself deliver data; matching URLs become eligible for the UDL resolution flow in F-037. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps deep-link, sharing, push, and uninstall APIs'` verifies that `setResolveDeepLinkURLs(['example.com'])` dispatches RPC method `setResolveDeepLinkURLs` with params `{'urls': ['example.com']}`. The same test covers the sibling `setOneLinkCustomDomain` mapping. `'PlatformException becomes AppsFlyerException'` covers the shared error conversion this method relies on. Native contract enforcement (empty-list rejection, SDK forwarding) is covered by the native SDKs' own bridge tests.

---

## Known Limitations
- **Both platforms implemented**: `setResolveDeepLinkURLs` has a real native implementation on Android (`AppsFlyerLib.getInstance().setResolveDeepLinkURLs(String[])`) and iOS (`sdk.resolveDeepLinkURLs = [...]`), and both RPC bridges are wired.
- **Empty list fails at the native bridge, not in Dart**: both bridges reject an empty `urls` list. Because the method is awaitable, that rejection now reaches the caller as `AppsFlyerException` instead of being swallowed — but Dart still does not pre-validate, so the round trip happens before the error is known.
- No ordering guarantee relative to `init()`/`start()` is enforced. Whether URLs must be registered before the SDK starts resolving deep links (to catch a cold-start wrapped link) is not verified by code inspection alone.

---

## Dependencies
```mermaid
flowchart LR
    F045["F-045 · Deep-Link URL Resolution Allow-list"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
