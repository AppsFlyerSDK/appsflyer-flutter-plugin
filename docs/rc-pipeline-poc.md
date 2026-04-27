# RC pipeline POC

This doc describes how to prove the unified RC pipeline works end-to-end before we trust it for a real release. Two levels: local simulation (no remote calls) and CI dry-run against a throwaway version.

For the user-facing operator manual, see [`RELEASE_USER_MANUAL.md`](./RELEASE_USER_MANUAL.md) (added in PR D). For contract meaning and stage definitions, see [`appsflyer-mobile-plugin-tooling/contracts/rc-release-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/rc-release-contract.md).

## Why a POC

The pipeline is additive; it does not replace a working release process. We need a way to exercise every stage without risking a real pub.dev artifact. Two layers cover that.

## Level 1: local simulation

Run on your workstation. No remote calls. Proves the plans, runner, scripts, and example app scaffolding all line up.

```sh
./scripts/simulate-rc-pipeline.sh --platform ios
# or --platform android
# or --platform both
```

What the script does:

1. Cuts a throwaway branch `releases/poc/99.99.99-rc1-poc`.
2. Stamps `pubspec.yaml` with `99.99.99-rc1-poc` (the RC-PREP stage in the contract).
3. Runs `.af-e2e/test-plan.json` against `example/` via `scripts/af-smoke-runner.sh` (the RC-E2E stage).
4. Simulates RC-PUBLISH — nothing real happens here, it prints a confirmation.
5. Runs `.af-smoke/rc-test-plan.json` against `example/` using a runtime-rewritten plan that substitutes `path: ..` for the pub.dev pin (the RC-SMOKE stage, minus the registry dependency).
6. Restores `pubspec.yaml` and deletes the throwaway branch.

Exit code 0 means both E2E and smoke passed. Exit code 1 means one of them failed; the script leaves a passing combined summary off.

Pass `--keep-branch` if you want to inspect the staging state after the run.

## Level 2: CI dry-run

Once the four plugin PRs (A, B, C, D) land, exercise the full workflow tree against a scratch version. Inputs:

- `flutter_version=99.99.99-rc1`
- `ios_sdk_version=6.17.7` (or whatever today's native wrappers pin)
- `android_sdk_version=6.17.4`
- `dry_run=true`

Expected behavior with `dry_run=true`:

- `rc-release.yml` creates the branch, applies version bumps, runs CI, and runs the two E2E workflows via `workflow_call`.
- `publish-rc` job runs validation but skips the real `flutter pub publish`.
- `open-pr` opens the PR to `master`.
- `create-prerelease` cuts the `99.99.99-rc1` tag as a GitHub prerelease.
- `notify-team` posts a Slack ping (or logs a skip if the webhook is unreachable).
- `rc-smoke.yml` fires via `workflow_run` on completion, detects the `dry_run=true` signal, posts `rc-smoke/pub.dev` check-run with conclusion `skipped`, and exits fast.

Expected behavior with `dry_run=false` on the same scratch version (run after the dry run):

- Everything above, plus `publish-rc` actually publishes `99.99.99-rc1` to pub.dev.
- `rc-smoke.yml` templates `example_rc_smoke/pubspec.yaml` with `appsflyer_sdk: =99.99.99-rc1`, builds, runs `SMOKE-001/002/003` on both platforms, uploads reports, and posts `rc-smoke/pub.dev` with conclusion `success`.
- The PR shows all four checks green: `CI`, `iOS E2E`, `Android E2E`, `rc-smoke/pub.dev`.

Negative promote test (proves the gate):

1. Take an old merged PR or a fresh dummy PR without a green `rc-smoke/pub.dev` check.
2. Apply the `pass QA ready for deploy` label.
3. `promote-release.yml` should fail fast with a PR comment pointing at the missing check-run.

Positive promote test (full loop):

1. On the real `99.99.99-rc1` PR, apply the `pass QA ready for deploy` label.
2. `promote-release.yml` verifies the green smoke check, strips `-rc1` from the release branch, pushes, and updates the PR description.
3. Merge the PR manually.
4. `production-release.yml` publishes `99.99.99` to pub.dev and cuts the GitHub release.
5. Clean up: delete the `99.99.99-rc1` tag and the `99.99.99` tag from the scratch version so the version slot is free again.

## POC acceptance checklist

- [ ] `simulate-rc-pipeline.sh --platform both` exits zero on a dev workstation with an emulator + simulator booted.
- [ ] Dry-run CI run on `99.99.99-rc1` produces a PR with `rc-smoke/pub.dev=skipped` and no pub.dev artifact.
- [ ] Wet-run CI run on `99.99.99-rc1` produces a PR with `rc-smoke/pub.dev=success` and a real pub.dev artifact.
- [ ] Negative promote (mis-applied label) leaves a PR comment and does not strip `-rc1`.
- [ ] Positive promote strips `-rc1`, merge publishes `99.99.99` to pub.dev, GitHub release exists.
- [ ] All four workflows (`rc-release.yml`, `rc-smoke.yml`, `promote-release.yml`, `production-release.yml`) appear in the Actions tab with the expected job names.

Mark each of these as you go in the PR description of the PR that lands this doc; those are the acceptance criteria.
