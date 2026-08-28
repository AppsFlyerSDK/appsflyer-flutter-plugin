---
id: F-070
name: Android Launcher Activity Referrer Collection
type: sdkCore
platform: android
status: active
last_verified: 2026-08-19
depends_on: [F-001]
---

## Business Purpose
`collectDataFromLauncherActivity()` exposes the Android native SDK's launcher-activity data collection API, which reads the open/web referrer from the launcher `Activity`'s intent so it can be attributed to the first session.

## Trigger
Called explicitly on Android after `init()` and before the first `start()`, so the referrer reaches the first Launch. Added to the plugin with Android RPC 7.0.12, which introduced the `collectDataFromLauncherActivity` RPC method.

## Call Chain
```
AppsFlyerSdk.collectDataFromLauncherActivity()                        [lib/src/appsflyer_sdk.dart]
  → off Android: native layer reports the method as unavailable → AppsFlyerException (404)
  → _invokeVoidRpc('collectDataFromLauncherActivity', {})
    → Android AppsflyerSdkPlugin generic RPC forwarding
      → process-scoped AppsFlyerRpcHandler(contextProvider = AppsFlyerContextHolder::current)
        → contextProvider() returns the most recently attached Activity
          → AppsFlyerLib.collectDataFromLauncherActivity(activity)
```

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | Public Android-only method, dispatched through RPC without a Dart platform check |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` | No per-method handler — generic `executeRpc` forwarding |
| `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsFlyerContextHolder.kt` | Supplies the attached `Activity` to the handler's `contextProvider` |
| Android `plugin_bridge/.../AppsFlyerRpcHandler.kt` | Casts `contextProvider()` to `Activity` and invokes `AppsFlyerLib.collectDataFromLauncherActivity(activity)`; answers `422` when the context is not an `Activity` |

## Input / Output
| | |
|--|--|
| **Input** | None; the RPC params map is empty. |
| **Output** | On Android, `Future<void>` completes after synchronous native SDK invocation, with no delivery callback or timeout. When no `Activity` is attached, `AppsFlyerContextHolder.current()` returns the application context and the native handler answers `422`, surfacing as `AppsFlyerException`. Off Android the call is still dispatched and throws `AppsFlyerException` (code `404`) once the native layer reports the method as unavailable. |

## Tests
`test/appsflyer_sdk_test.dart` verifies the Android RPC name and empty params in `'maps every Android-only API'`, and in `'platform-only calls are forwarded to the native RPC instead of being swallowed in Dart'` that a non-Android call still reaches the native layer. `android/src/test/kotlin/com/appsflyer/appsflyersdk/AppsFlyerContextHolderTest.kt` pins the context resolution this method depends on: Activity preference, fallback after detach, most-recent-wins across two engines, and that one engine's detach leaves an `Activity` another engine shares in place.

## Known Limitations
- Requires an attached `Activity`. A headless or background Flutter engine has none, so the call fails with `AppsFlyerException` (`422`) rather than silently doing nothing.
- The Flutter layer cannot tell whether a referrer was actually found in the intent.

## Dependencies
F-001 — call after `init()` and before the first F-002 `start()`.
