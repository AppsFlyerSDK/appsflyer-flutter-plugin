---
name: plugin-release
description: Review the AppsFlyer Flutter plugin for release readiness, including versioning, changelog, Android/iOS parity, validation coverage, and integration safety.
---

# Plugin Release

Use this skill before releasing a new version of the AppsFlyer Flutter plugin.

## Goal

Check whether the plugin is safe and ready for release.

## Workflow

1. Inspect the change set or current release candidate.
2. Identify:
   - plugin version changes
   - Android SDK version changes
   - iOS SDK version changes
   - Dart API changes
   - example app changes
3. Review release readiness:
   - version consistency
   - changelog presence
   - compatibility risks
   - Android/iOS parity
   - missing validation
4. Check whether new behavior requires release notes or migration guidance.
5. Summarize release blockers and non-blockers.

## What to Check

- `pubspec.yaml`
- changelog/release notes
- Android dependency declarations
- iOS dependency declarations
- public Dart API changes
- example app compatibility
- E2E or smoke test relevance
- backward compatibility risk

## Output Format

Return:
- Release summary
- Risk level: Low | Medium | High | Critical
- Blocking issues
- Non-blocking issues
- Missing validations
- Recommended release decision

## Rules

- Do not approve a release if versioning is inconsistent.
- Explicitly call out Dart/API compatibility risk.
- Explicitly call out Android/iOS behavior drift.
- If release evidence is incomplete, say what still must be verified.
- Prefer concrete release blockers over generic advice.
