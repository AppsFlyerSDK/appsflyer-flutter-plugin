# AppsFlyer Flutter Plugin — Architecture (Flutter ↔ RPC ↔ Native SDK)

**Status:** Current implementation  
**Last verified:** 2026-08-10  
**Flutter plugin:** 7.0.1  
**Android SDK / RPC:** 7.0.1  
**iOS SDK:** 7.0.1  
**iOS RPC:** 7.0.12

This document describes the current implementation of the `appsflyer_sdk` Flutter plugin. Its scope is the cross-platform wrapper, its Flutter channels, the Android and iOS RPC integrations, and the optional Purchase Connector. The native SDKs remain separately versioned systems; this repository adapts their supported RPC capabilities rather than reimplementing attribution, persistence, or networking.

Historical SDK 6 behavior and upgrade instructions belong in [`doc/migration-guide.md`](../doc/migration-guide.md), not in the current architecture contract. Method signatures and platform availability belong in [`doc/api-reference.md`](../doc/api-reference.md); this document explains boundaries and flows rather than duplicating that reference.

## 1. Architectural principles

The Flutter plugin is a thin, typed bridge over the native Android and iOS RPC modules.

- `AppsFlyerSdk.instance` is the public singleton entry point.
- Dart owns public naming, type safety, per-platform payload adaptation, event models, and error normalization.
- Native SDK validation, persistence, lifecycle state, threading, and network behavior remain native responsibilities.
- Every core Dart-to-native call uses one RPC transport method: `executeRpc` on `af-api`.
- Native asynchronous SDK events use `af-events` and are demultiplexed into one application callback per event, registered through the `register*Listener` APIs. The plugin exposes no public `Stream`.
- Per-call results remain correlated to the originating `MethodChannel` reply; they are not delivered through global callback slots.
- Intentional Android/iOS RPC differences are adapted explicitly instead of being hidden by duplicated business logic.

Dependencies point inward toward the native capability:

```text
host Flutter app
  → public Dart API and Dart models
    → Flutter channel transport
      → platform plugin adapter
        → native RPC parser/router
          → native AppsFlyer SDK
```

The callback direction is reversed, but ownership is not: the native SDK emits a callback, the RPC layer creates an event envelope, the platform plugin transports it, and Dart invokes the typed callback registered for that event. Neither native platform imports Dart business logic. The optional Purchase Connector follows a separate channel and does not pass through the core RPC router.

```mermaid
flowchart LR
    App["Flutter application"] --> SDK["AppsFlyerSdk public API"]
    SDK -->|"executeRpc {method, params}"| Method["af-api MethodChannel"]
    Method --> Android["Android plugin → AppsFlyerRpcHandler"]
    Method --> IOS["iOS plugin → AppsFlyerRPCBridge"]
    Android --> AndroidSDK["AppsFlyer Android SDK 7"]
    IOS --> IOSSDK["AppsFlyer iOS SDK 7"]
    AndroidSDK -->|"callback → RPC notifier → plugin"| Events["af-events EventChannel"]
    IOSSDK -->|"delegate → RPC emitter → plugin"| Events
    Events --> Registry["private listener registry (one callback per event)"]
    Registry --> App
```

## 2. Public Dart layer

`lib/src/appsflyer_sdk.dart` contains the public SDK surface.

### 2.1 Singleton and platform selection

`AppsFlyerSdk.instance` owns the production `MethodChannel` and `EventChannel`. The `@visibleForTesting` named constructor accepts injected channels and an optional `TargetPlatform`, allowing platform-specific behavior to be tested without changing global Flutter platform state.

The stored platform is used only for bridge concerns:

- selecting Android or iOS RPC method names;
- selecting platform-specific parameter shapes;
- short-circuiting APIs unsupported by the current native RPC layer;
- serializing platform-specific models such as purchase details and mediation values.

A platform-only API is not gated in Dart. Every call routes through `_invokeRpc` regardless of the current platform, and the native RPC layer answers `unknown method` when it does not implement it; that surfaces to the caller as `AppsFlyerException`. Keeping a platform-support table in Dart was rejected deliberately — it duplicates knowledge the RPC contract already owns and goes stale the moment a native SDK adds support, silently blocking a method that now works. The trade-off is that the exception `code` comes from the native layer and is not yet aligned: Android reports `422` (`INVALID_PARAMETERS`, because its parser maps unknown methods through the generic parse-error path) and iOS reports `404`. Aligning Android on `404` is a native RPC change, not a plugin one. Shared APIs behave the same way, except that the package registers native implementations only for Android and iOS, so invoking one on another Flutter target produces `MissingPluginException` rather than `AppsFlyerException`.

### 2.2 RPC helpers

All public RPC-backed methods delegate to two helpers:

```dart
Future<T> _invokeNullableRpc<T>(String method, [Map<String, dynamic>? params]);
Future<T> _invokeRpc<T extends Object>(String method, [Map<String, dynamic>? params]);
Future<void> _invokeVoidRpc(String method, [Map<String, dynamic>? params]);
```

`_invokeNullableRpc` is the unconstrained primitive for RPC calls whose native
reply may legitimately be absent (`String?`, `Map?`, or `void`). `_invokeRpc`
requires a non-null reply and throws `AppsFlyerException` when the native side
returns nothing, so callers such as `isSessionReady`, `isStopped`,
`getSdkVersion`, and `generateInviteLink` do not need ad-hoc `?? false`, `!`,
or per-method null checks. `_invokeVoidRpc` delegates to
`_invokeNullableRpc<Object?>`.

`_invokeRpc` sends this channel payload:

```json
{
  "method": "<rpc method>",
  "params": {}
}
```

The Flutter channel method is always `executeRpc`. A native `PlatformException` is converted into public `AppsFlyerException` before reaching plugin consumers. If the native reply decodes to a non-null value whose runtime type does not match the Dart call's expected type argument, `_invokeNullableRpc` throws `AppsFlyerException` instead of surfacing a raw cast error. When `_invokeRpc` receives a null reply it throws `AppsFlyerException` with message `<method> returned no value`. `AppsFlyerException.code` is populated only when `PlatformException.code` is numeric. Android RPC failures normally use HTTP-style numeric codes (`400`, `404`, `422`, `500`, `503`). iOS protocol errors also preserve numeric RPC codes, but an iOS handler failure without an `errorCode` is exposed with the non-numeric fallback `SDK_ERROR`. Plugin transport failures such as `UNEXPECTED_ERROR`, `SERIALIZATION_ERROR`, and `RPC_PARSE_ERROR` are also non-numeric. All of those cases therefore produce `AppsFlyerException(code: null, ...)` while retaining the message.

