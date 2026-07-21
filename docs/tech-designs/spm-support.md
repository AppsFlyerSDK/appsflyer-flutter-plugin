---
ticket: DELIVERY-125462
prd: docs/prds/spm-support.md
research: docs/researches/R-001-spm-support.md
planned_feature_doc: F-060 — doc to be written after development is complete
---

# Tech Design: Swift Package Manager (SPM) Support

## Context table

| Type | ID | Name |
|------|----|------|
| Issue case | none | `docs/issue-cases/` does not exist in this repo yet — no hot-zone history to check |
| Feature doc | F-054 | Purchase Connector: Build-Time Opt-in — directly extended by this design |

## Approach

Move (not mirror) `ios/Classes/` into an SPM-compatible tree shared by both CocoaPods and SPM, following the official Flutter plugin-author SPM migration guide exactly (verified directly at https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors — not just copied from the draft PRs):

```
ios/
├── appsflyer_sdk/                                          # NEW — SPM package root
│   ├── Package.swift                                       # NEW — SPM manifest
│   └── Sources/appsflyer_sdk/
│       ├── AppsflyerSdkPlugin.m                             # moved from ios/Classes/
│       ├── AppsFlyerAttribution.m                           # moved
│       ├── AppsFlyerStreamHandler.m                         # moved
│       └── include/appsflyer_sdk/
│           ├── AppsflyerSdkPlugin.h                         # moved (public header)
│           ├── AppsFlyerAttribution.h
│           ├── AppsFlyerStreamHandler.h
│           └── FlutterAppDelegate+AppsFlyerStreamHandler.h
├── appsflyer_sdk.podspec                                    # UPDATED — source_files/public_header_files repointed
├── .gitignore                                                # UPDATED — add .build/ and .swiftpm/
└── PurchaseConnector/                                        # UNCHANGED — stays CocoaPods-only, untouched
```

`ios/.gitignore` must add `.build/` and `.swiftpm/` per the official migration guide's checklist (step 10) — these are local SPM resolution/build artifacts that must not be committed, same rationale as `.dart_tool/`/`build/` already being ignored at the Dart level.

This matches draft PR #454's structure (not #455's mirror-based duplication), which the official guide independently confirms is the correct approach: the guide's own migration checklist deletes `ios/Classes/` entirely after moving — there is exactly one copy of Core's source, referenced by both the podspec (CocoaPods path) and `Package.swift` (SPM path). `pubspec.yaml` requires **no changes** — `pluginClass: AppsflyerSdkPlugin` continues to resolve via `<appsflyer_sdk/AppsflyerSdkPlugin.h>` in the new location, per the guide.

### `ios/appsflyer_sdk/Package.swift`

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "appsflyer_sdk",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "appsflyer-sdk", targets: ["appsflyer_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git", .exact("6.18.0"))
    ],
    targets: [
        .target(
            name: "appsflyer_sdk",
            dependencies: [
                .product(name: "AppsFlyerLib", package: "AppsFlyerFramework")
            ],
            cSettings: [
                .headerSearchPath("include/appsflyer_sdk")
            ]
        )
    ]
)
```

**Correction to draft PR #454**: its PR description names the dependency product `AppsFlyerLib-Static`. I fetched `AppsFlyerFramework`'s actual `Package.swift` at tag `6.18.0` directly via GitHub API — the declared product name is `AppsFlyerLib`, not `AppsFlyerLib-Static` (that string only appears in the *binary artifact's zip filename*, not the SPM product). Using the wrong product name would fail dependency resolution outright. Pin `.exact("6.18.0")` to match the podspec's existing `ss.ios.dependency 'AppsFlyerFramework','6.18.0'` exactly — no native SDK version bump required (R-001 confirmed the 6.18.0 tag's own Package.swift resolves and is valid).

**Correction (post-review)**: the original design used `from: "6.18.0"`, a semver-range requirement (`6.18.0..<7.0.0`) rather than an exact pin. This was caught during PR review — the CI E2E run cited in the PR's test plan actually resolved and ran against `AppsFlyerFramework` **6.18.1**, not 6.18.0, exposing a real asymmetry: CocoaPods consumers get exactly 6.18.0, SPM consumers could silently float onto any untested patch/minor release below 7.0.0. Changed to `.exact("6.18.0")` so both distribution paths pin identically. Re-verified via `swift package describe`: `Requirement: Exact: 6.18.0`.

### `ios/appsflyer_sdk.podspec` — path updates only, no marker needed

Per the official guide, **no special marker or flag is needed in the podspec to declare SPM availability** — the Flutter tool detects SPM support purely by the presence of `ios/appsflyer_sdk/Package.swift` at the conventional path. The podspec only needs its `Core` subspec's paths repointed to the moved files:

```ruby
s.subspec 'Core' do |ss|
  ss.source_files = 'appsflyer_sdk/Sources/appsflyer_sdk/**/*.m'
  ss.public_header_files = 'appsflyer_sdk/Sources/appsflyer_sdk/include/appsflyer_sdk/*.h'
  ss.dependency 'Flutter'
  ss.ios.dependency 'AppsFlyerFramework','6.18.0'
