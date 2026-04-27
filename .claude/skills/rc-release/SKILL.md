---
name: rc-release
description: Run or review an RC release for the AppsFlyer Flutter plugin. Follows the six-stage RC pipeline (RC-PREP, RC-E2E, RC-PUBLISH, RC-SMOKE, RC-PROMOTE, RC-RELEASE) defined in appsflyer-mobile-plugin-tooling. Use when cutting a new RC, debugging a failed rc-release / rc-smoke / promote-release run, or reviewing a promote PR.
---

# RC release - Flutter plugin

Thin pointer to the normative contract in the tooling repo. Do not duplicate contract content here; link to it.

## Sources of truth

- RC stage definitions: `../../../../appsflyer-mobile-plugin-tooling/contracts/rc-release-contract.md`
- Pre-publish E2E scenarios: `../../../../appsflyer-mobile-plugin-tooling/contracts/e2e-test-contract.md`
- Post-publish smoke scenarios: `../../../../appsflyer-mobile-plugin-tooling/contracts/smoke-test-contract.md`
- Test-app behavior: `../../../../appsflyer-mobile-plugin-tooling/contracts/test-app-contract.md`
- Operator manual for humans: [`../../../docs/RELEASE_USER_MANUAL.md`](../../../docs/RELEASE_USER_MANUAL.md)

Always follow the operator manual for step-by-step actions. This skill tells you which file owns which piece of the pipeline.

## Stage map for this plugin

| Stage | Workflow file | Notes |
|-------|---------------|-------|
| `RC-PREP` | [`.github/workflows/rc-release.yml`](../../../.github/workflows/rc-release.yml) | `prepare-branch` job; cuts `releases/<major>.x.x/<minor>.x/<version>` |
| `RC-E2E` | [`.github/workflows/ios-e2e.yml`](../../../.github/workflows/ios-e2e.yml), [`.github/workflows/android-e2e.yml`](../../../.github/workflows/android-e2e.yml) | Called via `workflow_call` from RC-release |
| `RC-PUBLISH` | [`.github/workflows/rc-release.yml`](../../../.github/workflows/rc-release.yml) | `publish-rc` job; honors `dry_run` |
| `RC-SMOKE` | [`.github/workflows/rc-smoke.yml`](../../../.github/workflows/rc-smoke.yml) | `workflow_run` on RC-release success; manual `workflow_dispatch` for reruns |
| `RC-PROMOTE` | [`.github/workflows/promote-release.yml`](../../../.github/workflows/promote-release.yml) | Triggered by `pass QA ready for deploy` label |
| `RC-RELEASE` | [`.github/workflows/production-release.yml`](../../../.github/workflows/production-release.yml) | Triggered by PR merge to `master` |

## Test plans

- E2E (pre-publish, against plugin source): [`.af-e2e/test-plan.json`](../../../.af-e2e/test-plan.json)
- Smoke (post-publish, against pub.dev RC): [`.af-smoke/rc-test-plan.json`](../../../.af-smoke/rc-test-plan.json)
- Runner: [`scripts/af-smoke-runner.sh`](../../../scripts/af-smoke-runner.sh)
- Local simulator: [`scripts/simulate-rc-pipeline.sh`](../../../scripts/simulate-rc-pipeline.sh)

## How to run an RC

Follow [`docs/RELEASE_USER_MANUAL.md`](../../../docs/RELEASE_USER_MANUAL.md) steps 1-6. In short: dispatch `rc-release.yml` with `dry_run=false`, watch four checks go green on the PR, apply `pass QA ready for deploy`, merge.

## How to debug a red stage

1. Identify which stage failed from the PR's check status (names map 1:1 to the workflows above).
2. For E2E: open the workflow run's `e2e-report` artifact; find first `"status": "FAIL"`; read `evidence`.
3. For RC-PUBLISH: check version collision (bump `rcN+1`) and `PUB_DEV_CREDENTIALS` secret.
4. For RC-SMOKE: `rc-smoke-ios-<n>` / `rc-smoke-android-<n>` artifacts contain the smoke JSON reports.
5. For RC-PROMOTE: the bot leaves a PR comment pointing at the exact reason (missing / wrong conclusion on `rc-smoke/pub.dev`).

## Rules

- Never strip `-rcN` manually and push; RC-PROMOTE is the only sanctioned path.
- Never republish the same RC version to pub.dev; bump to `rcN+1`.
- Never merge the promote PR before `RC-PROMOTE` has succeeded (it updates the PR body when it does).
- Never duplicate contract text in this skill; link to the tooling repo.
