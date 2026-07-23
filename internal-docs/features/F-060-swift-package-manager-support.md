---
id: F-060
name: "Swift Package Manager (SPM) Support (Core, iOS)"
type: sdkCore
platform: ios
status: active
last_verified: 2026-07-19
depends_on: []
---

## Business Purpose
Flutter 3.44+ makes Swift Package Manager the default iOS integration mechanism, and CocoaPods trunk goes read-only on December 2, 2026 — after that date, this plugin could no longer publish new CocoaPods releases at all, and any app on Flutter 3.44+ that hadn't migrated would hit a hard build error instead of today's build warning. Without this feature, every consumer of the plugin would eventually be forced onto an unsupported distribution path, and competing attribution SDKs (Adjust, Singular) that already support SPM would have a real integration advantage. This feature adds a `Package.swift` manifest for the Core integration so apps can adopt SPM today, while leaving CocoaPods fully intact for apps that aren't ready to migrate or that need Purchase Connector (see Known Limitations).

Ticket: DELIVERY-125462.

---

## Trigger
Not a runtime trigger — this is a build-time/distribution-mechanism choice made once per consuming app project:
- **SPM path**: the app either runs on Flutter 3.44+ (SPM is the default) or explicitly opts in on earlier 3.24+ versions via `flutter config --enable-swift-package-manager`. Flutter's own tooling then discovers `ios/appsflyer_sdk/Package.swift` at its conventional path — no marker or flag is required in the podspec to signal SPM availability.
- **CocoaPods path**: unchanged — apps that run `pod install` continue to resolve via `ios/appsflyer_sdk.podspec` exactly as before.

---

## Call Chain
This feature has no runtime call chain — it is a build-time source-tree and manifest change:

```
Shared source tree (used by both paths, single copy — no duplication):
  ios/appsflyer_sdk/Sources/appsflyer_sdk/
    AppsflyerSdkPlugin.m            (moved from ios/Classes/, content unmodified)
    AppsFlyerAttribution.m          (moved, unmodified)
    AppsFlyerStreamHandler.m        (moved, unmodified)
    include/appsflyer_sdk/
      AppsflyerSdkPlugin.h          (moved, unmodified — public header, pluginClass entry point)
      AppsFlyerAttribution.h
      AppsFlyerStreamHandler.h
      FlutterAppDelegate+AppsFlyerStreamHandler.h

SPM path (resolved by `flutter build`/`swift build` at build configuration time):
  ios/appsflyer_sdk/Package.swift
    → target "appsflyer_sdk" depends on product "AppsFlyerLib" from AppsFlyerFramework, pinned exactly to 6.18.0
    → compiles the shared Sources/ tree above as a ClangTarget, iOS 12.0 minimum
    → does NOT reference ios/PurchaseConnector/ at all — no PurchaseConnector target/product exists in this manifest

CocoaPods path (resolved by `pod install` at install time, unchanged behavior):
  ios/appsflyer_sdk.podspec
    subspec 'Core' → source_files/public_header_files repointed at the same shared Sources/ tree above
    subspec 'PurchaseConnector' → untouched, still points at ios/PurchaseConnector/ (unmoved)
```

---

