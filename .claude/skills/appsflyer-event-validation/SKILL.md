---
name: appsflyer-event-validation
description: Validate that expected AppsFlyer SDK events and callbacks were triggered during an end-to-end Flutter app scenario using logs, callback payloads, and test evidence.
---

# AppsFlyer Event Validation

Use this skill when validating whether AppsFlyer-related events actually fired during an app scenario.

## Goal

Compare expected AppsFlyer events against real evidence from logs, callbacks, or assertions.

## Workflow

1. Identify the scenario under test.
2. Define the expected AppsFlyer events or callbacks for that scenario.
3. Collect evidence from:
   - Flutter logs
   - Android logcat
   - iOS simulator logs
   - callback payloads
   - test assertions
4. Match expected events against actual evidence.
5. Classify each expected event as:
   - Confirmed triggered
   - Missing
   - Duplicate
   - Unclear
   - Blocked by environment
6. Summarize the result.

## Output Format

Return:

- Scenario
- Platform
- Expected AppsFlyer events
- Confirmed triggered events
- Missing events
- Duplicate or unexpected events
- Relevant evidence
- Final status: Passed | Failed | Inconclusive | Blocked

## Rules

- Do not assume an event fired because the app launched.
- Confirm events only from logs, callbacks, or assertions.
- If logs are insufficient, say `needs more logging`.
- Separate verified facts from assumptions.