`MissingPluginException` — when no native handler answers the channel — is **not** part of the RPC error contract and is **not** converted to `AppsFlyerException`. It indicates a Flutter integration gap (unsupported platform, or plugin registration failure) and should not occur on a properly integrated Android or iOS build.

`_invokeVoidRpc` discards successful native response data and exposes `Future<void>`. For native fire-and-forget setters, completion means that the RPC layer accepted the call; it does not invent a native network-completion callback. Dart does not add its own timeout or cancellation layer.

### 2.3 Public result delivery

Public APIs use the delivery style supported by the underlying capability:

| Public behavior | Examples | Transport behavior |
| --- | --- | --- |
| Awaitable request result | `start`, `logEvent`, `validateAndLogInAppPurchase`, `generateInviteLink` | Completes or fails through the originating `MethodChannel` reply |
| Awaitable RPC acceptance | setters, `logAdRevenue`, `logInvite` | Completes after the native RPC accepts the operation |
| Immediate Dart getter | `pluginVersion` | Reads local package metadata; no RPC |
| Registered callback | conversion data, UDL, session readiness | Delivered through `af-events` and dispatched to the single callback passed to the matching `register*Listener` |

`start`, `logEvent`, `generateInviteLink`, and `validateAndLogInAppPurchase` expose a public `awaitResponse` parameter. It defaults to `false` for `start` and `logEvent`, and to `true` for the two result-producing APIs. The flag is forwarded to both platforms for `start` and `logEvent`, but only Android exposes it for invite generation and purchase validation.

## 3. Flutter platform channels

The channel names are identical across Dart, Android, and iOS:

| Purpose | Channel | Dart | Android | iOS |
| --- | --- | --- | --- | --- |
| Requests and per-call replies | `af-api` | `MethodChannel` | `MethodChannel` | `FlutterMethodChannel` |
| Native SDK events | `af-events` | `EventChannel` | `EventChannel` | `FlutterEventChannel` |
| Optional Purchase Connector | `af-purchase-connector` | `MethodChannel` | included build variant | CocoaPods subspec |

The core `MethodChannel` remains necessary: an `EventChannel` can deliver native events but cannot provide correlated request/reply calls for initialization, setters, getters, `start`, event logging, purchase validation, or invite-link generation.

The channel names, `executeRpc` entry point, RPC method strings, parameter keys, JSON envelopes, and native event names are **internal transport contracts**. They are not a second public Flutter API and applications must not call them directly. `AppsFlyerSdk`, its exported models, and its documented callback typedefs are the public compatibility boundary. A transport contract can differ by platform while the public Dart method remains stable; the Dart layer owns that mapping.

## 4. Forward path: Dart → RPC → native SDK

### 4.1 Generic request

```text
Flutter public method
  → _invokeRpc / _invokeVoidRpc
  → af-api: executeRpc {method, params}
  → platform plugin dispatch
  → native RPC parser and handler
  → native SDK 7 API
  → native RPC response
  → MethodChannel result
  → Dart value or AppsFlyerException
```

### 4.2 Android transport

`AppsflyerSdkPlugin.kt` forwards every method except plugin-orchestrated `init` to `AppsFlyerRpcHandler`.

- Fast RPCs (setters, getters, and fire-and-forget `start` / `logEvent` / purchase validation / invite generation when `awaitResponse` is `false`) run inline on the platform thread and complete the Flutter `Result` immediately.
- `init` and awaited-callback RPCs (`start`, `logEvent`, `validateAndLogInAppPurchase`, or `generateInviteLink` when `awaitResponse` is `true`) run on a dedicated single-thread `blockingRpcExecutor` so cold-start bootstrap and slow native latch waits do not block the platform thread.
- The handler uses `JsonRpcRequestParser` and the typed Android RPC request catalog.
- SDK callbacks required for awaitable RPC operations are converted into the corresponding RPC response.
- Flutter results are delivered on the main thread.
- The RPC handler is process-scoped. `AppsFlyerRpcBridge` holds one handler behind an `AppsFlyerRpcExecutor`, built with `applicationContext` so it retains neither a destroyed `Activity` nor a torn-down engine. Because `AppsFlyerLib` is itself a process-wide singleton that keeps its configuration and registered listeners, reusing the handler means a recreated engine reattaches to a bridge that still matches the native SDK instead of building one with no memory of the listeners registered on it. The `init` RPC alone uses an ephemeral handler built around the current `Activity` when one is attached (scheduled on `blockingRpcExecutor`, not inline on the platform thread), so SDK 7 can replay the cold-start launch intent for deep linking without blocking cold start.
- Awaited native callbacks and the `init` sequence block only the dedicated blocking executor until completion or timeout. Fast calls are not queued behind them.
- The process-scoped `AppsFlyerRpcHandler` can be entered from both the platform thread (fast RPCs) and `blockingRpcExecutor` (`init` and awaited RPCs). That overlap is intentional: fast setters/getters must not wait behind a slow `await start()`. Listener bookkeeping inside the handler is not synchronized; if tighter guarantees are needed, they belong in the Android RPC module (`plugin_bridge`), not by serializing every plugin RPC on one executor.
- The `executeRpc` envelope `{method, params}` is parsed by `RpcEnvelopeParser` before dispatch. Both `method` and `params` are required; `params` may be empty but must be a `Map`. Dart's `_invokeNullableRpc` always supplies `params: params ?? {}`. A malformed envelope from anything other than that path is an integration error: Android throws `IllegalStateException` with message prefix `RPC envelope contract violation:` outside the dispatch `try/catch`; iOS calls `preconditionFailure` with the same prefix. Neither path is converted to a user-facing `AppsFlyerException` by design.

### 4.3 iOS transport

`AppsflyerSdkPlugin.swift` serializes `{method, params}` and calls `AppsFlyerRPCBridge.executeJson`.

