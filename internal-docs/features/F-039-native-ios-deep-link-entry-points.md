---
id: F-039
name: Native iOS Deep-Link Entry Points (URL scheme / Universal Links / Scenes)
type: deepLinking
platform: ios
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
iOS only tells an app about an incoming deep link through OS delegate callbacks (`application:openURL:...`, `application:continueUserActivity:...`) or, on the UIScene lifecycle (iOS 13+, and required by Flutter 3.41+'s UIScene migration), `scene:...` methods. The AppsFlyer SDK must intercept every one of these entry points — including the cold-start case where the OS delivers the launch URL/activity before the Flutter/Dart bridge exists — and pass it to the native AppsFlyer SDK so it can resolve OneLink attribution and, ultimately, deliver a `DeepLinkResult` to Dart via F-037. Without this interception layer, deep links opened while the app is fully cold (not yet running) would be silently lost.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Fires whenever iOS launches or resumes the app via a deep link: URI-scheme opens (`openURL`, iOS 9+ and the legacy iOS 8 form), Universal Links (`continueUserActivity`), or — when the host app has migrated to Flutter's UIScene-based lifecycle (`FlutterSceneLifeCycleDelegate`, gated by `__has_include(<Flutter/FlutterSceneLifeCycle.h>)`) — the equivalent `scene:openURLContexts:`, `scene:willConnectToSession:options:` (cold start), and `scene:continueUserActivity:` methods.

---

## Call Chain
```
iOS OS-level deep-link delivery (app already running or resuming):
  application:openURL:options: (iOS 9+)                                    [ios/Classes/AppsflyerSdkPlugin.m]
    → [[AppsFlyerAttribution shared] handleOpenUrl:url options:options]    [ios/Classes/AppsFlyerAttribution.m]
  application:openURL:sourceApplication:annotation: (iOS 8 and below)
    → [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:annotation:]
  application:continueUserActivity:restorationHandler: (Universal Links)
    → [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:]

iOS UIScene-based delivery (Flutter 3.41+ UIScene migration, iOS 13+, only compiled when FlutterSceneLifeCycle.h is available):
  scene:openURLContexts: → for each context → [[AppsFlyerAttribution shared] handleOpenUrl:context.URL options:opts]
  scene:willConnectToSession:options: (cold start via UISceneConnectionOptions)
    → for each URLContext → handleOpenUrl:options:
    → for each userActivity of type NSUserActivityTypeBrowsingWeb → continueUserActivity:restorationHandler:nil
  scene:continueUserActivity: → [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:nil]

AppsFlyerAttribution (buffering singleton, isBridgeReady initially NO)                              [ios/Classes/AppsFlyerAttribution.m]
  handleOpenUrl:.../continueUserActivity:...
    → if isBridgeReady == YES: forward immediately to [AppsFlyerLib shared] handleOpenUrl:/continueUserActivity:
    → else: buffer url/options/sourceApplication/annotation/userActivity/restorationHandler on self

AppsflyerSdkPlugin initSdkWithCall:result: (Dart called initSdk → method channel → native init)      [ios/Classes/AppsflyerSdkPlugin.m]
  → ... [AppsFlyerLib shared] init/start ...
  → [AppsFlyerAttribution shared].isBridgeReady = YES
  → [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self]
    → AppsFlyerAttribution receiveBridgeReadyNotification: (registered as observer in -init)
      → flushes any buffered url/options/sourceApplication/annotation/userActivity to [AppsFlyerLib shared] handleOpenUrl:/continueUserActivity:
        → native SDK resolves the deep link → triggers F-037 (UDL) delivery to Dart
```

---

## Files
| File | Role |
|------|------|
| `ios/Classes/AppsflyerSdkPlugin.m` | `application:openURL:options:`, `application:openURL:sourceApplication:annotation:`, `application:continueUserActivity:restorationHandler:`, and (behind `FlutterSceneLifeCycle.h` availability) `scene:openURLContexts:`, `scene:willConnectToSession:options:`, `scene:continueUserActivity:` — all OS/Scene entry points, each forwarding into `AppsFlyerAttribution`; `initSdkWithCall:result:` sets `isBridgeReady = YES` and posts `AF_BRIDGE_SET` once Dart's `initSdk` call reaches native code |
| `ios/Classes/AppsFlyerAttribution.h` | Declares the `AppsFlyerAttribution` singleton interface: buffering properties (`userActivity`, `restorationHandler`, `url`, `options`, `sourceApplication`, `annotation`), `isBridgeReady` flag, and the `AF_BRIDGE_SET` notification name constant |
| `ios/Classes/AppsFlyerAttribution.m` | Singleton implementation — `handleOpenUrl:...`/`continueUserActivity:...` either forward immediately to `AppsFlyerLib` or buffer until `isBridgeReady`; `receiveBridgeReadyNotification:` flushes exactly one buffered event (checked in priority order: sourceApplication+annotation form, then options form, then userActivity form) when notified |
| `ios/Classes/AppsflyerSdkPlugin.h` | `AppsflyerSdkPlugin` class declaration; conditionally conforms to `FlutterSceneLifeCycleDelegate` when available |

---

## Input / Output
| | |
|--|--|
| **Input** | `NSURL`/`NSDictionary` options (URI-scheme opens), `NSUserActivity` (Universal Links), or `UISceneConnectionOptions`/`UIOpenURLContext` sets (UIScene cold start/live events) — all supplied by iOS, not by Dart. |
| **Output** | No direct Dart-facing output from this feature; it forwards raw URL/activity data into `[AppsFlyerLib shared]`, which performs OneLink resolution and (if UDL is subscribed, F-037) surfaces a `DeepLinkResult` back through the existing callback channel. |

---

## Tests
No dedicated test found — this logic lives entirely in Objective-C native code with no automated coverage found under `test/` (Dart tests only) or any discoverable native (XCTest) test target in `ios/`.

---

## Known Limitations
- **Single-slot buffer, not a queue**: `AppsFlyerAttribution` buffers only one pending deep-link event at a time (a fixed set of instance properties, not a list); if the OS delivers multiple deep-link-shaped events before `isBridgeReady` flips to `YES` (e.g. both a URL and a Universal Link in rapid succession during cold start), only the values from the last call survive — earlier ones are silently overwritten.
- **All delegate methods return `NO`**: every intercepted method explicitly returns `NO`/is documented as "Results of this are ORed and NO doesn't affect other delegate interceptors' result" — by design, so as not to block other plugins/interceptors from also handling the same URL, but it also means AppsFlyer's interception is invisible to code checking the return value for "was this URL handled."
- **UIScene support is conditionally compiled**: the `scene:...` methods only exist when `__has_include(<Flutter/FlutterSceneLifeCycle.h>)` is true (Flutter 3.41+); on older Flutter/Flutter engine versions without UIScene support, only the legacy `UIApplicationDelegate` methods run, and per `doc/DeepLink.md` those legacy methods are also documented as unnecessary from plugin v6.4.0+ if the app doesn't override them itself (i.e. AppsFlyer intercepts automatically via method swizzling/plugin registration, not by requiring the host `AppDelegate` to call these directly).
- The `isBridgeReady`/`AF_BRIDGE_SET` handshake depends on Dart actually calling `initSdk`; if the Dart app never initializes the SDK (or does so much later), buffered deep-link data waits indefinitely in `AppsFlyerAttribution`'s single-slot buffer.
- No test coverage exists for any of the buffering/forwarding logic described here.

---

## Dependencies
```mermaid
flowchart LR
    F039["F-039 · Native iOS Deep-Link Entry Points"]:::deepLinking -->|"forwards resolved URL/activity to native SDK, which triggers"| F037["F-037 · Unified Deep Linking (UDL) Callback & Models"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
