# AppsFlyer Flutter Plugin

## Overview
Flutter plugin providing mobile attribution and analytics for iOS and Android. Bridges native AppsFlyer SDKs (iOS v6.17.9, Android v6.17.6) via Dart MethodChannel/EventChannel. Supports Flutter 2+ with null safety.

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
- `lib/src/callbacks.dart` — Attribution and event callback handlers
- `lib/src/udl/deeplink.dart` — Unified Deep Linking (UDL) implementation
- `lib/src/purchase_connector/` — In-app purchase validation models
- `android/src/main/java/com/appsflyer/appsflyersdk/AppsflyerSdkPlugin.java` — Android entry point
- `android/src/main/kotlin/` — Kotlin Purchase Connector for Android
- `ios/Classes/AppsflyerSdkPlugin.m` — iOS entry point (Objective-C)
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
- Keep `AppsflyerSdk` as a singleton; do not change the instantiation pattern.

## Key Patterns
- New SDK method: add Dart method in `appsflyer_sdk.dart` (invoke via `_channel.invokeMethod`), implement in `AppsflyerSdkPlugin.java` (Android) and `AppsflyerSdkPlugin.m` (iOS). Keep method name strings consistent across all three files.
- Callbacks from native → Dart flow through EventChannels defined in `callbacks.dart`.
- Deep linking (UDL) logic is isolated in `lib/src/udl/` — do not mix with core SDK channel calls.
- Purchase Connector is self-contained in `lib/src/purchase_connector/` (Dart models) and `ios/PurchaseConnector/` / `android/.../kotlin/` (native).

## Testing
- Run `flutter test test` for the Dart unit test suite.
- Integration testing requires running the `example/` app on a device/emulator.
- CI uses Travis CI (`.travis.yml`) on Linux with Flutter stable.

## Notes
- SDK version is set in `pubspec.yaml` and native dependency specs (podspec / `build.gradle`).
- Generated files (`*.g.dart`) must be committed — run `build_runner` after model changes.
- `doc/` and `example/` should be kept in sync with API changes.
- iOS native layer is Objective-C; Kotlin is used only for the Android Purchase Connector.

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
