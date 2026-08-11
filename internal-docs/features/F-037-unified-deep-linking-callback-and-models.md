---
id: F-037
name: Unified Deep Linking (UDL) Callback & Models
type: deepLinking
platform: both
status: active
last_verified: 2026-08-10
depends_on: ["F-001", "F-039", "F-040"]
---

## Business Purpose
Unified Deep Linking is AppsFlyer's current recommended API for both direct and deferred deep linking: a single Dart stream (`onDeepLinkReceived`) delivers one strongly-shaped result (`DeepLinkResult` — a `DeepLinkStatus`, an optional `DeepLinkFailure`, and an optional `DeepLink` payload) regardless of whether the link was clicked while the app was already installed or triggered a deferred install. It is the SDK 7 replacement for the legacy, now-removed OAOA path (F-036); install-time attribution is still available via GCD (F-035).

---

## Trigger
The host app subscribes to `onDeepLinkReceived` and calls `registerDeepLinkListener()` after `init()`. The native SDK then resolves a deep link (direct click while installed, or deferred deep link surfaced after a fresh install) and invokes its UDL delegate/listener. There is no init-time flag: registration is an explicit RPC call that maps to `subscribeForDeepLink` on Android and `registerDeeplinkListener` on iOS. The underlying native trigger differs per platform: on Android the SDK inspects the launch/new intent (F-040); on iOS it is `handleOpenUrl:`/`continueUserActivity:` buffered by `AppsFlyerAttribution` (F-039).

---

## Call Chain
Registration is an ordinary awaitable RPC. Results arrive on the **`af-events` EventChannel** as a native RPC JSON envelope, are parsed into a `_AppsFlyerEvent` (`name` + `data`), and are mapped into a `DeepLinkResult`.

```
AppsFlyerSdk.onDeepLinkReceived.listen(...)                            [lib/src/appsflyer_sdk.dart]
  → filter of the shared af-events broadcast stream
      (event.name == 'onDeepLinking' || event.name == 'onDeepLinkReceived')

AppsFlyerSdk.registerDeepLinkListener()
  → _invokeVoidRpc(isAndroid ? 'subscribeForDeepLink' : 'registerDeeplinkListener')
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge

Native deep link resolved (via F-039 iOS entry points / F-040 Android intent handling):
  → Android: AppsFlyerEventBus.publish(json) → EventChannel('af-events'), buffered until a sink attaches
  → iOS: deliverEvent(json) on EventChannel('af-events'), buffered in pendingEvents until Dart subscribes
    → _AppsFlyerEvent.fromNative(json)                                 [lib/src/appsflyer_event.dart]
      → DeepLinkResult._fromEvent(event, platform: _platform)             [lib/src/udl/deep_link_result.dart]
          status   = data['status'] normalized to DeepLinkStatus
          deepLink = DeepLink(decoded data['deepLink'])                [lib/src/udl/deeplink.dart]
          error    = Android ? DeepLinkFailure(type: ...) : DeepLinkFailure(message: ...)
```

Android also exposes `unregisterDeeplinkListener()`, which dispatches `unsubscribeForDeepLink`; on iOS the call is ignored with a logged warning and no RPC is dispatched.

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `onDeepLinkReceived` stream, `registerDeepLinkListener()` (platform-specific RPC name), and the Android-only `unregisterDeeplinkListener()` |
| `lib/src/appsflyer_event.dart` | `_AppsFlyerEvent.fromNative` — parses the RPC envelope (`event`, map-or-null `data`) |
| `lib/src/udl/deeplink.dart` | `DeepLink` — the raw `clickEvent` map plus typed accessors (`deepLinkValue`, `matchType`, `clickHttpReferrer`, `mediaSource`, `campaign`, `campaignId`, `afSub1..5`, `isDeferred`) and `getStringValue(key)` |
| `lib/src/udl/deep_link_result.dart` | `DeepLinkResult` (`status`, `deepLink`, `error`, `toJson`), `DeepLinkResult._fromEvent`, `DeepLinkStatus` (`found`/`notFound`/`error`/`unknown`), and `DeepLinkFailure` (`type`, `message`) |
| `android/.../AppsflyerSdkPlugin.kt` | `rpcEventNotifier` hops the bridge deep-link event to the main thread and publishes it to `AppsFlyerEventBus`; `createEventSink` adapts this engine's `af-events` sink |
| `android/.../AppsFlyerEventBus.kt` | Process-scoped buffer and FIFO replay, so a deep link resolved while no engine is attached is delivered to the next subscriber instead of being lost |
| `ios/.../AppsflyerSdkPlugin.swift` | `handleBridgeEvent` / `deliverEvent` forward the event to the `af-events` sink and buffer it in `pendingEvents` until Dart subscribes |

