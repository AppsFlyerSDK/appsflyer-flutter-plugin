---
name: sdk-version-bump
description: Safely bump the wrapped Android SDK or iOS SDK version in the AppsFlyer Flutter plugin, update the plugin version if needed, and validate all related files.
---

# SDK Version Bump

Use this skill when updating the native Android or iOS SDK version wrapped by the AppsFlyer Flutter plugin.

## Goal

Perform a safe, consistent version bump across Dart, Android, and iOS plugin layers.

## Workflow

1. Identify which SDK is being bumped:
   - Android SDK
   - iOS SDK
   - both

2. Locate current versions in the repository:
   - `pubspec.yaml`
   - Android Gradle files
   - iOS podspec / pod dependency files
   - example app config if relevant
   - changelog / release files

3. Update the native SDK version in all required places.

4. Decide whether the Flutter plugin version must also be bumped.
   - If behavior or wrapped SDK version is changing, check plugin versioning expectations.
   - If unclear, say `needs verification`.

5. Check whether changelog or release notes must be updated.

6. Verify the example app and integration surfaces still reference valid versions.

7. Summarize:
   - old version
   - new version
   - files changed
   - compatibility or release risk
   - validation steps still recommended

## What to Check

### Android
- Gradle dependency declarations
- version constants
- Maven coordinates
- wrapper code impacted by Android SDK changes

### iOS
- podspec
- Pod dependency declarations
- iOS wrapper/bridge references
- any version constants or release metadata

### Flutter plugin
- `pubspec.yaml`
- plugin version
- changelog
- example app compatibility

## Output Format

Return:
- Summary
- SDK bumped: Android | iOS | Both
- Previous version
- New version
- Files updated
- Plugin version impact
- Changelog impact
- Validation steps
- Compatibility risk

## Rules

- Do not update only one place if multiple version declarations exist.
- Do not guess the plugin versioning rule if it is not obvious.
- Call out any place that may still need manual release verification.
- Prefer a minimal and consistent change set.
