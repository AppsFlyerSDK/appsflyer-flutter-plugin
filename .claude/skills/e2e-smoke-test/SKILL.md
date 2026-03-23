---
name: e2e-smoke-test
description: Run or review a basic end-to-end smoke test for the AppsFlyer Flutter plugin on emulator or simulator, covering startup, initialization, and basic event flow.
---

# E2E Smoke Test

Use this skill for quick validation that the Flutter plugin is basically working after a change.

## Goal

Check that the plugin still works end-to-end at a basic level after code, SDK, or version changes.

## Workflow

1. Identify the target platform:
   - Android emulator
   - iOS simulator
   - both
2. Verify the scenario setup:
   - test app or example app
   - required config values
   - emulator/simulator available
3. Run or inspect the basic smoke scenario:
   - app launch
   - SDK init/start
   - one basic AppsFlyer event
   - callback flow if relevant
4. Collect evidence:
   - logs
   - callback payloads
   - test results
5. Report whether the flow passed or failed.

## Output Format

Return:

- Scenario
- Platform
- Steps
- Expected behavior
- Actual behavior
- Evidence
- Status: Passed | Failed | Blocked
- Follow-up recommendation

## Rules

- Keep this focused on basic release confidence.
- Do not expand into a full regression suite unless asked.
- If a key part cannot be tested locally, say so clearly.
