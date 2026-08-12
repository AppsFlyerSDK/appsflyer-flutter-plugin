---
id: F-039
name: Native iOS Deep-Link Entry Points (URL scheme / Universal Links / Scenes)
type: deepLinking
platform: ios
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
iOS only tells an app about an incoming deep link through OS delegate callbacks (`application:openURL:...`, `application:continueUserActivity:...`) or, on the UIScene lifecycle (iOS 13+, and required by Flutter 3.41+'s UIScene migration), `scene:...` methods. The AppsFlyer SDK must intercept every one of these entry points — including the cold-start case where the OS delivers the launch URL/activity before the Flutter/Dart bridge exists — and pass it to the native AppsFlyer SDK so it can resolve OneLink attribution and, ultimately, deliver a `DeepLinkResult` to Dart via F-037. Without this interception layer, deep links opened while the app is fully cold (not yet running) would be silently lost. Flutter drives these entry points automatically (the plugin registers as an application/scene delegate), so the host `AppDelegate` does not need to forward `openURL`/`continueUserActivity` manually.

---

## Trigger
Fires whenever iOS launches or resumes the app via a deep link: URI-scheme opens (`openURL`, iOS 9+ and the legacy iOS 8 form), Universal Links (`continueUserActivity`), or — when the host app has migrated to Flutter's UIScene-based lifecycle (`FlutterSceneLifeCycleDelegate`, gated by `__has_include(<Flutter/FlutterSceneLifeCycle.h>)`) — the equivalent `scene:openURLContexts:`, `scene:willConnectToSession:options:` (cold start), and `scene:continueUserActivity:` methods.

---

## Call Chain
```
iOS OS-level deep-link delivery (app already running or resuming):
  application:openURL:options: (iOS 9+)                                    [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift]
    → [[AppsFlyerAttribution shared] handleOpenUrl:url options:options]    [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerAttribution.swift]
  application:openURL:sourceApplication:annotation: (iOS 8 and below)
    → [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:annotation:]
  application:continueUserActivity:restorationHandler: (Universal Links)
    → [[AppsFlyerAttribution shared] continueUserActivity:userActivity]

iOS UIScene-based delivery (Flutter 3.41+ UIScene migration, iOS 13+, only compiled when FlutterSceneLifeCycle.h is available):
  scene:openURLContexts: → for each context → [[AppsFlyerAttribution shared] handleOpenUrl:context.URL options:opts]
  scene:willConnectToSession:options: (cold start via UISceneConnectionOptions)
    → for each URLContext → handleOpenUrl:options:
    → for each userActivity of type NSUserActivityTypeBrowsingWeb → continueUserActivity:
  scene:continueUserActivity: → [[AppsFlyerAttribution shared] continueUserActivity:userActivity]

AppsFlyerAttribution (queueing singleton, isBridgeReady initially NO)                               [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerAttribution.swift]
  handleOpenUrl:.../continueUserActivity:...
    → builds an RPC envelope: handleOpenUrl / handleOpenURL / continueUserActivity with {url, options|activityType}
    → executeOrQueueMethod:params:
      → if isBridgeReady == YES: [[AppsFlyerRPCBridge shared] executeJson:completion:]
      → else: append {method, params} to the pendingRequests queue

AppsflyerSdkPlugin initFromRpc:result: (Dart AppsFlyerSdk.init() → af-api executeRpc('init') → native init sequence)   [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift]
  → runSequence: setPluginInfo → initialize
  → [[AppsFlyerAttribution shared] markBridgeReady]
    → isBridgeReady = YES, then drains pendingRequests through [[AppsFlyerRPCBridge shared] executeJson:]
      → native SDK resolves the deep link → triggers F-037 (UDL) delivery to Dart
```
Deep-link listener registration is no longer part of the init sequence. Dart registers it explicitly with `AppsFlyerSdk.registerDeepLinkListener()`, which sends the `registerDeeplinkListener` RPC on iOS.

---

## Files
| File | Role |
|------|------|
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | `application:openURL:options:`, `application:openURL:sourceApplication:annotation:`, `application:continueUserActivity:restorationHandler:`, and (registered only when the registrar responds to `addSceneDelegate:`) `scene:openURLContexts:`, `scene:willConnectToSession:options:`, `scene:continueUserActivity:` — all OS/Scene entry points, each forwarding into `AppsFlyerAttribution`; `initFromRpc:result:` calls `markBridgeReady` once Dart's `init()` (`executeRpc('init')`) RPC sequence completes |
| Generated `appsflyer_sdk-Swift.h` | Exposes the `AppsFlyerAttribution` singleton interface to Objective-C: the three `handleOpenUrl:`/`continueUserActivity:` entry points and `markBridgeReady`, all pinned with explicit `@objc(...)` selectors in the Swift source |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerAttribution.swift` | Singleton implementation — private `isBridgeReady` flag and `pendingRequests` queue; `handleOpenUrl:...`/`continueUserActivity:...` build an RPC envelope and pass it to `executeOrQueueMethod:params:`, which either sends it through `AppsFlyerRPCBridge` or appends to the queue; `markBridgeReady` sets `isBridgeReady` and drains that queue in arrival order |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` (registration) | `@objc(AppsflyerSdkPlugin)` pins the runtime class name; scene-lifecycle support is registered at runtime via `registrar.responds(to: #selector(addSceneDelegate:))` instead of a compile-time header check, since Swift has no `__has_include` equivalent for a framework subheader |

---

## Input / Output
| | |
|--|--|
| **Input** | `NSURL`/`NSDictionary` options (URI-scheme opens), `NSUserActivity` (Universal Links), or `UISceneConnectionOptions`/`UIOpenURLContext` sets (UIScene cold start/live events) — all supplied by iOS, not by Dart. |
| **Output** | No direct Dart-facing output from this feature; it forwards the URL/activity data through `AppsFlyerRPCBridge` into the native SDK, which performs OneLink resolution and (if the deep-link listener is registered, F-037) surfaces a `DeepLinkResult` on the `onDeepLinkReceived` stream over the `af-events` EventChannel. |

---

## Tests
No dedicated test found — this logic lives entirely in Swift native code with no automated coverage found under `test/` (Dart tests only) or any discoverable native (XCTest) test target in `ios/`.

---

## Known Limitations
- **Queued, but only JSON-serializable data survives**: `AppsFlyerAttribution` keeps every early event in the `pendingRequests` queue and drains them in arrival order, so multiple deep-link-shaped events during cold start are all forwarded. Each entry is an RPC envelope. `openURL` `options`/`annotation` values are filtered through `jsonSafeOptionsFromDictionary:` before queueing or send; non-JSON entries are omitted rather than failing the whole deep link.
- **`restorationHandler` is not forwarded**: `UIApplicationDelegate` requires the parameter on `continueUserActivity:`, but attribution only needs `webpageURL` for RPC (the AppsFlyer SDK ignores the handler as well). Handoff/UI restoration remains the host app's responsibility.
- **All delegate methods return `NO`**: every intercepted method (including `application:didFinishLaunchingWithOptions:`) explicitly returns `NO`. Flutter ORs the results of its registered delegates, so returning `NO` avoids blocking other plugins from handling the same URL — but it also means AppsFlyer's interception is invisible to code that checks the return value for "was this URL handled."
- **UIScene support is conditionally compiled**: the `scene:...` methods only exist when `__has_include(<Flutter/FlutterSceneLifeCycle.h>)` is true (Flutter 3.41+); on older Flutter engine versions without UIScene support, only the legacy `UIApplicationDelegate` methods run. Either way the host `AppDelegate` does not have to forward anything, because the plugin is registered as a delegate itself.
- The `markBridgeReady` handshake depends on Dart actually calling `AppsFlyerSdk.init()`; if the app never initializes the SDK (or does so much later), queued deep-link data waits indefinitely in `pendingRequests`. A failed init sequence returns the error to Dart without marking the bridge ready, so the queue is never drained for that launch. When the owning Flutter engine detaches, `resetBridgeStateIfOwned(by:)` clears the singleton gate and pending queue so a recreated engine does not inherit a stale open gate from the previous instance.
- **Interim architecture**: this class JSON-encodes native deep-link entry points into `AFRPCBridge.executeJson` because the Flutter plugin predates the upstream RPC lifecycle-callback wrapper (`AFRPCContinueUserActivityRequest`, `AFRPCHandleOpenURLRequest`, etc.). Migrate to the typed lifecycle API when that wrapper ships; this class is then a deletion candidate rather than a long-term home for queue state.
- **RPC failures are logged, not surfaced to the host**: `execute(method:params:)` logs serialization and RPC/SDK errors through `os_log`; there is still no synchronous host callback — UDL results arrive on `af-events` only.
- **`handleLaunchOptions` is forwarded at launch**: `application:didFinishLaunchingWithOptions:` sanitizes launch options and immediately sends `handleLaunchOptions` through `AFRPCBridge` (fire-and-forget). The native SDK has no `initialize` dependency on that call; it only sets a pending-deeplink flag that `registerSessionReadyListener` samples later. `NSURL` values are converted to strings and non-JSON values are dropped.
- No test coverage exists for any of the buffering/forwarding logic described here.

---

## Dependencies
```mermaid
flowchart LR
    F039["F-039 · Native iOS Deep-Link Entry Points"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
