---
id: F-030
name: Custom/Branded OneLink Domains
type: oneLinkAndGrowth
platform: both
status: active
last_verified: 2026-07-15
depends_on: []
---

## Business Purpose
Apps that use a custom/branded domain for their OneLinks (instead of the default `*.onelink.me` domain) need the native SDK to recognize those domains as valid AppsFlyer deep-link/OneLink hosts — otherwise links on the branded domain would not be resolved/attributed correctly by the SDK when the app is opened via one of them. `setOneLinkCustomDomain` registers the list of branded domains with the native AppsFlyer SDK so it can correctly parse and attribute links served from them.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called by the host app during setup/configuration, before relying on branded-domain OneLinks being correctly resolved. Not tied to any specific runtime event.

---

## Call Chain
```
AppsflyerSdk.setOneLinkCustomDomain(brandDomains)                                 [lib/src/appsflyer_sdk.dart]
  → _methodChannel.invokeMethod("setOneLinkCustomDomain", brandDomains)
    → Android: AppsflyerSdkPlugin.onMethodCall("setOneLinkCustomDomain") → setOneLinkCustomDomain(call, result)   [android/.../AppsflyerSdkPlugin.java]
      → AppsFlyerLib.getInstance().setOneLinkCustomDomain(brandDomainsArray) → result.success(null)
    → iOS: AppsflyerSdkPlugin.handleMethodCall("setOneLinkCustomDomain") → setOneLinkCustomDomain:result:          [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
      → [[AppsFlyerLib shared] setOneLinkCustomDomains:brandDomains] → result(nil)
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setOneLinkCustomDomain(List<String>)` — public API, passes the list directly as the method-channel arguments (no wrapping map) |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `setOneLinkCustomDomain(call, result)` — casts `call.arguments` to `ArrayList<String>`, converts to `String[]`, forwards to `AppsFlyerLib.getInstance().setOneLinkCustomDomain(...)` |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `setOneLinkCustomDomain:result:` — forwards `call.arguments` directly to `[AppsFlyerLib shared] setOneLinkCustomDomains:]` |

---

## Input / Output
| | |
|--|--|
| **Input** | `brandDomains` (`List<String>`) — sent as the raw method-channel argument, not wrapped in a map |
| **Output** | `void` on both platforms; both native handlers call `result` with `null` unconditionally after forwarding to the native SDK, regardless of whether the domain list was valid |

---

## Tests
`test/appsflyer_sdk_test.dart` — `check setOneLinkCustomDomain call` (line 157) asserts `setOneLinkCustomDomain(["brandDomains"])` dispatches the `"setOneLinkCustomDomain"` method with a `List` argument containing `"brandDomains"`. Native behavior on either platform is not exercised.

---

## Known Limitations
- Android's cast `(ArrayList<String>) call.arguments` will throw a `ClassCastException` if the platform channel deserializes the Dart `List<String>` as a different concrete `List` implementation; this is untested and relies on Flutter's standard codec producing an `ArrayList`.
- Neither platform validates the domain strings (e.g. well-formed host names) before forwarding them to the native SDK — malformed entries are the native SDK's responsibility to reject.
- No callback/confirmation path exists — the call is fire-and-forget on both platforms with no way to detect misconfiguration from Dart.

---

## Dependencies
```mermaid
flowchart LR
    F030["F-030 · Custom/Branded OneLink Domains"]:::oneLinkAndGrowth
    classDef oneLinkAndGrowth fill:#7048E8,color:#fff
```