- `AppsFlyerRPCBridge` is `@MainActor`-isolated. It starts an async task per request; unlike Android, the plugin has no single FIFO executor for unrelated calls. Callers must `await` operations whose ordering matters.
- The plugin's Flutter-facing methods are non-isolated, so it reaches the bridge through `AFRPCBridge` (`AFRPCBridge.swift`), a Swift-only accessor that is the single point of contact in both directions. Outbound call sites — Flutter channel handlers plus `UIApplication`/`UIScene` delegate callbacks — already run on the main thread, so it uses `MainActor.assumeIsolated` to keep each call synchronous while asserting that assumption at runtime; engine detach, the one caller that may run off the main thread, hops through the main queue instead. Inbound events are always enqueued with `DispatchQueue.main.async` (even when already on the main thread) so af-events delivery order matches Android's always-post model; outbound RPC completions are normalized through `onMainActor` so mutations such as `markBridgeReady` do not depend on `AppsFlyerRPCBridge` keeping its own main-actor hop across version bumps. There is no Objective-C in the Core plugin.
- The `executeRpc` envelope `{method, params}` is parsed by `parseEnvelope` before dispatch, matching Android's `RpcEnvelopeParser` contract. Both keys are required; `params` may be empty but must be a `Map`. Dart's `_invokeNullableRpc` always supplies `params: params ?? {}`. A malformed envelope from anything other than that path is an integration error: iOS calls `preconditionFailure` with message prefix `RPC envelope contract violation:`; Android throws `IllegalStateException` with the same prefix. Neither path is converted to a user-facing `AppsFlyerException` by design. Dispatch-time serialization still validates every RPC payload with `JSONSerialization.isValidJSONObject` in `jsonString(from:)` before writing, which rejects the non-finite doubles that would otherwise raise `NSInvalidArgumentException`; such calls fail with a `SERIALIZATION_ERROR` `FlutterError`. `example/ios/RunnerTests` pins that serialization behavior.
- Native completion-handler APIs are invoked on the main queue and bridged into Swift concurrency. RPC state used to gate listeners is held in an actor.
- JSON protocol errors and SDK failures become `FlutterError` values.
- iOS-specific nested result envelopes are unwrapped into the primitive or map shape expected by Dart. Scalar getters with named-key nesting (`getSdkVersion`, `getAppsFlyerUID`, `isSessionReady`, `generateInviteLink`) have explicit cases until the RPC module aligns with Android's flat shape; everything else returns the `data` map when present (void setters correctly get `nil`).
- `logAndOpenStore` is the only non-init public call requiring plugin orchestration because the plugin opens the returned store URL.

### 4.4 iOS Swift Package Manager (Core)

Core iOS code is shared between CocoaPods (`ios/appsflyer_sdk.podspec`) and SPM (`ios/appsflyer_sdk/Package.swift`). The SPM manifest includes Flutter's required path dependency on `../FlutterFramework`. That package is **not** checked into the plugin repo — Flutter tooling generates it in the consuming app's ephemeral build output during `flutter pub get` / `flutter build`. Standalone `swift package resolve` against the plugin checkout is therefore expected to fail; the supported integration test is `flutter build ios` with Swift Package Manager enabled in the app. See F-060 for Purchase Connector exclusions and verification details.

## 5. Reverse path: native SDK → RPC → Dart callbacks

The native RPC event notifier emits JSON event envelopes. Both platform plugins forward those envelopes through `af-events` without maintaining Dart callback slots.

Events emitted before Dart attaches an `EventChannel` listener are buffered by the platform plugin and replayed when `onListen` runs. On Android that buffer lives in the process-scoped `AppsFlyerEventBus` rather than on the plugin instance, so it also spans engine teardown: the native SDK keeps the listeners registered through the process-scoped `AppsFlyerRpcHandler`, and routing every event through the bus means those late events reach the next subscriber instead of an unreachable plugin. iOS instead removes its bridge event handler in `detachFromEngineForRegistrar:` — only when the detaching instance still owns the bridge's single handler slot — so it has no equivalent late-delivery path and keeps its engine-scoped buffer.

Dart holds exactly one `af-events` subscription, owned by `AppsFlyerSdk` itself. It is established lazily on the first `register*Listener` call — not in the constructor — so nothing is read from the native buffers before the application has asked for events. That first attach flushes the entire native buffer, including events for listeners the application registers later in the sequence, so `_AppsFlyerListenerRegistry` holds those until their callback arrives rather than dropping them. The handler catches malformed transport values, logs them with `debugPrint`, and drops them instead of failing the subscription:

```dart
void _ensureEventsSubscribed() {
  _eventSubscription ??=
      _eventChannel.receiveBroadcastStream().listen(_handleNativeEvent);
}
```

`_AppsFlyerEvent.fromNative` accepts the RPC JSON string and normalizes:

- `event` → `_AppsFlyerEvent.name` (must be a non-empty string; missing, empty, or non-string values throw `FormatException`);
- `data` → `Map<String, dynamic>` when `data` is a JSON object, otherwise `{}` (covers Android `onSessionReady` with `data: null`).

Transport-only envelope fields (`timestamp`, `origin`) are ignored on the Dart side.

The Android and iOS plugins each keep an in-memory FIFO of event JSON strings while no Dart event sink is attached, then flush it from `onListen`. Both queues are capped at 64 events and drop the oldest on overflow; both platforms log a warning when that cap evicts events so the failure mode is visible in production logs. Android's `AppsFlyerEventBus` is process-scoped, iOS's `pendingEvents` is engine-scoped. On Android, the bus synchronizes buffer and sink state but does not hop threads: `drain()` calls the sink on the caller's thread, so `AppsflyerSdkPlugin` posts `publish()` onto the main looper and runs `attach`/`detach` from the platform thread. On Android, `AppsFlyerEventBus.drain()` can also handle a `DROP` outcome from an `AppsFlyerEventSink` implementation (covered by unit tests), but the production `createEventSink` adapter returns only `DELIVERED` or `RETRY_LATER`. Nothing is persisted, so events that occur before plugin registration, after engine teardown, or before the native RPC event handler exists are not recoverable.

On Android, the no-loss-across-engine-teardown guarantee (RD-65582) comes from explicit lifecycle teardown — `onCancel` / `onDetachedFromEngine` call `releaseEventSink()`, which detaches the bus sink so later publishes buffer until the next `onListen`. It does **not** rely on `EventChannel.EventSink.success()` throwing when the embedding is torn down: on supported Flutter embeddings (3.24+), a detached `BinaryMessenger` / `FlutterJNI` usually logs and returns silently rather than throwing. While `onDetachedFromEngine` is running, `createEventSink` therefore returns `RETRY_LATER` as soon as `isEngineDetached` is set — before calling `success()` — so the bus keeps the head event buffered instead of popping it on a false delivery. If `success()` does throw a `RuntimeException`, it is logged at error and returns `RETRY_LATER` so the head event is kept without crashing the platform thread. `Error` types still propagate. A narrow race may still exist if JNI detaches before `isEngineDetached` is set; hardening that boundary would need further embedding-level detection.

`_AppsFlyerListenerRegistry` (`lib/src/appsflyer_listener_registry.dart`) maps each native event name to the single callback registered for it, replacing that callback on re-registration — the same contract as the native SDKs, which hold one listener reference per event type.

An event that arrives before its listener has ever been registered is held in a FIFO capped at 64 — the same bound as each native buffer, since the held events are that buffer's replay — and delivered in a microtask when the listener registers. Holding covers the startup window only. Once a listener has been registered, an event arriving while no callback is installed (because the application unregistered) is logged and dropped rather than replayed on re-registration; `off` also discards anything still held for that event name.

