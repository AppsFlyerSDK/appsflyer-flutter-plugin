---
id: F-045
name: Deep-Link URL Resolution Allow-list
type: deepLinking
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Advertisers sometimes wrap an AppsFlyer OneLink inside another Universal Link/App Link domain they control. Opening that wrapper link launches the app correctly, but by default the native SDK has no reason to treat the wrapper's own domain as something it should resolve for deep-link data — so the OneLink attribution/deep-link payload underneath never surfaces. `setResolveDeepLinkURLs` lets an app explicitly tell the SDK which additional URL/domains it should attempt to resolve as deep links, so wrapped OneLinks still deliver correct attribution and deep-link data to the app.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called explicitly by the integrating Dart app, typically once at startup (independent of `initSdk`/SDK-start ordering — no code enforces call ordering relative to `initSdk`), whenever the app needs to configure which wrapped/custom domains the SDK should resolve as deep links.

---

## Call Chain
```
AppsflyerSdk.setResolveDeepLinkURLs(List<String> urls)                                     [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setResolveDeepLinkURLs", urls)
    → Android: onMethodCall(call, result) → case "setResolveDeepLinkURLs" → setResolveDeepLinkURLs(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → urls = (ArrayList<String>) call.arguments → urlsArr = urls.toArray(new String[0])
      → AppsFlyerLib.getInstance().setResolveDeepLinkURLs(urlsArr)
      → result.success(null)
    → iOS: handleMethodCall: → case "setResolveDeepLinkURLs" → setResolveDeepLinkURLs:call result:              [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → urlsArr = call.arguments (NSArray) → if urlsArr != nil: [[AppsFlyerLib shared] setResolveDeepLinkURLs:urlsArr]
      → result(nil)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setResolveDeepLinkURLs(List<String> urls)` — thin passthrough invoking the `setResolveDeepLinkURLs` method channel call with the raw URL list |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `onMethodCall` dispatch `case "setResolveDeepLinkURLs"`; `setResolveDeepLinkURLs(MethodCall, Result)` — casts arguments to `ArrayList<String>`, converts to `String[]`, calls `AppsFlyerLib.getInstance().setResolveDeepLinkURLs(urlsArr)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | Method-channel dispatch `case @"setResolveDeepLinkURLs"`; `setResolveDeepLinkURLs:result:` — passes `call.arguments` (an `NSArray`) directly to `[AppsFlyerLib shared] setResolveDeepLinkURLs:]`, guarded only by a nil check |
| `doc/API.md` | Documents the API (`setResolveDeepLinkURLs`) with the wrapped-OneLink rationale and a usage example; does not restrict it to a single platform |

---

## Input / Output
| | |
|--|--|
| **Input** | `List<String> urls` — the domains/URLs (e.g. `"clickdomain.com"`) the SDK should attempt to resolve as deep links. |
| **Output** | None (`result.success(null)`/`result(nil)`) — this configures internal native SDK state; it does not itself deliver deep-link data. Once configured, subsequently opened URLs matching these domains become eligible for the same deep-link resolution flow that ordinarily feeds F-037 (UDL)/F-035/F-036 (legacy) callbacks. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart` does not exercise `setResolveDeepLinkURLs`.

---

## Known Limitations
- **Both platforms implemented, contrary to some Android-only assumptions**: unlike several other Android-specific APIs in this plugin (e.g. `setOutOfStore`, explicitly documented "Android Only!" in `doc/API.md`), `setResolveDeepLinkURLs` has a real native implementation on both Android (`AppsFlyerLib.getInstance().setResolveDeepLinkURLs(String[])`) and iOS (`[AppsFlyerLib shared] setResolveDeepLinkURLs:]`) — `doc/API.md` does not flag any platform restriction for this call, and code confirms both platforms are wired.
- **Android**: casts `call.arguments` directly to `ArrayList<String>` with no null/type check before calling `.toArray(...)` — passing `null` or a non-list argument from Dart would throw a `NullPointerException`/`ClassCastException` inside the plugin rather than failing gracefully.
- **iOS**: silently no-ops if `urlsArr` is `nil` (still calls `result(nil)` as if successful) — a caller passing an unexpected/null value gets no error signal that the call had no effect.
- No ordering guarantee relative to `initSdk`/`startSDK` is enforced or documented; whether URLs must be registered before the SDK starts resolving deep links (to catch a cold-start wrapped link) is not verified by code inspection alone.
- No automated test coverage exists on either the Dart bridge or native implementations for this feature.

---

## Dependencies
```mermaid
flowchart LR
    F045["F-045 · Deep-Link URL Resolution Allow-list"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
```
