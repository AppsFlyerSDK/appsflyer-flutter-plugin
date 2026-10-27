---
id: F-071
name: "iOS Strict Mode: CocoaPods Opt-in"
type: sdkCore
platform: ios
status: active
last_verified: 2026-09-15
depends_on: []
---

## Business Purpose
The native AppsFlyer iOS SDK ships **Main** and **Strict** CocoaPods subspecs with
different binaries and embedded privacy manifests (`PrivacyInfo.xcprivacy`). Kids
apps and ad-ID-less integrations must link **Strict** so App Store privacy labels
match behavior. Runtime APIs such as `setDisableAdvertisingIdentifiers` (F-034) do
not swap the linked binary. This feature exposes a supported Podfile global so
integrators do not fork the plugin or add conflicting `pod 'AppsFlyerFramework/Strict'`
lines (GitHub #473).

---

## Trigger
Build-time only. The consuming app sets `$AppsFlyerStrictMode = true` in `ios/Podfile`
before `flutter_ios_podfile_setup` / `pod install`.

---

## Call Chain
No runtime call chain — CocoaPods resolves native dependencies at `pod install`:

```
App Podfile: $AppsFlyerStrictMode = true
  → ios/appsflyer_sdk.podspec (Core subspec)
      if defined?($AppsFlyerStrictMode) && $AppsFlyerStrictMode
        ss.ios.dependency 'AppsFlyerRPC/Strict', '7.0.13'
        ss.ios.dependency 'AppsFlyerFramework/Strict', '7.0.2'
      else
        ss.ios.dependency 'AppsFlyerRPC/Main', '7.0.13'
        ss.ios.dependency 'AppsFlyerFramework/Main', '7.0.2'
```

Both RPC and Framework must use the same variant; RPC/Main pulls Main framework and
would duplicate `AppsFlyerLib.xcframework` if only Framework were switched.

---

## Files
| File | Role |
|------|------|
| `ios/appsflyer_sdk.podspec` | Branches Core subspec dependencies on `$AppsFlyerStrictMode` |
| `doc/installation-guide.md` | Public opt-in, anti-patterns, SPM / Purchase Connector limits |
| `scripts/verify-version-consistency.sh` | Reads `appsflyer_framework_version` / `appsflyer_rpc_version` pins |

---

## Input / Output
| | |
|--|--|
| **Input** | Ruby global `$AppsFlyerStrictMode` truthy in app Podfile before pod install |
| **Output** | Resolved pods `AppsFlyerRPC/Strict` + `AppsFlyerFramework/Strict`; Strict `PrivacyInfo.xcprivacy` (`NSPrivacyTracking` false) in the linked xcframework |

---

## Known Limitations
- **SPM (F-060):** No Strict path; `Package.swift` always resolves Regular/Main.
- **Purchase Connector (F-054):** Enabling both `$AppsFlyerPurchaseConnector` and
  `$AppsFlyerStrictMode` may still duplicate frameworks because the Purchase Connector
  pod pins Regular `AppsFlyerFramework`.
- **Verification:** Confirm via `Podfile.lock`, paths under `Pods/.../xcframework/strict/`,
  and `plutil` on `PrivacyInfo.xcprivacy` — not via Dart logs.

---

## Tests
Manual: `$AppsFlyerStrictMode = true`, `pod install`, build iOS example; assert no
duplicate `appsflyerlib.xcframework` error and Strict privacy manifest values.
