---
name: plugin-api-change
description: Safely implement or modify a Flutter plugin API in the AppsFlyer Flutter plugin, including Dart API, platform channel mapping, Android wrapper, and iOS wrapper changes.
---

# Plugin API Change

Use this skill when adding, removing, or changing a Flutter plugin API.

## Goal

Make a safe API change across all plugin layers while preserving backward compatibility where possible.

## Workflow

1. Identify the public Dart API being changed.
2. Trace the full path:
   - Dart API
   - method/event channel
   - Android implementation
   - iOS implementation
3. Verify whether the API already exists in some form.
4. Check whether the change affects:
   - method names
   - argument mapping
   - callback behavior
   - event payload shape
   - Android/iOS parity
5. Implement or review changes in all required layers.
6. Check whether tests or example app code must be updated.
7. Summarize compatibility risk and missing validation.

## What to Check

### Dart layer
- public method signature
- null safety
- parameter validation
- returned types / Future / Stream behavior
- deprecation or compatibility strategy

### Platform channel
- method names
- event names
- argument serialization
- error mapping
- callback/event delivery

### Android
- plugin registration
- native method handling
- mapping to AppsFlyer Android SDK
- threading / lifecycle safety

### iOS
- plugin registration
- native method handling
- mapping to AppsFlyer iOS SDK
- callback/delegate behavior

## Output Format

Return:
- Summary
- Dart API impact
- Android impact
- iOS impact
- Compatibility risk
- Tests to add or update
- Example app impact
- Validation steps

## Rules

- Keep Android and iOS behavior aligned unless a platform difference is intentional.
- Do not silently break the public Dart API.
- If a behavior change is unavoidable, call it out explicitly.
- Do not stop at Dart-only changes if native work is required.