end
```

`PurchaseConnector` subspec is untouched — its `source_files = 'PurchaseConnector/**/*'` still points at the existing, unmoved directory.

## PurchaseConnector isolation — corrected failure-mode analysis

R-001 hypothesized that referencing Purchase Connector APIs from an SPM-only integration would fail as a **build/link error** (an improvement over F-054's documented silent-runtime `MissingPluginException`). Tracing the actual mechanism, **this hypothesis is wrong** — the real behavior is identical to today's CocoaPods opt-out path, not better:

- `ios/PurchaseConnector/` is never added to the SPM target's `Sources/` tree — it's a completely separate directory the `Package.swift` above never references.
- The existing `#ifdef ENABLE_PURCHASE_CONNECTOR` guard in `AppsflyerSdkPlugin.m` (moved, unmodified) depends on the `ENABLE_PURCHASE_CONNECTOR=1` preprocessor macro, which today is set only via the podspec's `pod_target_xcconfig` on the `PurchaseConnector` subspec (a CocoaPods-only mechanism — SPM has no equivalent `xcconfig` macro injection path in this design).
- Therefore in an SPM-only build, that macro is simply never defined — the guard resolves to false exactly as it does today for a CocoaPods app that didn't opt in.
- Net effect: an app integrated via SPM that calls a Purchase Connector Dart API gets the **same outcome as today's undocumented CocoaPods opt-out** — the `af-purchase-connector` MethodChannel has no registered handler, and Flutter raises its own `MissingPluginException` at runtime, not at build time. This is not an improvement; it is the same known limitation F-054 already documents, now reachable via a third path.

**Decision**: accept this as the same known-limitation behavior, not attempt to introduce a build-time guard for this release. Rationale: making PurchaseConnector fail differently (e.g., a Swift `#error` directive) would require adding conditional logic that reads consuming-app config *inside* the Package.swift/SPM target — which is precisely what flutter/flutter#161182 says SPM cannot yet do for Flutter plugins. Manufacturing a compile-time signal is out of scope until that's resolved; this PRD's non-goal (no SPM Purchase Connector this release) already excludes it. Flag for Phase 3: F-054's Known Limitations section needs a new bullet noting this is now reachable via SPM too, not just the two existing CocoaPods/Gradle paths — and R-001's speculative "improvement" claim should not be repeated in the final feature doc.

## Migration & rollout risk

