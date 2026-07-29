---
ticket: DELIVERY-125462
priority: P1
target: v6.18.0, end of July 2026
---

# PRD: Swift Package Manager (SPM) Support

> **⚠️ Superseded — historical planning record (do not treat as current).** This PRD targeted SPM support for the SDK **6.18.0** line (DELIVERY-125462, "target: v6.18.0"). The plugin has since migrated to **SDK 7 / RPC**: iOS now vendors the **AppsFlyerRPC 7.0.12** static xcframework as a `binaryTarget` (→ AppsFlyerFramework 7.0.1) and targets **iOS 13.0**. Current SPM state lives in `ios/appsflyer_sdk/Package.swift`, `internal-docs/features/F-060-swift-package-manager-support.md`, and `internal-docs/ARCHITECTURE.md`. Kept for context only.

## Problem

The plugin's iOS integration ships only via CocoaPods (`ios/appsflyer_sdk.podspec`). Two industry shifts make this untenable on the current timeline:

1. Flutter 3.44+ makes Swift Package Manager the default iOS integration mechanism. Plugins without an SPM manifest already surface a build warning in consuming apps today.
2. CocoaPods trunk (the `pod repo push` publishing path) goes **read-only on December 2, 2026**. Once that happens, the plugin cannot ship *new* CocoaPods releases at all — the build warning becomes a hard build error for any app that hasn't migrated, and we lose the ability to patch the CocoaPods distribution.