| Registration API | Callback | Native event names |
| --- | --- | --- |
| `registerConversionListener` | `onSuccess` | `onConversionDataSuccess` |
| `registerConversionListener` | `onFailure` | `onConversionDataFail` |
| `registerDeepLinkListener` | `onDeepLink` | `onDeepLinking` or `onDeepLinkReceived` |
| `registerSessionReadyListener` | `onReady` | `onSessionReady` |

Because the callback is an argument to the registration call, it is always in place before the RPC is dispatched, and no public `Stream` exists for an application to attach additional subscribers to. A single native event therefore cannot fan out to several handlers — `start()` cannot be issued twice for one session-ready event.

## 6. Initialization and session lifecycle

### 6.1 Initialization

The public API is:

```dart
Future<void> init({required String devKey, String? appId});
```

- Android receives only `devKey`; `appId` is not sent.
- iOS requires a non-empty `appId` and receives both fields. The native RPC layer validates both values.
- Initialization does not register optional conversion, UDL, or session-ready listeners.
- Initialization does not send a Launch.

Android initialization sequence:

```text
setPluginInfo(plugin: flutter, pluginVersion)   // on blockingRpcExecutor
  → init(devKey)                                // Activity-scoped handler when attached
  → complete the originating Flutter result on the main thread
```

Plugin metadata is attempted before initialization on both platforms so it can label the first session. Its result is intentionally non-fatal and does not abort `init`.

iOS initialization sequence:

```text
register RPC event handler
  → setPluginInfo(plugin: flutter, pluginVersion)
  → initialize(devKey, appId)
  → handle pending launch options when present
  → mark AppsFlyerAttribution bridge ready
  → replay queued iOS URL / Universal Link requests
```

### 6.2 Listener registration

Native listeners are registered explicitly, each with its own ordering relative to `init()`:

| Flutter API | Android RPC | iOS RPC | Order |
| --- | --- | --- | --- |
| `registerDeepLinkListener(onDeepLink)` | `subscribeForDeepLink` | `registerDeeplinkListener` | Before `init()` |
| `registerConversionListener(onSuccess:, onFailure:)` | `registerConversionListener` | `registerConversionListener` | After `init()` |
| `registerSessionReadyListener(onReady)` | `registerSessionReadyListener` | `registerSessionReadyListener` | After `init()`, last |

The deep-link listener is the exception because Android's deferred-resolution gate runs inside `init()`: the plugin passes the `Activity` as the init context (§7.1), which makes the native SDK replay the launch intent immediately, and `AFDeepLinkManager` sends the deferred resolution request only if a listener is already attached — a one-shot decision persisted per install. See F-037.

Android additionally exposes `unregisterConversionListener` and the RPC soft-unsubscribe mapped by `unregisterDeeplinkListener`. Session-ready unregister is supported on both platforms.

Registration is native state with an explicit contract: the application decides when delivery stops and resumes, and the plugin never infers that a listener has gone stale. Applications call the matching `unregister*Listener()` at the point in their own lifecycle where they no longer consume the events, and register again afterwards. Where that call reaches the native SDK it also clears the Dart callback slot; the iOS no-ops (`unregisterConversionListener`, `unregisterDeeplinkListener`) leave the callback in place, matching their native behavior. Because Android's RPC handler is process-scoped (§4.2), a registration — and an `unregisterDeeplinkListener` soft unsubscribe — outlives the engine that requested it, while the Dart callbacks do not; a recreated engine therefore repeats the registration sequence of a cold start. See [`doc/getting-started.md`](../doc/getting-started.md) for the integrator-facing version of this contract.

### 6.3 Session start

The app registers the native listener after initialization and calls `start()` for every foreground-cycle signal delivered to its callback.

```dart
final appsFlyer = AppsFlyerSdk.instance;

await appsFlyer.init(devKey: devKey, appId: appId);
await appsFlyer.registerSessionReadyListener(() async {
  await appsFlyer.start();
});
```

`start({awaitResponse})` and `logEvent(..., {awaitResponse})` forward the public flag (default `false`) to both native RPC layers. `true` completes the `Future<void>` on native request success and `false` completes after RPC acceptance. `generateInviteLink(..., awaitResponse: ...)` and `validateAndLogInAppPurchase(..., awaitResponse: ...)` default to `true` and forward the flag to Android RPC. Android returns a synchronous long link for `generateInviteLink(awaitResponse: false)` and an empty validation-result map for `validateAndLogInAppPurchase(awaitResponse: false)`. The current iOS RPC 7.0.12 does not expose the flag for those two APIs and always awaits their callbacks.

Listener registration can cause readiness or attribution work promptly, so application code must apply consent/identity settings that must affect the first Launch before registering the session-ready listener. The wrapper does not maintain an initialized/started state machine or reject out-of-order calls; it relies on the application to await required sequencing and on native RPC/SDK validation for unsupported states. Most configuration is native runtime state and must be re-applied after a cold process start.

### 6.4 Callback timeouts

Timeouts belong to the native RPC layers, not Dart. They bound how long a Flutter request waits; they do not cancel native work, so a late native operation may still complete after Dart has received an error.

| Awaited operation | Android RPC 7.0.1 | iOS RPC 7.0.12 |
| --- | ---: | ---: |
| `start` | 5 s | 10 s |
| `logEvent` | 5 s | 10 s |
| `validateAndLogInAppPurchase` | 5 s | 30 s |
| `generateInviteLink` | 10 s | 10 s |
| `logAndOpenStore` | no awaited SDK callback in Android RPC | 10 s before the plugin opens the URL |

These are distinct from `setDeepLinkTimeout`, which configures native deep-link resolution (default 3,000 ms on Android and 60,000 ms on iOS). Android requires a positive value; iOS accepts zero.

## 7. Deep-link lifecycle forwarding

### 7.1 Android

The plugin is `ActivityAware` and registers a `NewIntentListener`.

- On a warm-start intent, it calls `activity.setIntent(intent)` and returns `false`; it does not invoke `performDeepLinking` itself or claim exclusive handling.
- The SDK 7 lifecycle integration inspects the activity's current intent on resume after `subscribeForDeepLink`, so keeping that intent current enables native UDL resolution.
- There is no plugin-owned Android URL queue. If no activity is attached when the new intent arrives, the plugin does not retain it.
- The `init` RPC uses the active `Activity` when one is attached so the Android SDK can inspect cold-start lifecycle state; application context is the fallback. Every other RPC runs on the process-scoped executor, which always uses application context.

### 7.2 iOS

The plugin registers AppDelegate and, when available, UIScene lifecycle delegates.

