---
id: F-007
name: Android ID Collection Opt-out
type: sdkCore
platform: android
status: active
last_verified: 2026-07-29
depends_on: []
---

## Business Purpose
Google Play policy prohibits apps that bundle Google Play Services from collecting the Android ID for advertising/attribution purposes. `setCollectAndroidId(false)` lets a Play-Services-enabled app opt out of this collection so it stays compliant, while apps without Play Services can leave it enabled as a device-level fallback. Getting this wrong risks Play Store policy violations.

> **SDK 7 change:** the IMEI opt-out `setCollectIMEI` has been **removed** — IMEI auto-collection no longer exists in the native SDK 7, and there is no RPC bridge method for it. Only the Android-ID opt-out remains. See [`doc/migration-guide.md`](/doc/migration-guide.md).

---

## Trigger
Called by the host app during startup configuration, before `startSDK()`, when it needs to declare its Android ID collection posture (typically apps shipping with Google Play Services present).

---

## Call Chain
`setCollectAndroidId` is a generic RPC, Android-gated in Dart (no-op on iOS — Android ID is an Android-only identifier).

```
AppsflyerSdk.setCollectAndroidId(isCollect)                           [lib/src/appsflyer_sdk.dart]
  → Platform.isAndroid ? _executeRpc('setCollectAndroidID', {isCollect}) : no-op
    → af-api "executeRpc" {method:'setCollectAndroidID', params}
      → Android: dispatchRpc → AppsFlyerRpcHandler → AppsFlyerLib.setCollectAndroidID(isCollect)  [android/.../AppsflyerSdkPlugin.java]
```

---

## Files
| File | Role |
|------|------|
| `lib/src/appsflyer_sdk.dart` | `setCollectAndroidId(bool)` — `Platform.isAndroid`-guarded |
| `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` | generic `setCollectAndroidID` RPC dispatch over `AppsFlyerRpcHandler` |

---

## Input / Output
| | |
|--|--|
| **Input** | `isCollect` (bool) — `true` keeps collection enabled (default), `false` opts out. RPC param key `isCollect`. |
| **Output** | `void` — fire-and-forget; no confirmation returned to Dart. No-op on iOS. |

---

## Tests
`test/appsflyer_sdk_test.dart` verifies that `setCollectAndroidId` is a no-op on the test host (neither `Platform.isAndroid` nor `Platform.isIOS` is true), dispatching no RPC.

---

## Known Limitations
- **Android-only** and Dart-guarded: calling it on iOS is a silent no-op.
- `setCollectIMEI` was removed in SDK 7 (no native API, no RPC bridge method) — no replacement.

---

## Dependencies
```mermaid
flowchart LR
    F007["F-007 · Android ID Collection Opt-out"]:::sdkCore
    classDef sdkCore fill:#4C6EF5,color:#fff
```