Competing attribution SDKs (Adjust, Singular) already support SPM, so apps that need SPM today are choosing those SDKs over ours. The community has raised this twice (tracking issue #364, draft PR #370) and both attempts stalled on the same blocker: the `PurchaseConnector` subspec has no clean SPM path because it depends on an upstream Flutter engine limitation (flutter/flutter#161182) that is outside this plugin's control.

## Goal

Ship a `Package.swift` manifest so apps can integrate the plugin's Core (default) functionality via SPM, while `PurchaseConnector` remains CocoaPods-only until upstream Flutter resolves flutter/flutter#161182. Existing CocoaPods consumers must see zero behavior change.

Success: an app can add the plugin via SPM and get full attribution/deep-linking functionality (everything except Purchase Connector) with no CocoaPods dependency, by end of July 2026, in v6.18.0.

## Non-goals

- Making `PurchaseConnector` available via SPM — explicitly blocked on flutter/flutter#161182; out of scope until that upstream issue is resolved.
- Dropping or deprecating CocoaPods support — CocoaPods remains fully supported in this release.
- Migrating the Android side of the plugin (SPM is iOS/Apple-platform-only; no Android equivalent exists).
- Evaluating Swift Package Manager Traits (Swift tools 6.1+) as a mechanism to ship `PurchaseConnector` conditionally via SPM — flagged as a candidate for Bob to research, but committing to it is out of scope for this PRD until Bob confirms it's viable and doesn't just relocate the same upstream Flutter blocker.

## User/customer impact

- **Apps not using Purchase Connector**: can adopt SPM immediately, removing their CocoaPods dependency and the build warning; avoids a hard build break after Dec 2, 2026.
- **Apps using Purchase Connector**: must stay on CocoaPods (full install) until the upstream blocker resolves. They are not broken by this change, but they don't get the SPM option yet — this is a real, currently-unavoidable gap that needs to be communicated clearly in docs/release notes so these teams aren't surprised post-Dec-2026.
- **Existing CocoaPods consumers (any config)**: no behavior change — this PRD requires full backward compatibility as an explicit requirement, not an assumption.

## Requirements

1. Add a `Package.swift` manifest exposing the Core integration as an SPM product, building on the approach already prototyped in draft PRs #455 and #454.
2. `PurchaseConnector` is NOT exposed via SPM in this release; it remains a CocoaPods-only subspec, gated the same way `appsflyer.enable_purchase_connector` / `$AppsFlyerPurchaseConnector` already gate it today (see F-054).
3. `ios/appsflyer_sdk.podspec` continues to work unmodified in behavior for existing CocoaPods consumers — both the Core-only and Core+PurchaseConnector configurations.
4. Both integration paths must be verified before release:
   - SPM-only (Core, no PurchaseConnector)
   - CocoaPods, Core only
   - CocoaPods, Core + PurchaseConnector
   - (Explicitly NOT required: SPM + PurchaseConnector — not supported this release)
5. `CHANGELOG.md` and plugin release notes document: SPM support added, PurchaseConnector's CocoaPods-only status and why, and a pointer to flutter/flutter#161182 for apps tracking when Purchase Connector SPM support might land.
6. Ship as part of the current SDK 6 line, v6.18.0.

## Acceptance criteria

- [ ] A fresh Flutter app added via SPM (no `Podfile`) builds successfully on iOS and can call Core attribution APIs (init, start, event logging) end to end.
- [ ] A fresh Flutter app using CocoaPods with `PurchaseConnector` disabled builds and behaves identically to pre-change behavior.
- [ ] A fresh Flutter app using CocoaPods with `PurchaseConnector` enabled builds and behaves identically to pre-change behavior.
- [ ] Attempting to reference Purchase Connector APIs from an SPM-only integration fails at build/compile time with a clear signal (not a silent runtime no-op) — exact mechanism to be defined by Dave in tech design.
- [ ] `CHANGELOG.md` entry and release notes are published alongside v6.18.0 describing the SPM addition and the PurchaseConnector CocoaPods-only limitation.
- [ ] No existing `example/` app (CocoaPods-based) requires any change to keep building.

## Risks

- **Release risk**: this touches the iOS distribution mechanism for every consumer of the plugin, including all existing CocoaPods apps. A `Package.swift` misconfiguration or podspec regression could break builds plugin-wide. Requires explicit verification of all three supported build paths (Requirement 4) before shipping, not just the new SPM path.
- **Confusing failure mode risk**: if referencing Purchase Connector from an SPM-only integration fails silently or with an unclear Swift compiler error, it repeats the exact "confusing MissingPluginException" failure pattern already documented as a known limitation of the existing CocoaPods opt-in gate (F-054). Dave's tech design must address this explicitly.
- **Deadline risk**: CocoaPods trunk goes read-only Dec 2, 2026, well after this July 2026 ship date — no schedule risk from that deadline itself, but it does mean this is the last comfortable window to ship before urgency increases.
- **Scope creep risk**: SPM Package Traits (surfaced during research) could look like a tempting way to "solve" the PurchaseConnector gap now. Bob must confirm whether it actually changes anything about the flutter/flutter#161182 blocker before any decision to expand scope — the default assumption per ticket is that PurchaseConnector stays CocoaPods-only this release regardless of what traits offer.

## Open questions

- ~~Does flutter/flutter#161182 block *any* SPM path for PurchaseConnector, or does SPM Package Traits (Swift tools 6.1+) offer a way around it?~~ **Resolved (R-001):** flutter/flutter#161182 is still open and is about Flutter's own plugin build tooling lacking conditional-compilation support — not something SwiftPM Traits can fix from our side, since Flutter doesn't route plugin builds through traits today. PurchaseConnector stays CocoaPods-only this release, as originally scoped; traits are not a viable shortcut.
- ~~What is the minimum Xcode / Swift tools version the target Package.swift manifest requires, and is it compatible with the Flutter versions this plugin currently supports?~~ **Resolved (R-001):** `AppsFlyerFramework`'s own SPM package (dependency) requires Swift tools 5.3; draft PRs use tools-version 5.9 (Xcode 15.0+ minimum) for this plugin's own manifest. No conflict with `pubspec.yaml`'s Dart SDK/Flutter constraints — SPM eligibility is gated by the consuming app's Flutter tool version, not this package's declared environment.
- What exact compile-time signal should apps get if they reference Purchase Connector APIs without CocoaPods? (compiler error vs. missing symbol vs. something else) — **Dave to resolve in tech design.** (R-001 notes this should surface as a build/link error, not a silent runtime no-op — an improvement over F-054's existing CocoaPods failure mode — but Dave must confirm this holds for the SPM path specifically.)
- Do draft PRs #455/#454 already answer the Package.swift structure question, or do they need re-validation against the current plugin structure? — **Partially resolved (R-001):** #454 is the recommended starting point (move-based layout, already isolates PurchaseConnector correctly) but its dependency declaration is wrong (`AppsFlyerLib`, not `AppsFlyerLib-Static`) and neither draft PR completed real CI/device-build verification — **Dave to re-validate and correct in tech design**, and confirm the exact required `Package.swift` path convention against Flutter's official plugin-author SPM guide.
