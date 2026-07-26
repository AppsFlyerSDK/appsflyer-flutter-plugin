---
id: F-002
name: SDK Start (auto/manual + result handler)
type: sdkCore
platform: both
status: active
last_verified: 2026-07-15
depends_on: ["F-001"]
---

## Business Purpose
When `manualStart: true` is set on `AppsFlyerOptions` (F-001), the native SDK is initialized but deliberately does **not** begin sending sessions/attribution requests — this lets the host app gate the first network call behind consent collection (see F-011/F-012) or other startup preconditions. `startSDK()` is the trigger that actually opens the session. Without it, apps using manual-start mode would never attribute installs or sessions. The optional `onSuccess`/`onError` handler variant lets the app know definitively whether the first session request succeeded, which matters for CMP/consent flows that need to confirm the SDK is live before proceeding.

> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.

---

## Trigger
Called explicitly by the host app after `initSdk()` when `manualStart: true` was configured. Also implicitly satisfied automatically inside `initSdk`/`initSdkWithCall:` on both platforms when `manualStart` is `false` (the default), meaning most apps never call `startSDK()` directly.

---

## Call Chain
```
AppsflyerSdk.startSDK({onSuccess, onError})                                  [lib/src/appsflyer_sdk.dart]
  → guards on _isSdkStarted (no-op if already started)
  → if onSuccess/onError provided:
      _methodChannel.setMethodCallHandler(...)  // listens for native "onSuccess"/"onError"
      _methodChannel.invokeMethod('startSDKwithHandler')
        → Android: AppsflyerSdkPlugin.startSDKwithHandler(call, result)      [android/.../AppsflyerSdkPlugin.java]
          → AppsFlyerLib.getInstance().start(activity, null, AppsFlyerRequestListener)
            → onSuccess()/onError() → mMethodChannel.invokeMethod("onSuccess"|"onError")
        → iOS: AppsflyerSdkPlugin.startSDKwithHandler:result:                [ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m]
          → [[AppsFlyerLib shared] startWithCompletionHandler:^(...)]
            → [_methodChannel invokeMethod:@"onSuccess"|@"onError" ...]
  → else:
      _methodChannel.invokeMethod('startSDK')
        → Android: AppsflyerSdkPlugin.startSDK(call, result) → AppsFlyerLib.getInstance().start(activity)
        → iOS: AppsflyerSdkPlugin.startSDK:result: → [[AppsFlyerLib shared] start]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `startSDK()` — guards double-start via `_isSdkStarted`, chooses handler vs. plain path |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | `startSDK`, `startSDKwithHandler` — native start, posts `onSuccess`/`onError` back on the UI thread |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m` | `startSDK:result:`, `startSDKwithHandler:result:` — native start, dispatches completion handler results on main queue |

---

## Input / Output
| | |
|--|--|
| **Input** | Optional `RequestSuccessListener onSuccess` and `RequestErrorListener onError` Dart callbacks; no other parameters |
| **Output** | No return value from `startSDK()` itself (`void`). If a handler was supplied, the native side invokes `onSuccess` with no arguments, or `onError(int errorCode, String errorMessage)` back through the Dart `MethodChannel.setMethodCallHandler`, after which the handler is torn down (`setMethodCallHandler(null)`) so it fires only once. |

---

## Tests
No dedicated test found. `test/appsflyer_sdk_test.dart` covers `initSdk`, `setHost`, `logEvent`, etc., but has no test invoking `instance.startSDK(...)` in either its handler or plain form, and no test for the `_isSdkStarted` double-start guard.

---

## Known Limitations
- `_isSdkStarted` is set to `true` as a side effect of `initSdk()` whenever `manualStart == false` (auto-start mode). If the host app then also calls `startSDK()` "just in case," the Dart guard silently no-ops it — this is correct behavior but is easy to misread as a bug when debugging why a manually-added `startSDK()` call appears to do nothing.
- If `startSDK()` is called with a handler and the native side never calls back (e.g. process death, or an unexpected exception path), the Dart method handler is never cleared and `_isSdkStarted` remains `true` forever, permanently blocking any future `startSDK()` call for that app session.
- On the `default` branch of the Android `setMethodCallHandler` switch (i.e. an unrecognized method name arrives), the Dart code resets `_isSdkStarted = false`, which would allow a subsequent `startSDK()` call to fire a second native `start()` — this branch is not currently exercised by any real native call and appears to be defensive/dead code.
- iOS's `startSDKwithHandler:` also registers a `UIApplicationDidBecomeActiveNotification` observer (`appDidBecomeActive`) as a side effect of the plain `startSDK:` path but not from within `startSDKwithHandler:` itself — foreground-resume auto-restart behavior differs subtly between the two start paths.

---

## Dependencies
```mermaid
flowchart LR
    F002["F-002 · SDK Start"]:::sdkCore -->|"only meaningful when manualStart is set during"| F001["F-001 · SDK Initialization & Options Validation"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
