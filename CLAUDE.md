# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Claude Agents

This repository includes custom agents under `.claude/agents/`.

Current agents:
- `flutter-plugin-developer` — for Flutter plugin development, Dart/native bridge work, SDK version bumps, and release-related plugin changes
- `flutter-e2e-tester` — for end-to-end validation on Android emulators and iOS simulators, including AppsFlyer event verification from logs

## Claude Skills

This repository includes reusable skills under `.claude/skills/`.

Plugin development skills:
- `sdk-version-bump` — bump wrapped Android/iOS SDK versions and related plugin version metadata
- `plugin-api-change` — add or modify Flutter plugin APIs safely across Dart, Android, and iOS
- `platform-channel-debug` — debug Flutter ↔ native bridge issues
- `plugin-release` — review plugin release readiness

Quality / E2E skills:
- `appsflyer-event-validation` — verify expected AppsFlyer events and callbacks from logs and evidence
- `launch-log-analysis` — analyze app launch logs per session and compare expected vs actual AppsFlyer events
- `e2e-smoke-test` — run or review a basic emulator/simulator smoke test for plugin readiness

## Working Style

When a task matches one of the skills above, prefer using the relevant skill workflow.
When a task needs specialized reasoning, prefer the matching custom agent.
For plugin work, inspect Dart, Android, and iOS layers together before changing code.
For E2E validation, rely on logs, callback payloads, and explicit evidence rather than assumptions.

---

## Commands

### Plugin (root)
```sh
flutter pub get                          # Install dependencies
flutter analyze --no-fatal-infos --no-fatal-warnings  # Lint
dart format --set-exit-if-changed .      # Format check
flutter test                             # Run all unit tests
flutter test test/appsflyer_sdk_test.dart  # Run a single test file
flutter test --coverage                  # Run tests with coverage
```

### Example App
```sh
cd example && flutter pub get            # Install example dependencies
cd example && flutter build apk --debug  # Build Android debug APK
cd example && flutter build appbundle --release  # Build Android release bundle
cd example && flutter build ios --simulator --debug  # Build iOS for simulator
cd example && flutter build ipa --release --no-codesign  # Build iOS IPA (no signing)
```

### iOS (CocoaPods)
```sh
cd example/ios && pod install            # Install CocoaPods dependencies
cd example/ios && pod repo update        # Update pod repo before install
```

### Code generation (JSON serializable)
```sh
flutter pub run build_runner build       # Generate *.g.dart files
flutter pub run build_runner watch       # Watch mode for code gen
```

### Publish dry run
```sh
dart pub publish --dry-run               # Validate before tagging a release
```

---

## Architecture

This is an **integrated Flutter plugin** (not fully federated) wrapping the AppsFlyer native SDKs.

### Layer overview

```
lib/src/appsflyer_sdk.dart          ← Dart API (AppsflyerSdk singleton)
        ↓ MethodChannel / EventChannel
android/src/main/java/…/AppsflyerSdkPlugin.java   ← Android bridge (Java)
ios/Classes/AppsflyerSdkPlugin.m                   ← iOS bridge (Objective-C)
```

### Platform channels

Defined in `lib/src/appsflyer_constants.dart`:
- `af-api` — main method channel for all SDK API calls
- `af-events` — event stream channel
- `callbacks` — callback delivery channel
- `af-purchase-connector` — purchase validation channel

### Purchase Connector (conditional)

Android includes the Purchase Connector only when the Gradle property `appsflyer.enable_purchase_connector=true` is set. Source sets are split between `src/main/include-connector/` and `src/main/exlude-connector/` (note: "exlude" is the existing spelling in the repo).

iOS Purchase Connector is in `ios/PurchaseConnector/PurchaseConnectorPlugin.swift`.

### Key version files

When bumping SDK or plugin versions, these files must stay in sync:
- `pubspec.yaml` — plugin version + Dart SDK constraints
- `android/build.gradle` — `com.appsflyer:af-android-sdk` version + `com.appsflyer:purchase-connector` version
- `ios/appsflyer_sdk.podspec` — `AppsFlyerFramework` version + Purchase Connector version
- `CHANGELOG.md` — top entry must match `pubspec.yaml` version
- `README.md` — SDK version table at the top

### SDK targets
- Android: minSdk 19, compileSdk 35, Java/Kotlin 17
- iOS: deployment target 12.0

### CI/CD
Workflows in `.github/workflows/`:
- `ci.yml` — runs on PRs/pushes to `development`/`master`: lint → format → unit tests → Android APK build → iOS simulator build
- `rc-release.yml` / `production-release.yml` / `promote-release.yml` — release pipeline stages

### Versioning
Follow semantic versioning. Bump **MAJOR** for breaking Dart or native API changes. Git tags must match `pubspec.yaml` version (`vX.Y.Z`).
