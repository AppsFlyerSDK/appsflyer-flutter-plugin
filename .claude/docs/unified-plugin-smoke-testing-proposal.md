# Unified plugin smoke testing: automation-first approach

**Author:** Dani Ko  
**Date:** April 2026  
**Related:** [Unified automation for Plugins research](https://www.notion.so/appsflyerrnd/Unified-automation-for-Plugins-research-335b7b13af5f8082a356ef4799d02871) (senior dev proposal)  
**Status:** Draft / Discussion

---

## Problem

AppsFlyer has multiple SDK plugins (Flutter, React Native, Cordova, Capacitor, Unity, etc.), each with its own test app, build tooling, and CI setup. Release smoke testing is manual, inconsistent, and hard to scale. Teams have no shared definition of "smoke passed" and no portable way to execute and verify smoke tests across plugins.

The senior dev's research document proposes a companion tooling repository with shared smoke contracts and Cursor Skill templates. This document **extends** that proposal with a concrete **automation-first** layer: portable bash scripts, machine-readable test definitions, and structured log validation that any developer or AI agent can run; not tied to a single IDE or agent tool.

---

## Alignment with senior dev proposal

This proposal **aligns** with the companion tooling repo (#1) approach and adds a concrete execution layer on top. The senior dev's proposal provides the "what" (contracts, templates, governance); this proposal provides the "how" (scripts, schemas, log parsing, structured output).

### Where this proposal builds on top

| Senior dev proposal | This proposal adds |
|---|---|
| Smoke test contract (normative docs with scenario IDs) | Machine-readable test plan JSON schema consumed by scripts and agents |
| Optional helper scripts (emulator lifecycle, log capture) | Complete `af-smoke-runner.sh` script: install, launch, collect, validate, report |
| Cursor Skill templates as delivery mechanism | Agent-agnostic design; scripts work with Cursor, Claude Code, Windsurf, GitHub Copilot, or bare terminal |
| Generic test-app behavioral contract | Concrete unified test app spec: standardized package names, `.env` config, `[AF_QA]` log prefix, auto-run flows |
| Multi-root workspace workflow for template instantiation | Single `af-smoke-runner.sh` entry point that any tool can invoke |

### Where this proposal suggests improvements

These are explicit callouts where the senior dev's proposal could be strengthened. **None of these modify the Notion document**; they are recommendations for discussion.

**1. Agent-agnostic execution (not Cursor-only)**  
The senior dev's proposal makes Cursor Skill templates the "preferred" and "default" delivery mechanism. This creates a hard dependency on one IDE. Not every team member or CI environment uses Cursor. This proposal recommends that the **primary automation artifact** be a portable bash script. Cursor Skills, Claude Code skills, or any other agent wrapper can call that script, but the script itself must run anywhere bash + ADB/xcrun are available.

**2. Machine-readable test definitions, not just prose**  
The smoke contract in the senior dev's proposal is described as "readable specs" with optional traceability IDs. That's good for humans but hard for automation to consume. This proposal adds a **JSON test plan schema** that both scripts and AI agents parse directly. The schema defines phases, checks, expected log patterns, pass/fail criteria, and failure actions; all machine-readable.

**3. Concrete log validation, not just "failure signals"**  
The senior dev's proposal mentions "failure signals (what logs or artifacts indicate a regression)" but leaves the actual parsing to each plugin. This proposal standardizes on:
- A `[AF_QA]` log prefix convention across all plugins
- `grep`-based pattern matching built into the runner script
- Structured JSON output with per-check pass/fail/evidence
- HTTP 200 response code validation from native SDK logs

**4. Unified test app contract with teeth**  
The senior dev's proposal describes a "generic test-app contract" that is deliberately abstract. This proposal adds concrete requirements:
- Standardized package name convention: `com.appsflyer.qa.<plugin-name>`
- Standardized `.env` file with `DEV_KEY` and `APP_ID`
- Auto-run flow on launch: init SDK, call pre/post-start APIs, fire standard events, log everything with `[AF_QA]`
- Deep link URL scheme: `afqa-<plugin-name>://deeplink`

**5. Single entry-point script replaces "choose your own adventure"**  
The senior dev's proposal says plugins "own execution" and "integrate helpers however fits." This flexibility is good for adoption but bad for consistency. This proposal provides a single `af-smoke-runner.sh` that handles the full lifecycle: uninstall, install, launch, wait, collect logs, validate checks, produce a JSON report. Plugins only need to supply a config file with their package name, paths, and platform details.

**6. iOS log collection strategy**  
The senior dev's proposal doesn't address the iOS simulator log problem (logs are hard to filter and don't contain HTTP payloads). This proposal uses a dual strategy: `xcrun simctl spawn ... log show` for real-time capture, plus reading the app's `Documents/af_qa_logs.txt` file written by the `AfDemoLogger` class directly from the simulator's filesystem.

---

## Architecture

```
appsflyer-mobile-plugin-tooling/          (companion repo)
├── contracts/
│   ├── smoke-test-contract.md            (normative: what smoke means)
│   └── test-app-contract.md              (normative: how test apps behave)
├── schemas/
│   └── smoke-test-plan.schema.json       (JSON schema for test plans)
├── scripts/
│   ├── af-smoke-runner.sh                (main entry point)
│   ├── lib/
│   │   ├── android.sh                    (ADB helpers)
│   │   ├── ios.sh                        (xcrun simctl helpers)
│   │   ├── log-parser.sh                 (grep-based log validation)
│   │   └── report.sh                     (JSON report generation)
│   └── README.md
├── templates/
│   ├── cursor-skills/                    (Cursor Skill templates, per senior dev proposal)
│   ├── claude-skills/                    (Claude Code skill templates)
│   └── agent-generic/                    (agent-agnostic prompt templates)
└── docs/
    ├── smoke-scenarios/
    │   ├── SMOKE-001-cold-launch.md
    │   ├── SMOKE-002-bg-deeplink.md
    │   └── SMOKE-003-fg-deeplink.md
    └── troubleshooting.md

each-plugin-repo/
├── .af-smoke/
│   ├── config.json                       (plugin-specific: package name, paths, etc.)
│   └── test-plan.json                    (plugin-specific test plan, extends schema)
├── .cursor/skills/                       (Cursor Skills, instantiated from templates)
├── .claude/skills/                       (Claude Code skills, instantiated from templates)
└── example/                              (test app following the test-app contract)
```

---

## Unified test app contract (concrete)

Every plugin's test/example app must follow these rules so the smoke runner can operate identically across all plugins.

### Package naming

| Platform | Convention | Example (Flutter) |
|---|---|---|
| Android | `com.appsflyer.qa.<plugin>` | `com.appsflyer.qa.flutter` |
| iOS | `com.appsflyer.qa.<plugin>` | `com.appsflyer.qa.flutter` |

### Configuration

All test apps load credentials from a `.env` file (or platform equivalent) with these keys:

```
DEV_KEY=<appsflyer-dev-key>
APP_ID=<ios-app-store-id>
```

For QA environments, teams share a known dev key and app ID so results are comparable.

### Log prefix convention

All test apps **must** tag every SDK-related log line with the `[AF_QA]` prefix. Structured format:

```
[AF_QA][<method>] <message>
[AF_QA][CALLBACK][<callbackName>] received: <payload>
```

This makes log filtering trivial: `grep "AF_QA"` gives you everything the smoke runner needs.

### Auto-run flow

On launch, without any user interaction, the test app must:

1. Initialize the SDK with `manualStart: true`
2. Register all three callback listeners (conversion data, attribution, deep linking)
3. Call all platform-appropriate pre-start APIs
4. Call `startSDK`
5. On success: call all post-start APIs, fire three standard events:
   - `af_demo_launch` (platform info)
   - `af_purchase` (standard e-commerce event)
   - `af_content_view` (standard content event)
6. Log every API call, result, callback, and error with `[AF_QA]` prefix

### Deep link URL scheme

```
afqa-<plugin-name>://deeplink?deep_link_value=<value>&af_sub1=<test_tag>&pid=testmedia&c=deeplink_test
```

### iOS log file

On iOS, test apps must write all `[AF_QA]` logs to `Documents/af_qa_logs.txt` (appendable) so the smoke runner can read them from the simulator's host filesystem without relying on `log show` filtering.

---

## Machine-readable test plan schema

Each plugin provides a `.af-smoke/test-plan.json` that the runner script consumes. Key structure:

```json
{
  "_meta": {
    "plan_id": "flutter-smoke",
    "plugin": "flutter",
    "version": "1.0.0",
    "platforms": ["android", "ios"]
  },
  "config": {
    "android": {
      "package_name": "com.appsflyer.qa.flutter",
      "activity": ".MainActivity",
      "apk_path": "example/build/app/outputs/flutter-apk/app-debug.apk",
      "build_cmd": "cd example && flutter build apk --debug"
    },
    "ios": {
      "bundle_id": "com.appsflyer.qa.flutter",
      "app_path": "example/build/ios/iphonesimulator/Runner.app",
      "build_cmd": "cd example && flutter build ios --simulator --debug"
    }
  },
  "phases": [
    {
      "id": "phase_1",
      "name": "Cold launch smoke",
      "scenario_ref": "SMOKE-001",
      "requires_fresh_install": true,
      "wait_after_launch_sec": 25,
      "checks": [
        {
          "id": "sdk_started",
          "description": "startSDK returns SUCCESS",
          "type": "log_contains",
          "pattern": "[AF_QA][startSDK] result: SUCCESS",
          "fail_action": "abort"
        },
        {
          "id": "is_first_launch_true",
          "description": "onInstallConversionData fires with is_first_launch=true",
          "type": "log_contains",
          "pattern": "[AF_QA][CALLBACK][onInstallConversionData]",
          "payload_check": {"field": "is_first_launch", "expected": "true"},
          "fail_action": "abort"
        },
        {
          "id": "event_af_demo_launch",
          "description": "af_demo_launch event fires",
          "type": "log_contains",
          "pattern": "[AF_QA][logEvent(af_demo_launch)]",
          "fail_action": "fail"
        },
        {
          "id": "http_200_count",
          "description": "At least 3 HTTP 200 responses",
          "type": "count_matches",
          "pattern": "response code:200 OK|response_status=200",
          "minimum": 3,
          "fail_action": "fail"
        },
        {
          "id": "no_fatal_errors",
          "description": "No fatal exceptions in logs",
          "type": "absent",
          "patterns": ["Fatal Exception", "FATAL", "[AF_QA][startSDK] error:"],
          "fail_action": "fail"
        }
      ]
    },
    {
      "id": "phase_2",
      "name": "Background deep link",
      "scenario_ref": "SMOKE-002",
      "requires_fresh_install": false,
      "deep_link_url": "afqa-flutter://deeplink?deep_link_value=qa_deeplink_bg&af_sub1=background_test&pid=testmedia&c=deeplink_test",
      "pre_actions": {
        "android": ["adb shell input keyevent KEYCODE_HOME", "sleep 2"],
        "ios": ["xcrun simctl launch {{UDID}} com.apple.mobilesafari", "sleep 2"]
      },
      "trigger": {
        "android": "adb shell am start -a android.intent.action.VIEW -d \"{{DEEP_LINK_URL}}\"",
        "ios": "xcrun simctl openurl {{UDID}} \"{{DEEP_LINK_URL}}\""
      },
      "wait_after_trigger_sec": 5,
      "checks": [
        {
          "id": "deeplink_found",
          "description": "onDeepLinking fires with Status.FOUND",
          "type": "log_contains",
          "pattern": "[AF_QA][CALLBACK][onDeepLinking] received: status=Status.FOUND",
          "fail_action": "fail"
        },
        {
          "id": "deeplink_value",
          "description": "deepLinkValue matches expected",
          "type": "log_contains",
          "pattern": "deepLinkValue=qa_deeplink_bg",
          "fail_action": "fail"
        }
      ]
    }
  ],
  "report": {
    "output_dir": ".af-smoke/reports/",
    "format": "json"
  }
}
```

---

## The smoke runner script

`af-smoke-runner.sh` is the single entry point. It reads the plugin's `test-plan.json` and does everything:

### Usage

```bash
# Run all phases on Android
./af-smoke-runner.sh --platform android --plan .af-smoke/test-plan.json

# Run all phases on iOS (auto-detects booted simulator)
./af-smoke-runner.sh --platform ios --plan .af-smoke/test-plan.json

# Run a specific phase only
./af-smoke-runner.sh --platform android --plan .af-smoke/test-plan.json --phase phase_1

# Dry run (show what would happen)
./af-smoke-runner.sh --platform android --plan .af-smoke/test-plan.json --dry-run
```

### What it does (per phase)

1. **Uninstall** the app (fresh install phases only)
2. **Clear** platform logs (ADB logcat -c / equivalent)
3. **Install** the app from the configured path
4. **Launch** the app
5. **Wait** for SDK to settle (configurable per phase)
6. **Execute pre-actions** (deep link phases: background the app, etc.)
7. **Trigger** deep links if applicable
8. **Wait** for trigger to propagate
9. **Collect logs** (ADB logcat / iOS log file / xcrun simctl log)
10. **Validate** each check against collected logs
11. **Produce** a JSON report

### Output

```json
{
  "run_id": "flutter-smoke-2026-04-15T14:30:00Z",
  "platform": "android",
  "device": "emulator-5554",
  "plan_id": "flutter-smoke",
  "overall_status": "PASS",
  "phases": [
    {
      "phase_id": "phase_1",
      "status": "PASS",
      "checks": {
        "sdk_started": {"status": "PASS", "evidence": "[AF_QA][startSDK] result: SUCCESS — SDK started"},
        "is_first_launch_true": {"status": "PASS", "evidence": "...is_first_launch: true..."},
        "event_af_demo_launch": {"status": "PASS", "evidence": "[AF_QA][logEvent(af_demo_launch)] result: true"},
        "http_200_count": {"status": "PASS", "evidence": "Found 5 HTTP 200 responses (minimum: 3)"},
        "no_fatal_errors": {"status": "PASS", "evidence": "No forbidden patterns found"}
      },
      "log_file": ".af-smoke/reports/phase_1_android_logs.txt"
    }
  ],
  "duration_sec": 47
}
```

This JSON is what any AI agent or human reads to determine pass/fail. No ambiguity.

---

## How different AI agents consume this

The automation is **agent-agnostic**. The script is the source of truth; agents are wrappers.

### Cursor (Skills)

```
.cursor/skills/smoke-runner/SKILL.md
```
The Skill instructs the Cursor agent to run `af-smoke-runner.sh`, read the JSON report, and summarize results.

### Claude Code (Skills)

```
.claude/skills/smoke-runner/SKILL.md
```
Same structure: skill reads the test plan, invokes the script, parses the report.

### GitHub Copilot / Windsurf / any LLM agent

Prompt template (stored in `templates/agent-generic/smoke-prompt.md`):

```
You are validating an AppsFlyer plugin release. Run the smoke test script:

  ./af-smoke-runner.sh --platform {{PLATFORM}} --plan .af-smoke/test-plan.json

Read the JSON report from .af-smoke/reports/ and summarize:
- Overall status
- Any failed checks with evidence
- Recommended next steps
```

### Bare terminal (no agent)

```bash
./af-smoke-runner.sh --platform android --plan .af-smoke/test-plan.json
cat .af-smoke/reports/latest.json | jq '.overall_status'
```

---

## Comparison: approaches for driving test apps

### Option A: bash + ADB/xcrun (recommended)

Scripts drive the app externally through platform tools.

| Pros | Cons |
|---|---|
| Works on any CI runner with Android SDK / Xcode | Cannot drive complex in-app UI interactions |
| No app modification needed beyond logging | Deep link testing requires URL scheme config |
| Portable across all plugin stacks | Limited to what ADB intents / xcrun openurl can trigger |
| Fast to set up and maintain | |

### Option B: integration_test (Flutter) / Detox (RN) / XCTest

Framework-specific test harnesses that run inside the app process.

| Pros | Cons |
|---|---|
| Can drive any UI interaction | Stack-specific; different framework per plugin |
| Tight assertions on widget/view state | Heavier setup; requires test target configuration |
| First-class in CI for that stack | Harder to share across plugins |

### Option C: Appium / Maestro (cross-platform UI automation)

External UI automation tools that interact with the app via accessibility APIs.

| Pros | Cons |
|---|---|
| Stack-agnostic UI automation | Additional dependency to install and maintain |
| Can handle complex flows | Slower than native test frameworks |
| Supports both platforms | Flaky on CI without careful setup |

### Recommendation

**Start with Option A** (bash + ADB/xcrun) for smoke testing. The auto-run test app design eliminates the need for UI interaction during smoke; the app does everything on launch. The script only needs to install, launch, wait, and read logs.

Add Option B or C **later** for plugins that need regression-level coverage beyond smoke.

---

## Phased rollout

### Phase 0: Bootstrap (1-2 weeks)

- Create `appsflyer-mobile-plugin-tooling` repo
- Write `af-smoke-runner.sh` with Android support
- Define smoke test plan JSON schema
- Document the test app contract
- Port the Flutter plugin's existing test plan to the new schema

### Phase 1: Flutter pilot (1-2 weeks)

- Validate `af-smoke-runner.sh` against the Flutter plugin's example app
- Add iOS support to the runner script
- Generate agent skill templates (Cursor + Claude Code)
- Integrate into Flutter plugin's CI (`.github/workflows/ci.yml`)

### Phase 2: Second plugin (1 week)

- Pick React Native or Unity
- Validate the test app contract translates to that stack
- Confirm the runner script works without modification (only `config.json` changes)
- Iterate on the schema if gaps appear

### Phase 3: Broad rollout

- All plugins adopt the test app contract
- Teams instantiate agent skills from templates
- Tooling repo is tagged and versioned

---

## Open questions

1. **Shared dev key for QA?** Should all plugins use the same AppsFlyer dev key and app ID for smoke, or does each plugin keep its own? A shared key makes cross-plugin comparison easier; per-plugin keys give isolation.

2. **CI runner requirements:** Do all plugin CIs have ADB and Xcode available, or do some run on Linux-only GitHub runners?

3. **Native SDK log verbosity:** Android logs HTTP payloads in plain text; iOS does not. Should we push for an iOS SDK debug flag that logs payloads in simulator builds?

4. **Maestro as a future option:** If the team later wants UI-driven flows (beyond auto-run smoke), Maestro is a strong cross-platform option. Worth evaluating in Phase 2.

5. **How strictly to enforce the test app contract:** Should tooling CI validate that a plugin's test app conforms (lint-like check), or is it advisory?
