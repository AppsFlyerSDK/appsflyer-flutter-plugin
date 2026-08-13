---
id: F-017
name: SDK Kill Switch (stop)
type: sdkCore
platform: both
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
Some legal, privacy, or contractual situations (e.g. a "right to be forgotten," a regulator order, a licensing dispute) require the app to fully halt all AppsFlyer network activity immediately, for the whole SDK instance. `stop(true)` tells the native SDK to stop communicating with AppsFlyer's servers entirely, and is reversible with `stop(false)`. This is an "extreme case" API for legal/privacy compliance, distinct from the narrower per-user `anonymizeUser` (F-013). `isStopped()` reads the current state and is available only on Android.

---

## Trigger
The host app awaits `AppsFlyerSdk.instance.stop(...)` at any point — typically in response to a privacy/legal requirement such as a remote "kill switch" flag, a consent-withdrawal flow, or compliance testing — to halt or resume all SDK network communication.

---

## Call Chain
`stop` is an awaitable RPC setter on both platforms. `isStopped` is an awaitable getter that only Android implements, but it is not gated in Dart.

```
AppsFlyerSdk.stop(shouldStop)                                         [lib/src/appsflyer_sdk.dart]
  → _invokeVoidRpc('stop', {'shouldStop': shouldStop})
    → _invokeRpc → MethodChannel('af-api').invokeMethod('executeRpc', {method, params})
      → Android: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRpcHandler
        → AppsFlyerLib.stop(...)
      → iOS: AppsflyerSdkPlugin.dispatchRpc → AppsFlyerRPCBridge
  → PlatformException is converted to AppsFlyerException

AppsFlyerSdk.isStopped()                                              [Android only]
  → off Android: native RPC reports the method as unavailable → AppsFlyerException
  → _invokeRpc<bool>('isStopped')
    → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.isStopped()
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `stop(bool shouldStop)` on both platforms; `isStopped()` routed through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | Forwards `stop` and `isStopped` through the Android RPC handler |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift` | Forwards `stop` through the iOS RPC bridge |

---

## Input / Output
| | |
|--|--|
| **Input** | `stop`: `shouldStop` (`bool`) — `true` halts all SDK network activity, `false` re-enables it. RPC param key `shouldStop`. `isStopped()`: no parameters. |
| **Output** | `stop` → `Future<void>` that completes after RPC validation and the synchronous native setter invocation; it has no completion callback or timeout. `isStopped()` → `Future<bool>` on Android; an unexpected native null reply throws `AppsFlyerException`. Calling it off Android dispatches the RPC anyway and throws `AppsFlyerException` rather than returning a fabricated `false`. Bridge or validation failures surface as `AppsFlyerException`. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies in the cross-platform RPC mapping test that `stop(true)` dispatches RPC method `stop` with `{'shouldStop': true}`, and in the native-return-value test that `isStopped()` dispatches `isStopped` and returns the native `true`. `'an off-platform getter forwards rather than fabricating a value'` asserts that `isStopped()` on iOS still dispatches the `isStopped` RPC and returns the native value instead of a fabricated `false`, and `'platform-only getters surface the native method-not-found error'` covers the same call throwing `AppsFlyerException` when the native layer reports the method as unavailable.

---

## Known Limitations
- `isStopped()` is implemented only on Android. On iOS the call is still dispatched and throws `AppsFlyerException` instead of returning a `false` that could not be distinguished from a genuine "not stopped" state.
- Distinct from `anonymizeUser` (F-013): `stop` disables the entire SDK instance for all users/sessions, while `anonymizeUser` scopes an opt-out to the current user only.
- `stop(false)` resumes SDK operation, but does not itself send a Launch. Normal per-foreground `start()` handling still applies after resumption.

---

## Dependencies
```mermaid
flowchart LR
    F017["F-017 · SDK Kill Switch (stop)"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
