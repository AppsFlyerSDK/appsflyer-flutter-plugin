---
id: F-032
name: Facebook Deferred App Links
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Apps that run Facebook Ads alongside AppsFlyer OneLink need deferred deep links to resolve correctly even when Facebook's own SDK has already claimed the deferred-app-link resolution flow. `enableFacebookDeferredApplinks` tells the native AppsFlyer SDK to interoperate with the Facebook SDK's `FBSDKAppLinkUtility` class so both attribution sources can coexist instead of one silently overriding or racing the other. Without enabling this, apps combining Facebook Ads and AppsFlyer OneLink risk deferred deep links resolving incorrectly (or not at all) for users who install after clicking a Facebook ad.

A companion **iOS-only** API, `setFacebookDeferredAppLink(String? url)`, lets an app that already holds the deferred link set (or clear, with `null`) it directly, bypassing the Facebook SDK fetch.

---

## Trigger
Called once by the host app during startup configuration (before/around SDK init), for apps that have integrated the Facebook SDK and want AppsFlyer to interoperate with its deferred app-link resolution.

---

## Call Chain
Since the SDK 7 / RPC migration this is a generic RPC call (no per-method channel handler): the Dart wrapper sends `{method:'enableFacebookDeferredApplinks', params:{isEnabled:<bool>}}` (params key is **`isEnabled`**) through the single `executeRpc` entry point, and each platform's native RPC bridge parses and forwards it. Both Dart methods are awaitable and surface native failures as `AppsFlyerException`.
```
AppsFlyerSdk.enableFacebookDeferredApplinks(bool isEnabled)                           [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('enableFacebookDeferredApplinks', {'isEnabled': isEnabled})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsFlyerRpcHandler.execute(json)                                        [plugin_bridge/.../AppsFlyerRpcHandler.kt]
        → JsonRpcRequestParser → EnableFacebookDeferredApplinksRequest(isEnabled)  // optBoolean("isEnabled", false)
        → AppsFlyerLib.getInstance().enableFacebookDeferredApplinks(isEnabled)  // true|false forwarded as-is
        → RpcResponse.Success
      → iOS: AppsFlyerRPCBridge / AFRPCRequestHandler                                      [AppsFlyerRPC framework]
        → AFRPCParser → AFRPCEnableFacebookDeferredApplinksRequest(enable)  // requireBool("isEnabled")
        → AFRPCDeepLinkHandler → fbClass = enable ? NSClassFromString("FBSDKAppLinkUtility") : nil
        → sdk.enableFacebookDeferredApplinks(with: fbClass)  ([AppsFlyerLib shared])
```
The iOS-only companion routes the same way:
```
AppsFlyerSdk.setFacebookDeferredAppLink(String? url)                                     [lib/src/appsflyer_sdk.dart]
  → not iOS: log warning, return (no RPC dispatched)
  → _invokeVoidRpc('setFacebookDeferredAppLink', {'url': url})
    → iOS: AppsFlyerRPCBridge / AFRPCRequestHandler → [AppsFlyerLib shared] (unsafe schemes rejected)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `Future<void> enableFacebookDeferredApplinks(bool isEnabled)` — thin passthrough that sends the generic RPC `enableFacebookDeferredApplinks` with `{isEnabled}`. Also `Future<void> setFacebookDeferredAppLink(String? url)` — **iOS only**, guarded by an iOS platform check; sends the `setFacebookDeferredAppLink` RPC with `{url}`. |
| `android/.../plugin_bridge` (native SDK, not the Flutter plugin) | `EnableFacebookDeferredApplinksRequest(isEnabled)`; handler → `AppsFlyerLib.getInstance().enableFacebookDeferredApplinks(isEnabled)` — `true`/`false` forwarded as-is |
| `AppsFlyerRPC` framework (native iOS SDK, not the Flutter plugin) | `AFRPCEnableFacebookDeferredApplinksRequest(enable)`; `AFRPCDeepLinkHandler` maps `enable → NSClassFromString("FBSDKAppLinkUtility")` (true) / `nil` (false), then `sdk.enableFacebookDeferredApplinks(with:)` |
| `android/.../AppsflyerSdkPlugin.kt` / `ios/.../AppsflyerSdkPlugin.swift` | No per-method handler — the generic `executeRpc` dispatch forwards the JSON envelope to the native RPC bridge above. |

---

## Input / Output
| | |
|--|--|
| **Input** | `enableFacebookDeferredApplinks`: `isEnabled` (bool). `setFacebookDeferredAppLink`: `url` (`String?`; `null` clears the current URL). |
| **Output** | `Future<void>` — completes after native RPC validation and the synchronous SDK configuration call. Validation or bridge failures throw `AppsFlyerException`; there is no native completion callback or timeout. On Android, `setFacebookDeferredAppLink` logs a warning and returns without dispatching an RPC. Any resolved data is delivered later through a separately registered conversion-data or UDL stream. |

---

## Tests
`test/appsflyer_sdk_test.dart` → `'maps deep-link, sharing, push, and uninstall APIs'` verifies that `enableFacebookDeferredApplinks(true)` dispatches RPC method `enableFacebookDeferredApplinks` with `{'isEnabled': true}`, and that `setFacebookDeferredAppLink(null)` dispatches `setFacebookDeferredAppLink` with `{'url': null}` on iOS. `'platform-only void calls are ignored without reaching the native RPC'` covers `setFacebookDeferredAppLink` on Android and asserts that no RPC is dispatched. Native behavior (true→class / false→nil on iOS, bool forwarding on Android) is covered by the native SDK's own bridge tests.

---

## Known Limitations
- **No more disable asymmetry (RPC migration)**: both platforms now honor `false`. Android forwards the literal bool; the iOS RPC bridge maps `false → nil` and calls `enableFacebookDeferredApplinks(with: nil)`, so the feature can be turned back off on iOS. (The pre-RPC iOS handler treated `false` as a no-op — that limitation no longer applies.)
- **iOS requires the Facebook SDK linked**: the iOS bridge resolves `FBSDKAppLinkUtility` via `NSClassFromString`, so if the Facebook SDK isn't linked into the app, enabling passes a `nil` class and is effectively a no-op. Android's flag is self-contained. This platform difference is called out in the Dart dartdoc.
- The awaited `Future` confirms that the native RPC request succeeded, not that Facebook deferred-app-link interop actually engaged. A missing `FBSDKAppLinkUtility` class on iOS still resolves successfully.
- `setFacebookDeferredAppLink` is iOS-only: on Android the call is ignored with a logged warning and no RPC is dispatched, so shared code can call it unconditionally but gets no feedback beyond the log line.

---

## Dependencies
```mermaid
flowchart LR
    F032["F-032 · Facebook Deferred App Links"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
