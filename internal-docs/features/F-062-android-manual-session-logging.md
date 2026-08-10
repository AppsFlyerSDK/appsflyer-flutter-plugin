---
id: F-062
name: Android Manual Session Logging
type: sdkCore
platform: android
status: active
last_verified: 2026-08-10
depends_on: []
---

## Business Purpose
`logSession()` exposes the Android native SDK's manual session logging API. It is an exceptional integration surface; normal Flutter lifecycle handling uses F-002 `start()` from each F-002 session-ready event.

## Trigger
Called explicitly on Android only when an integration has a verified need to invoke the native manual-session API. It is not a replacement for initialization or the standard per-foreground `start()` workflow.

## Call Chain
```
AppsFlyerSdk.logSession()                                             [lib/src/appsflyer_sdk.dart]
  → non-Android: log warning and return
  → _invokeVoidRpc('logSession', {})
    → Android AppsflyerSdkPlugin generic RPC forwarding
      → AppsFlyerRpcHandler → AppsFlyerLib.logSession(context)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-guarded method |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | Generic RPC forwarding |
| Android `plugin_bridge/.../AppsFlyerRpcHandler.kt` | Invokes `AppsFlyerLib.logSession(context)` |

## Input / Output
| | |
|--|--|
| **Input** | None; the RPC params map is empty. |
| **Output** | On Android, `Future<void>` completes after synchronous native SDK invocation, with no delivery callback or timeout. Bridge failures surface as `AppsFlyerException`. Off Android the call logs a warning, dispatches nothing, and completes normally. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android RPC name/empty params and the non-Android no-op guard. Native handler tests cover forwarding.

## Known Limitations
- The Flutter layer cannot tell whether the native SDK accepted or sent the manual session.
- Mixing this call with the normal F-002 start flow can create unexpected session accounting; use it only when the Android integration requirement is explicit.

## Dependencies
No required feature dependency. F-002 remains the standard lifecycle workflow.