---

## Input / Output
| | |
|--|--|
| **Input** | None from Dart beyond `registerDeepLinkListener()`; the deep-link click event originates from AppsFlyer's OneLink resolution, delivered into the native SDK via F-039 (iOS) / F-040 (Android) entry points or the SDK's own intent/URL inspection. |
| **Output** | `DeepLinkResult { DeepLinkStatus status, DeepLink? deepLink, DeepLinkFailure? error }` emitted on `onDeepLinkReceived`. `DeepLink` exposes the raw click-event map plus typed getters. UDL privacy protection means new users' payloads are limited to `deep_link_value`/`deep_link_sub1-10`; other getters may return `null`. `DeepLinkResult.toJson()` serializes the result back to its JSON form. |

---

## Tests
`test/appsflyer_sdk_test.dart`:
- `normalizes Android and iOS deep-link status without hiding errors` — builds `DeepLinkResult._fromEvent` from an Android `onDeepLinking` envelope (`FOUND` + JSON-string `deepLink`) and an iOS `onDeepLinkReceived` failure envelope, asserting the mapped `DeepLinkStatus`, `deepLinkValue`, `isDeferred`, and that the iOS failure carries a `message` but no `type`.
- `listeners are registered explicitly` — asserts `registerDeepLinkListener()` dispatches `subscribeForDeepLink` on Android and `registerDeeplinkListener` on iOS.
- `maps every Android-only API` — asserts `unregisterDeeplinkListener` dispatches `unsubscribeForDeepLink`.
- `platform-only void calls are ignored without reaching the native RPC` — asserts `unregisterDeeplinkListener` on iOS dispatches no RPC.

`test/appsflyer_sdk_test.dart` — `routes deep-link events with an object data payload` covers an `onDeepLinkReceived` envelope whose `data` is a JSON object.

---

## Known Limitations
- `onDeepLinkReceived` is a broadcast stream, so multiple subscribers are supported, but events delivered before any subscription exists are not replayed by Dart. Subscribe before calling `registerDeepLinkListener()`.
- **Unrecognized status strings** fall back to `DeepLinkStatus.unknown`; `DeepLinkResult._fromEvent` never throws on an unexpected status.
- Failure detail is asymmetric by design: Android populates `DeepLinkFailure.type` (a stable error type) and iOS populates `DeepLinkFailure.message` (a localized string). Neither platform fills both.
- Android RPC 7.0.1 serializes the native click event via `org.json.JSONObject.toString()`, which is valid JSON. `_decodeDeepLink` decodes it directly with `jsonDecode` (types, including `is_deferred`, are preserved); a malformed/non-JSON string is treated as "no deep link" (`null`) rather than partially parsed.
- **`DeepLink.isDeferred` is unreliable on iOS**: the native `AppsFlyerDeepLink.clickEvent` dictionary never includes an `is_deferred` key (the flag lives on a separate native `isDeferred` property that the iOS RPC bridge's `didResolveDeepLink` does not forward). `isDeferred` always returns `null` for iOS deep links regardless of the actual deferred/direct outcome. Android reliably sets `is_deferred` on every resolved deep link. Fixing this requires a native iOS RPC change (forwarding `deepLink.isDeferred` alongside `clickEvent`) — out of scope for the Flutter plugin.
- `unregisterDeeplinkListener()` is an Android-only soft unsubscribe: the native SDK keeps its listener (it exposes no public unsubscribe API) and the RPC bridge drops subsequent deep-link events.
- Both platforms buffer native events until Dart attaches to `af-events` (RD-65582) and replay them on attach. Android buffers in the process-scoped `AppsFlyerEventBus`, so a deep link resolved while the Flutter engine is torn down (back press, then a link tap) survives engine recreation; the buffer holds at most 64 events and drops the oldest beyond that. iOS buffers per plugin instance and removes its bridge handler on engine detach, so it has no equivalent cross-engine replay.

---

## Dependencies
```mermaid
flowchart LR
    F037["F-037 · Unified Deep Linking (UDL) Callback & Models"]:::deepLinking -->|"listener registered after"| F001["F-001 · SDK Initialization"]:::sdkCore
    F037 -->|"iOS input arrives through"| F039["F-039 · Native iOS Deep-Link Entry Points"]:::deepLinking
    F037 -->|"Android warm-intent state is synchronized by"| F040["F-040 · Android New-Intent Deep-Link Forwarding"]:::deepLinking
    classDef deepLinking fill:#E64980,color:#fff
    classDef sdkCore fill:#4C6EF5,color:#fff
```