- URL-scheme links map to `handleOpenUrl` or `handleOpenURL` according to the native callback shape.
- Universal Links map to `continueUserActivity`.
- launch options are retained until the RPC bridge is initialized;
- `AppsFlyerAttribution` queues early URL/Universal Link requests and replays them after plugin-internal `markBridgeReady(markedBy:)`. Queue state is serialized on the main queue inside the singleton (interim until the RPC lifecycle-callback wrapper absorbs it). Serialization and RPC failures are logged via `os_log`; the host app still learns deep-link outcomes only through `af-events` (F-037). That call records the owning plugin instance so `resetBridgeStateIfOwned(by:)` on engine detach clears `isBridgeReady` / `pendingRequests` without affecting a live second engine. A parameterless `@objc markBridgeReady` is intentionally not exposed: it would open the gate without an owner and break detach cleanup.

These lifecycle RPC calls are implementation details and are not public Dart methods.

## 8. Platform-specific API adaptation

The public layer normalizes only where a reliable mapping exists.

Examples:

- `registerDeepLinkListener` selects the different Android and iOS RPC method names.
- `init` omits `appId` on Android. iOS receives both fields; validation is native-side.
- `AFMediationNetwork` maps to the native platform's accepted identifier.
- `AppsFlyerInviteLinkParams.referrerCustomerId` maps to Android `customerId` and iOS `referrerCustomerId`.
- `AFPurchaseDetails` has dedicated Android and iOS implementations because the native RPC request shapes differ.
- `sendPushNotificationData` is Android-only, while `handlePushNotification` is iOS-only.

Where the native RPC layer has no equivalent, the Flutter API either logs and ignores the call or does not expose the capability at all. Dart does not simulate missing native behavior.

Important differences that affect design and testing:

| Concern | Android | iOS |
| --- | --- | --- |
| Core request scheduling | Fast RPCs inline on the platform thread; `init` and awaited-callback RPCs on one blocking executor | Independent async tasks through a `@MainActor` bridge |
| Native request catalog | Kotlin sealed requests parsed by `JsonRpcRequestParser` | Swift typed requests parsed by `AFRPCParser` and routed by domain |
| Result shape | Bare `RpcResponse.Success` value or void | JSON response envelope with plugin-side unwrapping |
| UDL subscribe/unsubscribe | `subscribeForDeepLink`; soft unsubscribe drops future callbacks because the SDK has no native unsubscribe | `registerDeeplinkListener`; no public unregister mapping |
| Warm link entry | Current `Activity` intent consumed by SDK lifecycle | AppDelegate/UIScene callbacks explicitly forwarded through RPC |
| iOS app ID | Not used | Required by Dart `init` |
| Purchase Connector opt-in | Gradle source-set flag | CocoaPods subspec; unavailable through SPM |

## 9. Purchase validation and Purchase Connector

### 9.1 RPC purchase validation

`validateAndLogInAppPurchase` is part of the core RPC bridge and accepts the `AFPurchaseDetails` interface.

- `AFAndroidPurchaseDetails` sends `purchaseType`, `productId`, `purchaseToken`, and `additionalParameters`.
- `AFIOSPurchaseDetails` sends the nested `product` and `transaction` objects expected by the iOS RPC.
- `AppsFlyerSdk.validateAndLogInAppPurchase` appends the public `awaitResponse` value only to the Android payload; the iOS RPC does not expose that field.
- Supplying a model for the wrong current platform throws `ArgumentError` before crossing the channel.

### 9.2 Purchase Connector

Purchase Connector is a separate optional native subsystem using `af-purchase-connector` rather than the core RPC channel.

- Android is enabled through `appsflyer.enable_purchase_connector=true`.
- iOS is enabled through the CocoaPods Purchase Connector subspec.
- iOS Purchase Connector is not available through the plugin's Swift Package Manager integration.
- Dart keeps a separate process singleton. The first factory call requires configuration and sends an unawaited `configure` channel call; later configuration objects are ignored with a log.
- `startObservingTransactions()` and `stopObservingTransactions()` send unawaited calls because their public signatures return `void`. Consequently, native `PlatformException` failures from these calls are not normalized by the core `AppsFlyerException` path.
- Native validation callbacks travel back over the same Purchase Connector `MethodChannel`, not `af-events`. Dart stores callback functions: separate Android subscription/in-app success/failure listeners and one combined iOS validation callback.
- Android marshals connector callbacks to the main looper and serializes maps as JSON strings. iOS dispatches its delegate callback to the main queue and also sends JSON text; Dart accepts either a JSON string or a decoded map.
- On Android, `AppsFlyerPurchaseConnector` keys its `MethodChannel`, `ConnectorWrapper`, and validation listeners per `FlutterPluginBinding`, so add-to-app / multi-engine setups do not share one channel or tear down another engine's connector on detach.
- On iOS, `PurchaseConnectorPlugin` remains a process singleton holding one channel, so the last engine to register owns it. It publishes no instance of its own and therefore receives no detach callback directly: `AppsflyerSdkPlugin.detachFromEngineForRegistrar:` calls `tearDownForEngineDetach(registrar:)`, which stops transaction observation, clears the revenue delegate and the channel, and lets the next engine call `configure` again. The teardown is skipped unless the detaching registrar still owns the channel, so a stale engine cannot stop observation for a live one.

## 10. Error handling and state boundaries

