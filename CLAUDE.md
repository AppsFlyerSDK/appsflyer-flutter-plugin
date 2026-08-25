# AppsFlyer Flutter Plugin

## Overview
Flutter plugin providing mobile attribution and analytics for iOS and Android.
The core bridge uses native AppsFlyer SDK 7.0.1 on Android and 7.0.2 on iOS
(pinned by AppsFlyerRPC), Android RPC 7.0.12, and iOS AppsFlyerRPC 7.0.13. It
requires Flutter 3.35+ and Dart 3.9+. On Android the host app also needs Kotlin
Gradle Plugin 2.0.21+, AGP 8.9.1+, Gradle 8.11.1+, and JDK 17 — see
`doc/installation-guide.md`.

## Starting a feature

To start the full feature delivery workflow, use the slash command:

```
/af-ship <short description>
```

This invokes Alice, who writes a PRD, coordinates Bob and Erin if needed, and
manages Dave through tech design, implementation, and feature documentation.
Nothing else triggers the full workflow — all other requests go directly to the
relevant skill.

## Direct invocation

For everything outside of feature delivery, invoke skills directly:

| Task | Invoke |
|------|--------|
| Code question, architecture, implementation | `dave-flutter-engineer` |
| Maintenance task (see list below) | `dave-flutter-engineer` |
| Platform API research, version behavior | `bob-flutter-researcher` |
| Payload analysis, field mapping, schema review | `erin-flutter-analyst` |

## Architecture
- `lib/src/appsflyer_sdk.dart` — Main SDK class (singleton, MethodChannel/EventChannel bridge)
- `lib/src/appsflyer_event.dart` — Native RPC event envelope
- `lib/src/udl/deeplink.dart` — Unified Deep Linking (UDL) implementation
- `lib/src/purchase_connector/` — In-app purchase validation models
- `android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.kt` — Android entry point
- `android/src/main/include-connector/` — Optional Kotlin Purchase Connector bridge
- `ios/appsflyer_sdk/Sources/appsflyer_sdk/` — iOS RPC entry point (Swift)
- `ios/PurchaseConnector/` — iOS purchase validation module
- `test/` — Dart unit tests (mockito)
- `example/` — Full Flutter example app (iOS + Android)
- `doc/` — Per-feature integration guides

## Commands
```bash
flutter pub get           # Install dependencies
flutter test test         # Run Dart unit tests
flutter pub run build_runner build   # Regenerate JSON serialization code
```

## Coding Conventions
- **Linter**: `flutter_lints` with custom overrides in `analysis_options.yaml`.
  - `public_member_api_docs` is disabled — no need to add dartdoc to every member.
  - `constant_identifier_names` is disabled — follow existing naming in constants files.
  - 80-char line limit is disabled — but keep lines readable.
- **JSON serialization**: Uses `json_annotation` + `json_serializable`. After changing annotated model classes, run `build_runner` to regenerate `.g.dart` files. Commit the generated files.
- **Testing**: `mockito` for mocking. Add tests in `test/` for new public API.
- Dart null safety is required — all new code must be null-safe.
- Keep `AppsFlyerSdk.instance` as the production singleton.

## Key Patterns
- New core SDK methods must map to existing native RPC capabilities. Add the
  Dart RPC call and only platform adaptation required by the RPC contracts;
  keep business behavior in the native SDK/RPC modules.
- Native RPC callbacks flow through the `af-events` EventChannel as
  `_AppsFlyerEvent` envelopes parsed on the Dart side.
- Deep linking (UDL) logic is isolated in `lib/src/udl/` — do not mix with core SDK channel calls.
- Purchase Connector is self-contained in `lib/src/purchase_connector/` (Dart models) and `ios/PurchaseConnector/` / `android/.../kotlin/` (native).

## Testing
- Run `flutter test test` for the Dart unit test suite.
- Run `./gradlew :appsflyer_sdk:testDebugUnitTest` from `example/android` for the Android native tests. On a fresh clone, run `flutter build apk --config-only` from `example/` first: the Gradle wrapper is gitignored and is only written once the Flutter tool invokes Gradle.
- Run `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination "id=<simulator-udid>"` from `example/` for the iOS native tests.
- Integration testing requires running the `example/` app on a device/emulator.
- CI is GitHub Actions (`.github/workflows/lint-test-build.yml`): the Dart suite on Linux, plus the Android native tests inside the Android build job. The iOS XCTest suite is not run in CI — run it locally.

## Notes
- SDK version is set in `pubspec.yaml` and native dependency specs (podspec / `build.gradle`).
- Generated files (`*.g.dart`) must be committed — run `build_runner` after model changes.
- `doc/` and `example/` must be kept in sync with API changes — see Documentation review.
- The iOS core bridge is Swift only — no Objective-C. `AFRPCBridge.swift` reaches the
  `@MainActor`-isolated `AppsFlyerRPCBridge` via `MainActor.assumeIsolated`; Swift and
  Kotlin implement the optional Purchase Connector bridges.

## Documentation review

Applies to every code change, including pure refactors.

After every code change, identify and review all related documentation. Update
documentation whenever the change affects documented behavior, public APIs,
parameters, configuration, architecture, workflows, examples, compatibility, or
user-visible output. If no documentation update is needed, explicitly state which
documentation was reviewed and why it remains accurate.

Where to look, by what changed:

| Changed | Review |
|---------|--------|
| Public Dart API surface | dartdoc on the member, `doc/api-reference.md`, `README.md`, `CHANGELOG.md` |
| Platform-specific behavior or availability | `doc/api-reference.md`, the affected `internal-docs/features/F-NNN-*.md` |
| Breaking change or removed API | `doc/migration-guide.md`, `CHANGELOG.md` — see also the API Removal Rule |
| Behavior of a catalogued feature | matching `internal-docs/features/F-NNN-*.md` plus `internal-docs/features/INDEX.md` |
| Architecture, channels, or RPC transport | `internal-docs/ARCHITECTURE.md` and the Architecture section above |
| Setup, configuration, or native dependencies | `doc/installation-guide.md`, `doc/getting-started.md` |
| Anything the sample app demonstrates | `example/` and `example/README.md` |

Rules:

- Correct outdated references and examples in the files you review, including stale
  method names, signatures, return types, and snippets that no longer compile.
- Never hand-edit generated output. Regenerate it — `*.g.dart` via
  `flutter pub run build_runner build`.
- Leave accurate documentation alone. An unnecessary documentation edit is a defect.

Every task summary must state:

- which documentation files were reviewed;
- which documentation files were updated;
- if none were updated, why the existing documentation remains accurate.

## Maintenance bypass

The following do not require a PRD or Alice review — invoke Dave directly:

- Version bumps in `pubspec.yaml` and native dependency specs (`ios/*.podspec`, `android/build.gradle`)
- `CHANGELOG.md` updates
- Dependency bumps (`json_annotation`, `mockito`, `flutter_lints`, `build_runner`, etc.)
- Lint/formatting fixes
- Regenerating `*.g.dart` files via `build_runner` after model changes with no public API change
- Doc-only edits in `doc/` or `example/`
- Renames, dead-code removal, comment cleanup with no public API change

## Output contract

Every `/af-ship` deliverable must include:

- Alice PRD (`internal-docs/prds/`)
- Bob findings (if invoked)
- Erin payload impact (if invoked)
- Dave tech design (`internal-docs/tech-designs/`)
- Dave implementation + unit tests
- Dave feature doc (`internal-docs/features/`)
- Alice sign-off at each phase