## Files
| File | Role |
|------|------|
| `ios/appsflyer_sdk/Package.swift` | New SPM manifest. `swift-tools-version:5.9` (Xcode 15.0+), `platforms: [.iOS("12.0")]` (matches the podspec's existing deployment target). Declares one product/target depending on `AppsFlyerFramework`'s `AppsFlyerLib` product, pinned `.exact("6.18.0")`, matching the podspec's exact CocoaPods pin. |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/*.m` | Core implementation files, moved verbatim from `ios/Classes/` via `git mv` (confirmed zero content diff) — now the single shared source tree for both CocoaPods and SPM. |
| `ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/*.h` | Public headers, moved verbatim from `ios/Classes/` — `AppsflyerSdkPlugin.h` is where `pluginClass: AppsflyerSdkPlugin` (declared in `pubspec.yaml`, unchanged) resolves from in both integration paths. |
| `ios/appsflyer_sdk.podspec` | `Core` subspec's `source_files`/`public_header_files` repointed to the new shared path; `PurchaseConnector` subspec is untouched. No marker added to declare SPM availability — Flutter's tooling detects it purely by the presence of `Package.swift` at the conventional path. |
| `ios/.gitignore` | Added `.build/` and `.swiftpm/` — local SPM resolution/build artifacts that must not be committed. |
| `CHANGELOG.md` | Documents SPM support added under the 6.18.0 entry, Purchase Connector's continued CocoaPods-only status, and a link to flutter/flutter#161182. |

---

## Input / Output
| | |
|--|--|
| **Input** | Which iOS integration mechanism the consuming app's Flutter tooling selects: SPM (default on Flutter 3.44+, opt-in via `flutter config --enable-swift-package-manager` on 3.24–3.43) or CocoaPods (`pod install`, unchanged). Nothing in `pubspec.yaml` changes to select this — it's entirely driven by the app's own Flutter/Xcode configuration. |
| **Output** | Which build system compiles the Core native code and links `AppsFlyerFramework` into the app: Swift Package Manager resolving `AppsFlyerLib` directly from GitHub, or CocoaPods resolving the `AppsFlyerFramework` pod as before. Either path produces the same compiled Core behavior — same source files, same public API surface. |

---

## Tests
No dedicated automated test — this is a build-configuration/distribution-mechanism concern with no Dart or native runtime logic change, the same category as F-054 (Purchase Connector: Build-Time Opt-in), which sets the precedent that this class of change is verified via full builds rather than unit tests. Verification performed for this change:
- `swift package describe` — genuine dependency resolution against the live `AppsFlyerFramework` GitHub repository, confirming the manifest resolves product `AppsFlyerLib` at range `6.18.0..<7.0.0` and picks up all 3 Core `.m` sources correctly.
- `pod spec lint --quick --allow-warnings` — passed, confirming the podspec's repointed `source_files`/`public_header_files` globs resolve correctly against the moved tree.
- `flutter test test` — all 38 existing Dart tests pass unaffected (this change touches only iOS native file locations and build manifests, not Dart code).

> **Outstanding pre-release gate**: the tech design's mandatory 4-path real-device build verification (SPM Core-only / CocoaPods Core-only / CocoaPods Core+PurchaseConnector / confirming SPM+PurchaseConnector is inert, all on real devices, not `--no-codesign` alone) has **not yet been run** — it requires a full macOS/Xcode/iOS-device environment that was unavailable during implementation. This must be completed before this ships (before promoting through the RC pipeline). See `docs/tech-designs/spm-support.md` for the exact verification steps.

---

## Known Limitations
- **Purchase Connector is not available via SPM this release, with no opt-in mechanism at all.** `Package.swift` never references `ios/PurchaseConnector/` and has no equivalent of the podspec's `pod_target_xcconfig` macro injection, so `ENABLE_PURCHASE_CONNECTOR` is never defined for an SPM build under any configuration. Calling a Purchase Connector Dart API from an SPM-only integration fails with the same generic Flutter `MissingPluginException` that F-054 already documents for the CocoaPods not-opted-in case — this is not a new or worse failure mode, but it is a third, permanent path to it (not something a developer can fix by setting a flag, unlike the other two paths). Apps that need Purchase Connector must stay on CocoaPods until flutter/flutter#161182 is resolved.
- **flutter/flutter#161182 (Flutter's own plugin tooling lacking conditional-compilation support under SPM) is the real blocker**, not a SwiftPM limitation — investigated during research (`docs/researches/R-001-spm-support.md`), including whether SwiftPM Package Traits (Swift tools 6.1+) could work around it. They cannot: the issue's own text states Flutter would need to add trait support to its plugin tooling first, which it has not.
- **Three architectural alternatives to bring Purchase Connector onto SPM were evaluated and rejected for this release** (see `docs/researches/R-001-spm-support.md` addendum): a second product in the same `Package.swift` (not viable — Flutter's tooling only links one product per plugin, no documented support for a second), an environment-variable-gated compile flag (technically usable but fragile — requires every consuming app to set an env var on every build/CI run with silent failure if forgotten), and splitting Purchase Connector into its own federated pub.dev package (architecturally sound, no hidden blocker, but a separate, larger initiative with its own versioning/release pipeline — a candidate future initiative, not part of this ticket).
- **Real-device build verification is outstanding** — see Tests section above. Static/network verification (Swift manifest resolution, podspec lint, Dart test suite) passed, but the tech design's full 4-path device build has not yet run.

---

## Dependencies
```mermaid
flowchart LR
    F060["F-060 · Swift Package Manager Support"]:::sdkCore
    F054["F-054 · Purchase Connector: Build-Time Opt-in"]:::purchaseValidation
    F060 -->|"adds a third, permanently-excluded iOS path to"| F054
    classDef sdkCore fill:#4C6EF5,color:#fff
    classDef purchaseValidation fill:#F59F00,color:#fff
```