- Core RPC `PlatformException` values are converted to `AppsFlyerException`. `MissingPluginException` is left unwrapped — it is outside the RPC contract.
- Platform-only calls are not short-circuited in Dart; they reach the RPC and surface the native `AppsFlyerException` off-platform. Shared calls are not guaranteed to work outside Android/iOS.
- Dart throws `ArgumentError` before transport for purchase details on the wrong platform. Most other input validation, including `init` parameters and `setConsentData` GDPR fields, remains in the typed native RPC request and SDK.
- Android converts parser/validation failures to numeric `RpcResponse.Error` values. Unexpected plugin orchestration failures use plugin error strings such as `UNEXPECTED_ERROR` or `INIT_ERROR`.
- iOS distinguishes protocol errors in the response `error` envelope from handler failures represented by `result.success == false`; the iOS plugin adapter converts both to `FlutterError` and unwraps successful values.
- A malformed native event is logged and dropped by Dart. It never reaches an application callback and does not fail the `af-events` subscription. Conversion-data failure and UDL failure are normal event payloads, not failed MethodChannel requests.
- Android splits teardown by lifetime. The Dart-facing half is engine-scoped: `onDetachedFromEngine` sets `isEngineDetached` first, then clears the channel handlers, detaches this engine's `af-events` sink via `releaseEventSink()` (which also runs from `onCancel`), and shuts down the blocking-RPC executor. Setting `isEngineDetached` before `releaseEventSink()` lets any in-flight `af-events` delivery return `RETRY_LATER` instead of calling `EventChannel.success()` on a detached embedding. That detach is what keeps the process-scoped `AppsFlyerEventBus` buffering events for the next engine; it is not inferred from `EventChannel.EventSink.success()` throwing. Clearing the method-call handler is what stops new calls — teardown and `onMethodCall` both run on the platform thread, so a post-detach `executeRpc` entry is rare; if one still reaches the plugin, it completes with `PLUGIN_DETACHED` directly while async completions still drop in `deliverRpcResult`. Only awaited RPCs outlive teardown, because `shutdown()` lets the in-flight task run to completion: its latch can resolve seconds later, and `deliverRpcResult` then drops the `Flutter Result` rather than replying on a dead channel. Replying would not crash — Flutter discards the response with a `FlutterJNI was detached` warning — but that warning is misleading in customer bug reports. The native-facing half is process-scoped and deliberately survives: `AppsFlyerEventBus` keeps its buffer and `AppsFlyerRpcBridge` keeps the RPC handler, so a recreated engine reattaches to the configured bridge. Dart state does not survive either way — the application calls the `register*Listener` APIs again after a new engine attaches, and reusing the handler only makes that re-registration reuse the existing listeners instead of building new ones.
- iOS registers its RPC event handler during plugin construction and tears it down in `detachFromEngineForRegistrar:` (after `publish:` in `registerWithRegistrar:`), clearing `eventSink`, `pendingEvents`, and the bridge event handler when the `FlutterEngine` is deallocated. `AppsFlyerRPCBridge` holds one handler per process while plugin instances are per engine, so `AFRPCBridge` records the registering instance as the slot's owner and removes the handler only for that owner — a detaching engine cannot silence events for an engine that registered after it and is still alive. This mirrors the `this.sink === sink` guard in `AppsFlyerEventBus.detach`; on both platforms the newest registration owns event delivery. `isEngineDetached` is set first in teardown so any in-flight `executeJson` completion (including the `init` sequence and `logAndOpenStore`) skips `FlutterResult` and `markBridgeReady(markedBy:)` instead of replying on a dead channel or flushing `AppsFlyerAttribution`'s process-scoped queue for a torn-down engine. A synchronous `executeRpc` that still reaches the plugin after detach completes with `PLUGIN_DETACHED` instead; `deliverFlutterResult` remains the drop path for async completions only. Teardown runs the whole block on the main queue, hopping when `detachFromEngineForRegistrar:` arrives off it: every other writer of the plugin's state (`onListen`, `onCancel`, `deliverEvent`, and the RPC completions reading `isEngineDetached`) is already main-thread confined, so the hop is what makes that confinement complete and lets the state stay lock-free. It captures the instance strongly, since both the bridge handler slot and `AppsFlyerAttribution`'s queue are keyed on its identity.
- Event callbacks belong to the Flutter application, but the transport subscription belongs to the plugin: Dart keeps one `af-events` listener and one callback slot per event, so the SDK installs no per-callback global state and the application cannot create a second delivery path.

## 11. Serialization and parameter contracts

Core calls cross two serialization boundaries:

```text
Dart values
  → Flutter StandardMessageCodec
    → Java Map / Objective-C NSDictionary
      → native JSON request string
        → typed RPC request
```

- Public parameter maps should contain JSON-compatible values only: string-keyed maps, lists, strings, booleans, finite numbers, and `null`. Platform channels can carry some additional Flutter codec types, but the following native JSON boundary cannot.
- Dart generally includes explicit `null` values in the `params` map. Android's plugin JSON conversion omits null-valued map entries, while iOS serializes them as JSON null; the typed request on each platform then decides whether the resulting value means “absent,” nullable, or invalid. Do not assume identical wire JSON even when the public Dart semantics are aligned. Clearing the iOS sharing filter is one case where an explicit Dart null is intentionally consumed on iOS.
- Android converts the Flutter map to `JSONObject` and its parser uses typed `opt*` helpers. Missing, omitted-null, or wrong-typed optional values can therefore collapse to parser defaults.
- iOS validates the Objective-C object with `NSJSONSerialization`, then `AFRPCParser` decodes `AnyCodable` into JSON scalar/list/map types and typed request initializers validate required values. The iOS parser rejects request JSON at or above 1 MiB.
- Enums are never sent by ordinal. Dart maps them to stable native strings, including platform-specific `AFMediationNetwork` values and different purchase-type spellings.
- Returned platform maps use dynamic Flutter codec key/value types. Dart converts result and event maps to `Map<String, dynamic>` at the public boundary. Core result type mismatches can surface as Dart cast/type errors; malformed event values are caught and dropped.
- Native callback events are JSON strings even though core MethodChannel requests begin as maps. Purchase Connector callbacks also currently send JSON strings, while its Dart handler tolerates an already-decoded map.

Treat `lib/src/appsflyer_sdk.dart` and the platform model serializers as the source of truth for public-to-RPC mapping. Treat Android `RpcRequest`/`JsonRpcRequestParser` and iOS `AFRPCTypedRequests`/`AFRPCParser` as the source of truth for accepted native transport shapes.

## 12. Privacy and security boundaries

The plugin exposes controls; the host application remains responsible for collecting consent lawfully and ordering calls so the first session reflects the user's choice.

- Apply consent, anonymization, identifier-collection, and stop/resume decisions before registering the session-ready listener when they must affect the first Launch. `setConsentData` is native runtime state: reapply it on each cold/process start, while background-to-foreground cycles in the same process retain it. TCF collection reads the platform consent stores through the native SDK when enabled.
- Advertising and device identifier collection is implemented by native SDK controls. The Dart bridge maps the setting but does not read, store, or redact identifiers itself. Platform-specific controls include Android ID/App Set ID/network data and iOS IDFV, ASA/Apple Ads, SKAdNetwork, and device name.
- Email, phone, first name, and last name cross the in-process Flutter channel and RPC boundary as raw strings. SHA-256 normalization/hashing happens inside the native SDK before those values are sent to AppsFlyer. The Facebook App-Scoped ID is explicitly not hashed. `clearUserPii` clears values set through all public `setUser*` PII methods, including that Facebook ID; it does not clear customer ID, consent, anonymization, or stopped state.
- Event values, additional data, partner data, push payloads, purchase details, deep links, and identifiers supplied by the app are passed to native code. The plugin is not a general-purpose sanitizer or secret store. iOS rejects dangerous schemes for `setFacebookDeferredAppLink`; that narrow validation does not apply to every URL-taking API.
- Platform channels and native RPC calls are in-process boundaries, not encrypted inter-process/network protocols. Network transport, native storage, identifier persistence, and server delivery belong to the native AppsFlyer SDKs.
- Debug logging is off unless enabled. Native debug logs can include request/event data useful for integration testing, so applications should not enable them in production or log channel payloads containing sensitive values. The wrapper's normal RPC diagnostics log method/failure information rather than intentionally logging PII values.

See [`doc/consent-dma.md`](../doc/consent-dma.md) for integration ordering and the public privacy controls.