- **No opt-in required, no behavior change for existing users.** CocoaPods apps continue to resolve via the podspec exactly as before — same subspecs, same dependency versions, only the on-disk source location changed (transparent to consumers, who never reference `ios/Classes/` paths directly).
- **Public API surface**: unchanged. No new Dart methods, no MethodChannel changes. This is purely an iOS build/distribution-mechanism addition.
- **Rollback plan**: if a regression surfaces post-release, revert the file move + podspec path change + delete `Package.swift`; CocoaPods consumers are unaffected either way since the podspec keeps working throughout development (verified per-build-path below, not assumed).
- **Big-bang vs gradual**: this ships in v6.18.0 as a single release; SPM adoption itself is gradual and consumer-controlled (Flutter's own `--enable-swift-package-manager` flag / 3.44+ default) — we're not forcing anyone onto SPM, only making it available.

## Concurrency & Thread Safety

**N/A for this change.** No runtime or concurrent code path is touched — the `.m`/`.h` files are relocated verbatim (`git mv`, no content changes to the moved implementation), and the only new artifacts (`Package.swift`, podspec path updates, `.gitignore`) are build-time manifests with no executable logic, threading, or callback/completion-handler code of their own.

## Test Coverage

**No automated unit test is added.** This falls in the same category as F-054 (Purchase Connector: Build-Time Opt-in), which is explicitly documented as untested at the unit level because "this is a Gradle/CocoaPods build-configuration concern with no Dart or native unit test coverage; verifying it requires two full builds (opted-in vs. opted-out) rather than a unit test." The same reasoning applies here: there is no Dart or native runtime logic change to unit-test — only source-tree layout and build manifests. The Verification plan below (4 real build-path checks) is the equivalent verification for this category of change, not a substitute being skipped.

## Verification plan (mandatory — neither draft PR completed this)

Both #454 and #455 self-report only local/simulator builds and explicitly ask reviewers to verify before merging. This design requires actually running all three supported build paths from the PRD's acceptance criteria before shipping, using `example/`:

1. **SPM, Core only** — `flutter config --enable-swift-package-manager && cd example && flutter clean && flutter build ios --no-codesign`. Confirm init/start/event-logging Dart APIs reach the native layer (existing `example/` app coverage).
2. **CocoaPods, Core only** (`$AppsFlyerPurchaseConnector` unset) — `flutter config --no-enable-swift-package-manager && cd example && flutter clean && pod install && flutter build ios --no-codesign`. Confirm behavior is bit-for-bit identical to pre-change (regression check).
3. **CocoaPods, Core + PurchaseConnector** (`$AppsFlyerPurchaseConnector = true` in `example/ios/Podfile`) — same as above with the flag set. Confirm Purchase Connector channel still registers and responds.
4. **Explicitly not required this release**: SPM + PurchaseConnector — confirm it's genuinely absent/inert per the corrected failure-mode analysis above (attempt calling a Purchase Connector API from an SPM-only build and confirm it raises `MissingPluginException`, matching the documented limitation rather than crashing or hanging).

All four must be run on a real device build, not just `--no-codesign`, before Alice's implementation review is requested — `--no-codesign` only proves compilation succeeds, not that the native SDK initializes and channels respond.

## Documentation impact (flag only — action in Phase 3)

- **F-054** (`docs/features/F-054-purchase-connector-build-time-opt-in.md`): add SPM as a third gating path in its Call Chain/Files sections, and add the corrected failure-mode bullet to Known Limitations (see above) once implementation lands.
- **F-060** (new): this feature's own catalog entry, written in Phase 3 from the real implemented code — supersedes the placeholder discussion from earlier in this session; do not reuse any earlier draft.
- `CHANGELOG.md` and release notes (PRD requirement 5): document SPM support added for Core, PurchaseConnector's continued CocoaPods-only status, and link flutter/flutter#161182 for apps tracking when that might change.

## Open questions resolved by this design

- Package.swift path: confirmed `ios/appsflyer_sdk/Package.swift` against the official Flutter guide (not just the drafts) — correct.
- podspec marker: none needed — presence of `Package.swift` at the conventional path is the only signal Flutter tooling requires.
- Compile-time signal for Purchase Connector-without-CocoaPods: corrected from R-001's hypothesis — it's the same runtime `MissingPluginException` as today's CocoaPods opt-out, not a build-time error. Accepted as an existing known limitation, not a regression.
