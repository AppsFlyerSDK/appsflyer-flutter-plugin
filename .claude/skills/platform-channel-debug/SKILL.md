---
name: platform-channel-debug
description: Debug communication issues between Flutter Dart code and native Android/iOS implementations in the AppsFlyer Flutter plugin.
---

# Platform Channel Debug

Use this skill when a Flutter-to-native or native-to-Flutter flow is not working correctly.

## Goal

Find where the bridge is broken between Dart, platform channel wiring, and native SDK integration.

## Workflow

1. Identify the failing flow:
   - Dart -> native method call
   - native -> Dart callback
   - event channel stream
   - initialization/registration issue

2. Trace the path end-to-end:
   - Dart caller
   - channel name
   - method/event name
   - Android handler
   - iOS handler
   - native SDK callback if relevant

3. Verify argument and payload mapping.

4. Check for mismatches:
   - channel names
   - method names
   - argument keys
   - null handling
   - serialization types
   - callback thread assumptions

5. Identify the first broken point in the chain.

6. Recommend the smallest safe fix.

## What to Check

- Dart method call or listener registration
- MethodChannel/EventChannel setup
- Android plugin registration and handler mapping
- iOS plugin registration and handler mapping
- callback/event propagation back to Dart
- log statements or existing debug hooks
- example app path that reproduces the issue

## Output Format

Return:
- Failing scenario
- Expected flow
- Actual break point
- Evidence
- Suspected root cause
- Recommended fix
- Validation steps

## Rules

- Do not say the issue is in native SDK behavior unless the bridge has been verified first.
- Prefer tracing the real execution path over guessing.
- Separate confirmed breakage from hypotheses.
- If evidence is incomplete, say `needs verification`.