## 13. Testing strategy

Different test levels protect different boundaries:

| Level | Location | Responsibility |
| --- | --- | --- |
| Dart channel/unit tests | `test/appsflyer_sdk_test.dart` | Public method-to-RPC names, parameter maps, platform-only forwarding, exception normalization, typed event routing, malformed-event behavior |
| Generated-model checks | `lib/appsflyer_sdk.g.dart` plus generator workflow | Purchase Connector JSON model conversion; regenerate after annotated model changes |
| Android RPC tests | native Android SDK/RPC repository | Typed request parsing/validation, handler-to-SDK mapping, callbacks, response/error behavior, timeouts |
| iOS RPC tests | native iOS SDK/RPC repository | Parser/router/domain handlers, state actor, event encoding, SDK timeout races, negative paths |
| Platform adapter tests | `android/src/test/kotlin/com/appsflyer/appsflyersdk/AppsFlyerEventBusTest.kt`, `AppsFlyerRpcBridgeTest.kt`; otherwise no comprehensive suite in this repository | Android event buffering, replay ordering, sink attach/detach across engine recreation, concurrent publishing, and single-executor RPC bridge reuse across engine recreation are covered by JVM unit tests (`./gradlew :appsflyer_sdk:testDebugUnitTest` from `example/android`, run by the Android CI job). Channel registration, engine detach, Android activity/new-intent behavior, iOS AppDelegate/UIScene forwarding, and result unwrapping still require focused native tests or example-app verification |
| Device/integration tests | `example/`, RC scenario scripts, real AppsFlyer dashboard/logs | Plugin registration, native dependency packaging, lifecycle sessions, deep links, attribution callbacks, push/uninstall paths, and network-visible behavior |

The PR gate is `.github/workflows/lint-test-build.yml`: analyze, format check and `flutter test --coverage` on Linux, then a per-platform release build, with `./gradlew :appsflyer_sdk:testDebugUnitTest` running ahead of the build on the Android job (preceded by `flutter build apk --config-only`, because the Gradle wrapper is gitignored and a fresh checkout has none until the Flutter tool invokes Gradle). The iOS `RunnerTests` suite is not wired into CI: it re-implements the function under test rather than importing the plugin, so it pins Foundation behavior and would cover no plugin code in exchange for a simulator boot on a runner that bills at 10x. None of that loads a real device: it cannot prove lifecycle, packaging or network-visible behavior, and SPM resolution is not covered at all because `Package.swift` depends on the app-generated `FlutterFramework` path. Run the example on a device or emulator for platform changes and follow [`doc/testing-and-troubleshooting.md`](../doc/testing-and-troubleshooting.md). Purchase Connector changes need opt-in builds; iOS Core should be checked through both CocoaPods and SPM where applicable.

## 14. Adding or changing capabilities

### 14.1 Public method or core RPC method

1. Confirm the capability exists in the pinned Android and/or iOS RPC catalog. If it does not, add and release the native RPC capability first; do not reproduce native SDK business logic in Dart.
2. Define the public Dart signature and platform availability in `lib/src/appsflyer_sdk.dart`. Add a small model only when it gives callers type safety or isolates a real platform-shape difference.
3. Map the public call to the exact native method name and parameter keys. Adapt the payload when the two contracts differ; do not silently send an iOS contract to Android or vice versa. Do not add a platform gate when only one side supports the method — forward it and let the RPC reject it.
4. Decide the completion contract: RPC acceptance, awaited native callback, returned value, or asynchronous event. Keep a request result on its originating MethodChannel reply; reserve `af-events` for unsolicited/repeating SDK events.
5. Update iOS result unwrapping when the public API expects data from an iOS nested response. Add plugin orchestration only for cross-layer duties such as initialization ordering or opening a returned URL.
6. Test Dart mappings for both platforms, including nulls/defaults, exceptions, and off-platform behavior. Add or update native RPC parser/handler tests in the owning native repository and run device coverage for lifecycle or packaging changes.
7. Update API, feature, migration, and architecture documentation affected by the change. Do not hand-edit generated `.g.dart` files.

### 14.2 Callback or event

1. Register the native SDK delegate/listener in the native RPC layer and define a stable event name plus JSON-compatible data shape.
2. Emit through the RPC notifier/event emitter and keep Flutter-channel access on the platform main thread.
3. Ensure the platform plugin registers the event handler early enough and decide whether its existing buffer is sufficient — Android's `AppsFlyerEventBus` is process-scoped, iOS's is engine-scoped, and both are capped at 64 events.
4. Decode and normalize the event in Dart, then dispatch it through `_AppsFlyerListenerRegistry` to a callback taken as an argument by the matching `register*Listener` API. Do not add a public `Stream`. Document platform payload differences.
5. Test listener gating, event name/payload mapping, malformed input, callback replacement on re-registration, and early-event replay. Add device coverage when the callback depends on application lifecycle.

### 14.3 Platform-only or Purchase Connector feature

Keep platform-only behavior visibly gated in Dart and documented as such. Purchase Connector features belong to its separate channel, models, native opt-in sources, and callback mechanism; they should not be added to `af-api` merely to make the channels look uniform.

## 15. Known constraints and trade-offs

- Android and iOS are the only registered Flutter targets. Platform-only calls throw `AppsFlyerException` off-platform; calls on other targets can throw `MissingPluginException`.
- Public/native compatibility is checked by tests and review, not generated from a shared cross-platform schema. Android and iOS RPC method names and parameter shapes can drift independently.
- Android runs fast RPCs inline on the platform thread. `init` and awaited-callback RPCs use a dedicated blocking executor, so cold-start bootstrap and a slow validation or invite-link wait do not stall unrelated setters/getters. iOS permits unrelated requests to overlap, so ordering must still be expressed by awaiting calls.
- Native timeout errors do not cancel SDK work. Fire-and-forget completion is acceptance, not network delivery.
- Event buffering is in memory and never persisted, so it does not survive process death. Both platforms cap the buffer at 64 events and drop the oldest on overflow; both log a warning when eviction happens. The buffer is process-scoped on Android and engine-scoped on iOS. Malformed events are dropped. On Android, `createEventSink` returns `DELIVERED` on success and `RETRY_LATER` while `isEngineDetached` is set or when `EventChannel.EventSink.success()` throws an unexpected `RuntimeException` (logged at error; `Error` types propagate). `AppsFlyerEventBus.drain()` also understands a `DROP` outcome for alternate sink implementations, but the production Flutter adapter does not emit it. Dart attaches its single `af-events` subscription on the first `register*Listener` call, and that attach flushes the whole native buffer at once: `_AppsFlyerListenerRegistry` holds any replayed event whose listener has not registered yet — capped at 64, the same bound as the native buffers — and delivers it when that listener registers. An event arriving after its listener has been registered and then unregistered is logged and dropped.
- Android deep-link correctness relies on an attached activity and SDK lifecycle inspection of its current intent; there is no plugin URL queue. iOS owns explicit AppDelegate/UIScene forwarding and queues early URL requests in `AppsFlyerAttribution` until initialization.
- Android deep-link unsubscribe is soft: it clears the RPC listener reference, but the native SDK has no unsubscribe API. iOS exposes no conversion/UDL unregister mapping in the current RPC.
- The plugin does not enforce a full lifecycle state machine. Call ordering, cold-start configuration replay, ATT prompting, and consent UI remain application responsibilities.
- iOS Purchase Connector requires CocoaPods and is absent from the SPM product. Its Dart `void` operations do not expose native completion errors through the core exception contract.
- The public dynamic map surfaces cannot provide compile-time guarantees for arbitrary event/additional-data keys or values. Keep payloads JSON-compatible and verify platform-specific mappings.

