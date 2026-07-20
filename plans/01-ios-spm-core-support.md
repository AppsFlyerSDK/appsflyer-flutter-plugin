# Plan: Add Swift Package Manager (SPM) support to Core (DELIVERY-125462)

Jira: https://appsflyer.atlassian.net/browse/DELIVERY-125462 (P1, assignee: Kobi Kagan, target: end of July 2026, ships inside v6.18.0 line)

## Goal

Add a `Package.swift` for the plugin's **Core** module so SPM-enabled Flutter apps (Flutter 3.44+ default) can build against this plugin without CocoaPods, while:
- Keeping the **PurchaseConnector** subspec CocoaPods-only (blocked upstream by [flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182) — no SPM opt-in mechanism exists in Flutter tooling today)
- Preserving 100% CocoaPods backward compatibility for apps not yet on SPM

---

## Phase 0: Documentation Discovery (consolidated findings — do not re-derive, cite these)

### A. Prior art in this repo — three existing draft PRs, none merged

| PR | Approach | Verdict |
|---|---|---|
| [#454](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/pull/454) (`nurlangarash`) | True `git mv` of `Classes/*` → `ios/appsflyer_sdk/Sources/appsflyer_sdk/` (+headers → `.../include/appsflyer_sdk/`), podspec updated to match, single source of truth. Depends on `AppsFlyerFramework-Static` / product `AppsFlyerLib-Static` (matches `static_framework = true`). Copilot flagged `.iOS("12.0")` (invalid) and product/target name mismatch — **both already fixed** in follow-up commit `98d9938dd2`. PurchaseConnector explicitly untouched. | **Use this as the base.** |
| [#455](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/pull/455) (`TeddyYeung`) | Duplicates Core sources into a second tree, leaves podspec pointing at old `Classes/` — two copies to maintain forever. Same `.iOS("12.0")` bug, **never fixed**. Adds `.gitignore` entries (`.build/`, `.swiftpm/`) — worth cherry-picking. | Reject the architecture; take only the `.gitignore` hunk. |
| [#370](https://github.com/AppsFlyerSDK/appsflyer-flutter-plugin/pull/370) (`alejandro-all-win-software`, oldest) | Tried to fold PurchaseConnector itself into SPM via an env-var-gated target (`ENABLE_PURCHASE_CONNECTOR=1`) + dependency on `appsflyer-apple-purchase-connector`. Author's own comment: *"blocked by flutter/flutter#161182... if you find another way to opt in to Purchase Connector, I'd be happy to close this PR in favor of that approach."* | **Do not repeat this.** This is exactly the dead end DELIVERY-125462 tells us to route around by staying CocoaPods-only for PurchaseConnector. |

None of the three have maintainer review; all are `REVIEW_REQUIRED`/`BLOCKED` on branch protection only (CI/security scans pass on all three).

### B. Ground-truth structure (verified against a real, live, first-party plugin: `image_picker_ios` in `flutter/packages`, not just docs prose)

Target layout (adapted to our plugin, matches what #454 already did):
```
ios/appsflyer_sdk.podspec                                            # unchanged location, paths updated
ios/appsflyer_sdk/Package.swift                                      # new
ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerAttribution.m
ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsFlyerStreamHandler.m
ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.m
ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsFlyerAttribution.h
ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsFlyerStreamHandler.h
ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/AppsflyerSdkPlugin.h
ios/appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/FlutterAppDelegate+AppsFlyerStreamHandler.h
```
Our case is simpler than `image_picker_ios`: our podspec has never set a custom `s.module_map`, so no umbrella header / `.modulemap` file is needed — CocoaPods' and SwiftPM's default module generation both suffice. Don't add one (that would be inventing a requirement we don't have).

`Package.swift` (the corrected version from #454's follow-up commit is the right shape):
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "appsflyer_sdk",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "appsflyer-sdk", targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static.git", exact: "6.18.0")
    ],
    targets: [
        .target(
            name: "appsflyer_sdk",
            dependencies: [
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static")
            ],
            path: "Sources/appsflyer_sdk",
            cSettings: [
                .headerSearchPath("include/appsflyer_sdk")
            ]
        )
    ]
)
```
Anti-pattern guard (from Copilot's actual review on #454): `.iOS("12.0")` is **not** valid SwiftPM API — must be `.iOS(.v12)`. Library name uses hyphens (`appsflyer-sdk`), target/package name keeps underscores (`appsflyer_sdk`) — this is Flutter's documented convention, not a typo.

Podspec `Core` subspec path update (mirrors #454 exactly):
```ruby
# before
ss.source_files = 'Classes/**/*'
ss.public_header_files = 'Classes/**/*.h'
# after
ss.source_files = 'appsflyer_sdk/Sources/appsflyer_sdk/**/*.{h,m}'
ss.public_header_files = 'appsflyer_sdk/Sources/appsflyer_sdk/include/**/*.h'
```
`PurchaseConnector` subspec: **zero changes.**

### C. Repo conventions (fact-checked, not assumed)

- **CHANGELOG.md**: `## <version>` header, flat `-` bullets, newest on top. Current top entry is `## 6.18.0`.
- **pubspec.yaml**: `version: 6.18.0`, no existing SPM-related keys — none are required; Flutter auto-detects `Package.swift` by convention path, no pubspec opt-in needed.
- **CI**: `.github/workflows/lint-test-build.yml` (`build-ios` job) and `ios-e2e.yml` (`e2e-ios` job) both do `pod install` + `flutter build ios` — pure CocoaPods today, zero SPM verification exists anywhere in CI.
- **Docs**: `doc/Installation.md` has no SPM section at all today. `doc/PurchaseConnector.md:74-76` documents the CocoaPods-only opt-in (`$AppsFlyerPurchaseConnector = true` in Podfile) — this needs a caveat added (see Phase 4).
- **PurchaseConnector opt-in today**, confirmed by repo-wide grep, is exclusively: `if defined?($AppsFlyerPurchaseConnector)` in the podspec, set by the consumer's own Podfile. The example app itself does **not** set this flag.
- Public header surface for `Core` is exactly 4 files: `AppsFlyerAttribution.h`, `AppsFlyerStreamHandler.h`, `AppsflyerSdkPlugin.h`, `FlutterAppDelegate+AppsFlyerStreamHandler.h`.
- `AppsflyerSdkPlugin.m` already guards PurchaseConnector registration behind `#ifdef ENABLE_PURCHASE_CONNECTOR` (a preprocessor flag CocoaPods sets via `GCC_PREPROCESSOR_DEFINITIONS`). **This flag is never defined in the new `Package.swift`, so that code path is simply compiled out under SPM — no dangling reference, nothing to fix here.**

### D. Known architectural limitation to surface, not hide

Per Flutter's own SPM integration model: once a plugin ships a `Package.swift`, Flutter routes that **entire plugin** through SPM for any app that has SPM enabled — the podspec's fallback Podfile path is not used for that plugin at all in that mode. That means **an SPM-enabled consumer app cannot reach the `PurchaseConnector` subspec or its `$AppsFlyerPurchaseConnector` Podfile flag at all** — not "it might not work," but "the mechanism that would enable it never runs." This is the concrete, user-facing shape of the flutter/flutter#161182 blocker, and it must be stated explicitly in docs (Phase 4), not left for users to discover as a silent failure.

### E. Do SwiftPM "Package Traits" close this gap? No — checked and ruled out, don't revisit without new evidence

SwiftPM added **Package Traits** in Swift 6.1 ([docs.swift.org/swiftpm/.../packagetraits](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/packagetraits/)) — a real, build-time optional-feature mechanism (`traits: [.default(enabledTraits:...), .trait(name:...)]` in the package author's manifest; conditional compilation via `#if TraitName`). This is architecturally the kind of thing that could gate an optional `PurchaseConnector` target. It does **not** change our plan, for two concrete reasons:

1. **Traits are enabled by the consumer's own `Package.swift`** — `.package(url: ..., traits: [.init(name: "PurchaseConnector")])` — or via CLI (`swift build --traits X`). Flutter apps don't have a hand-authored `Package.swift`; Flutter's tooling *generates* `FlutterGeneratedPluginSwiftPackage` automatically from `pubspec.yaml`, and that generation pipeline has **no trait-selection input** today. There is nowhere in `pubspec.yaml` or `flutter build` for an app developer to say "enable the PurchaseConnector trait." This is exactly the surface flutter/flutter#161182 would need to add — it remains open/unresolved as of this writing.
2. **Requires `swift-tools-version: 6.1`.** Our `Package.swift` (Phase 2) is `5.9`, matching Flutter's own official template and PR #454's precedent, chosen for the widest Xcode/toolchain compatibility against our `iOS 12` deployment target. Bumping to 6.1 to get traits would raise the minimum Xcode/Swift toolchain for every consumer, for a feature-gate mechanism Flutter can't even plumb through yet — not a reasonable trade today.

**Conclusion: no plan change.** Keep Core-only SPM + CocoaPods-only PurchaseConnector as decided. Revisit only if Flutter ships trait pass-through from `pubspec.yaml`/`flutter build` (i.e. flutter/flutter#161182 or a successor issue closes with that shape) — at that point, adding a `purchase_connector` trait to `Package.swift` would be the natural next step, gated on bumping `swift-tools-version` to 6.1+.

---

## Phase 1: Establish the branch from PR #454

**What to do:**
1. `gh pr checkout 454` (or fetch `nurlangarash:feat/swift-package-manager-support`) into a new local branch off current `master`.
2. Rebase onto current `master` HEAD (`df7f4854`) — resolve `CHANGELOG.md` conflicts by keeping master's `## 6.18.0` entry intact and adding the new SPM entry above/alongside it per Phase 3, not overwriting it.
3. Confirm the rebased diff still matches the structure in Phase 0.B exactly — no drift from master's current `Classes/*` file set (master has 4 headers + `AppsFlyerAttribution.m`/`AppsFlyerStreamHandler.m`/`AppsflyerSdkPlugin.m`; confirm #454's `git mv` list is unchanged since June 22).

**Verification:** `git diff master --stat` shows only expected renames/adds — no unexpected deletions, no `ios/PurchaseConnector/**` touched, no `ios/Classes/**` files left behind untouched (they should all be gone, replaced by the SPM tree — CocoaPods now points at the new path per Phase 0.B).

**Anti-pattern guard:** Do not adopt #455's duplication approach even partially — no two copies of the same `.m`/`.h` file should exist after this phase.

---

## Phase 2: Structural fixes & cleanup

**What to do:**
1. Cherry-pick #455's `.gitignore` addition: `.build/`, `.swiftpm/`.
2. Confirm `Package.swift` matches the corrected form in Phase 0.B exactly (`.iOS(.v12)`, not `.iOS("12.0")`; product `AppsFlyerLib-Static` from `AppsFlyerFramework-Static`, pinned `exact: "6.18.0"` to match the podspec's `AppsFlyerFramework` pin).
3. Confirm `cSettings: [.headerSearchPath("include/appsflyer_sdk")]` is present (required for the `.m` files' `#import` statements to resolve).
4. Confirm all 4 public headers live under `Sources/appsflyer_sdk/include/appsflyer_sdk/` and the 3 `.m` files live directly under `Sources/appsflyer_sdk/` (not under `include/`).

**Verification:**
- `grep -rn "ENABLE_PURCHASE_CONNECTOR" ios/appsflyer_sdk/Sources/` — confirm the `#ifdef` guard is untouched and no unconditional reference to `PurchaseConnectorPlugin` was introduced.
- `pod lib lint ios/appsflyer_sdk.podspec --configuration=Debug --skip-tests --use-modular-headers` passes (validates the CocoaPods path still resolves against the new file paths).

**Anti-pattern guard:** Do not add a `.modulemap`/umbrella header — our podspec never had one; don't invent structure `image_picker_ios` needed for reasons that don't apply here.

---

## Phase 3: Version bump & CHANGELOG

**Confirmed baseline (verified directly against `releases/6.x.x/6.18.x/6.18.0-rc1`, the actual last-released branch — identical to current `master`, nothing later exists in this repo):**
- Plugin version: `6.18.0`
- iOS Core `AppsFlyerFramework`: `6.18.0`
- iOS `PurchaseConnector` (podspec: `ss.ios.dependency 'PurchaseConnector', '6.18.0'`): `6.18.0`
- Android `purchase-connector` (`build.gradle`: `implementation 'com.appsflyer:purchase-connector:2.2.0'`): `2.2.0`

This is a **plugin-only** change (adds SPM plumbing, does not touch native SDK versions) — so none of the above native pins change. `AppsFlyerFramework-Static` in `Package.swift` (Phase 2) must pin `exact: "6.18.0"` to match, not any other number.

**What to do:**
1. Bump `pubspec.yaml` `version:` from `6.18.0` to `6.18.0+1` (matches repo's existing `+N` build-suffix convention for same-SDK-version plugin updates, e.g. `6.17.7+1` seen in CHANGELOG history).
2. Add new top `CHANGELOG.md` entry above `## 6.18.0`:
   ```
   ## 6.18.0+1

   - Added Swift Package Manager (SPM) support for the Core module (iOS). PurchaseConnector remains CocoaPods-only pending flutter/flutter#161182 (iOS PurchaseConnector 6.18.0 / Android purchase-connector 2.2.0 unchanged).
   ```

**Verification:** `grep -A3 "^## 6.18.0+1" CHANGELOG.md` shows the new entry; `pubspec.yaml` version matches; confirm no native dependency version in podspec/build.gradle/Package.swift was changed by this phase.

**Note:** Confirm this version number against whatever the `rc-release` skill / RC pipeline expects before tagging — don't hardcode a release version without checking the active RC process.

---

## Phase 4: Documentation updates

**What to do:**
1. `doc/Installation.md`: add a new "Swift Package Manager" section documenting that Core supports SPM as of this version, and that apps must still use CocoaPods if they need PurchaseConnector.
2. `doc/PurchaseConnector.md`: add an explicit caveat near the "How to Opt-In" section (lines ~66-82): *PurchaseConnector requires CocoaPods; it is not available in SPM-enabled apps until [flutter/flutter#161182](https://github.com/flutter/flutter/issues/161182) is resolved.*
3. `README.md`: no structural change needed (it only links to `doc/Installation.md`), but confirm the SDK Versions table still matches `6.18.0`/`AppsFlyerFramework-Static` if that pin changes.

**Verification:** Manual read-through; confirm no doc implies PurchaseConnector "might work" under SPM — it must state plainly that it does not.

**Anti-pattern guard:** Do not word this as "partial support" or "coming soon" — per Phase 0.D this is a hard mechanism gap, not a rough edge.

---

## Phase 5: CI verification

**What to do:**
1. Confirm existing `lint-test-build.yml` (`build-ios`) and `ios-e2e.yml` (`e2e-ios`) jobs still pass unmodified — these exercise the CocoaPods path (regression check for apps not on SPM).
2. Add a new step or job (e.g. `build-ios-spm` in `lint-test-build.yml`) that runs against the `example/` app with SPM enabled (`flutter config --enable-swift-package-manager`) and does `flutter build ios --no-codesign` — verifying the Core-only SPM path resolves and links.
3. Manually verify (not necessarily CI-gated, since it's an intentional non-feature) that an SPM-enabled example app cannot reach PurchaseConnector — i.e. confirm there's no `pod install` step running for `appsflyer_sdk` at all in that mode, consistent with Phase 0.D.

**Full verification matrix required by the ticket:**

| Build mode | PurchaseConnector requested? | Expected result |
|---|---|---|
| CocoaPods (existing) | No | Builds, Core only — unchanged from today |
| CocoaPods (existing) | Yes (`$AppsFlyerPurchaseConnector = true`) | Builds with PurchaseConnector — unchanged from today |
| SPM (new) | No | Builds, Core only — **new capability** |
| SPM (new) | Yes (attempted) | No mechanism to opt in — confirm this fails/is absent cleanly, not silently broken |

**Anti-pattern guard:** Don't treat the CI job as "just make the SPM path build once" — the ticket explicitly requires verifying all four rows above.

---

## Final Phase: Sign-off checklist

1. `git diff master --stat` reviewed — matches Phase 0/1/2 scope exactly, nothing extra.
2. All four build-matrix rows in Phase 5 verified with evidence (CI logs or local build output).
3. `CHANGELOG.md` and `pubspec.yaml` version bumped per Phase 3.
4. `doc/Installation.md` and `doc/PurchaseConnector.md` updated per Phase 4, explicitly stating the PurchaseConnector/SPM limitation.
5. No `.iOS("12.0")`-style invalid SwiftPM API left in `Package.swift` (`grep -n '\.iOS(\"' ios/appsflyer_sdk/Package.swift` should return nothing).
6. No duplicate source files between `ios/Classes/` (should no longer exist) and `ios/appsflyer_sdk/Sources/`.
7. Ready to open a PR against DELIVERY-125462, referencing and closing out #454/#455/#370 in the description (crediting their work, explaining why #454 was chosen as base).