## 16. Key files

| Layer | File | Responsibility |
| --- | --- | --- |
| Public library | `lib/appsflyer_sdk.dart` | Library exports |
| Dart SDK | `lib/src/appsflyer_sdk.dart` | Public API, per-platform payload adaptation, RPC invocation, typed event callbacks |
| Event model | `lib/src/appsflyer_event.dart` | Native event decoding and normalization |
| Listener registry | `lib/src/appsflyer_listener_registry.dart` | Private one-callback-per-event dispatch for `af-events` |
| Errors | `lib/src/appsflyer_exception.dart` | Public SDK exceptions |
| Purchase models | `lib/src/af_purchase_details.dart` | Android/iOS purchase request implementations |
| Invite model | `lib/src/appsflyer_invite_link_params.dart` | Platform-aware invite parameter mapping |
| Android plugin | `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Channels, RPC dispatch, lifecycle forwarding, `af-events` sink adapter |
| Android event relay | `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsFlyerEventBus.kt` | Process-scoped event buffering, FIFO replay, synchronized buffer/sink state (`drain()` calls the sink on the caller's thread — main-thread delivery is enforced in `AppsflyerSdkPlugin`), `EventSendResult` delivery (`DELIVERED` / `RETRY_LATER` / `DROP` in `drain()`), and sink attach/detach across engine recreation; production `createEventSink` uses `DELIVERED` and `RETRY_LATER` only |
| Android RPC bridge owner | `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsFlyerRpcBridge.kt` | Process-scoped `AppsFlyerRpcHandler` behind `AppsFlyerRpcExecutor`, so engine recreation reattaches to the configured native bridge |
| Android dependencies | `android/build.gradle` | SDK/RPC BOM, optional connector source set, Android compatibility |
| iOS plugin | `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Channels, RPC dispatch, lifecycle forwarding, result unwrapping |
| iOS attribution adapter | `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerAttribution.swift` | Queues and forwards early URL/Universal Link RPC calls |
| iOS RPC bridge access | `ios/appsflyer_sdk/Sources/appsflyer_sdk/AFRPCBridge.swift` | Main-actor-checked access to the `@MainActor`-isolated `AppsFlyerRPCBridge` from the plugin's non-isolated contexts |
| iOS dependencies | `ios/appsflyer_sdk.podspec`, `ios/appsflyer_sdk/Package.swift` | CocoaPods subspecs; Core-only SPM manifest (AppsFlyerFramework + vendored AppsFlyerRPC binaryTarget + ephemeral Flutter-generated `FlutterFramework` path dependency — see §4.4, F-060) |
| Purchase Connector | `lib/src/purchase_connector/`, `android/src/main/include-connector/`, `ios/PurchaseConnector/` | Optional non-core channel, state, models, and native callbacks |
| Dart contract tests | `test/appsflyer_sdk_test.dart` | Public mapping, platform behavior, errors, and event decoding |

## 17. Sources of truth and related documentation

Source-of-truth ownership is split by boundary:

| Contract | Source of truth |
| --- | --- |
| Public Flutter API and public models | Current `lib/appsflyer_sdk.dart` library and `lib/src/` implementation |
| Dart-to-native mapping and public error/event normalization | `lib/src/appsflyer_sdk.dart`, platform serializers, and `lib/src/appsflyer_event.dart` |
| Channel registration, buffering, lifecycle forwarding, orchestration, and iOS result unwrapping | Android/iOS platform plugin source in this repository |
| Android RPC method names, accepted parameters, validation, callbacks, and timeouts | Pinned native Android `RpcRequest`, `JsonRpcRequestParser`, and `AppsFlyerRpcHandler` |
| iOS RPC method names, accepted parameters, validation, callbacks, and timeouts | Pinned native iOS `AFRPCParser`, typed requests, router, and domain handlers |
| Integration guidance | Public guides; secondary to code when they disagree |

Repository references:

- [`doc/README.md`](../doc/README.md) — integration-guide index
- [`doc/api-reference.md`](../doc/api-reference.md) — public API and platform availability
- [`doc/getting-started.md`](../doc/getting-started.md) — initialization and session-start integration
- [`doc/deep-linking.md`](../doc/deep-linking.md) — UDL and lifecycle setup
- [`doc/consent-dma.md`](../doc/consent-dma.md) — consent, identifiers, anonymization, and PII
- [`doc/purchase-connector.md`](../doc/purchase-connector.md) — optional connector setup and behavior
- [`doc/testing-and-troubleshooting.md`](../doc/testing-and-troubleshooting.md) — device verification and operational failures
- [`doc/migration-guide.md`](../doc/migration-guide.md) — SDK 6 to SDK 7 changes
- [`internal-docs/features/INDEX.md`](features/INDEX.md) and [`internal-docs/features/DIAGRAM.md`](features/DIAGRAM.md) — feature-level implementation records and dependency diagrams; observe their per-entry verification dates
- [`internal-docs/tech-designs/spm-support.md`](tech-designs/spm-support.md) — historical ADR-like design record; its superseded sections are explicitly marked, so use the current manifest and feature F-060 for current behavior

No dedicated ADR directory or checked-in machine-readable cross-platform RPC schema exists in this repository. Any external alignment matrix or schema can assist review, but it is not sufficient evidence unless it matches the pinned source revisions above.

Before declaring a release ready, verify the Dart API, both native RPC catalogs, platform mappings, event shapes, docs, and tests against the same revision.

## 18. Document maintenance

Review this document whenever the public Dart surface, channel names, RPC versions/catalogs, native dependency versions, result/event envelopes, initialization or lifecycle behavior, threading/timeouts, platform support, privacy controls, Purchase Connector packaging, or test strategy changes. Also review it during every release-version alignment. Update the `Last verified` date only after checking the Dart wrapper and both pinned native RPC implementations, not for prose-only edits.
