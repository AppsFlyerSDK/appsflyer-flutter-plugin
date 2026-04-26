# Release user manual (AppsFlyer Flutter plugin)

One-page operator guide for cutting and shipping a release candidate. Read this end-to-end the first time; after that you'll only need steps 1 and 4-6.

For contract meaning and stage IDs, see [`appsflyer-mobile-plugin-tooling/contracts/rc-release-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/rc-release-contract.md). For the file-layout rationale and local dry-run, see [`rc-pipeline-poc.md`](./rc-pipeline-poc.md).

## Prerequisites

- Write access to `AppsFlyerSDK/appsflyer-flutter-plugin` on GitHub.
- Flutter SDK installed locally (used for the optional local simulation).
- `appsflyer-mobile-plugin-tooling` checked out next to this repo if you plan to cross-reference contracts.
- Repo secrets in place: `ENV_FILE`, `PUB_DEV_CREDENTIALS`, `CI_SLACK_WEBHOOK_URL`, `CI_JIRA_EMAIL`, `CI_JIRA_TOKEN`, `CI_JIRA_DOMAIN`. Ask an admin if any are missing; `ENV_FILE` must contain a valid `DEV_KEY` + `APP_ID` that launches cleanly on both platforms.

## Step 1 - Trigger the RC workflow

1. Open the Actions tab → **RC - Release Candidate** workflow → **Run workflow**.
2. Fill in the inputs:

   | Input | Example | Notes |
   |-------|---------|-------|
   | `base_branch` | `development` | Default. Override only when cutting a hotfix off another branch (e.g. `master`-derived patch). |
   | `flutter_version` | `6.18.0-rc1` | Must match `^\d+\.\d+\.\d+(\+\d+)?-rc\d+$` |
   | `ios_sdk_version` | `6.17.7` | Native wrapper version |
   | `android_sdk_version` | `6.17.4` | Native wrapper version |
   | `skip_tests` | `false` | Only set true for doc-only re-runs |
   | `dry_run` | `false` | Leave `true` for drills; set `false` for a real RC |

3. Click **Run workflow**. The workflow runs `validate-release`, `prepare-branch` (cuts `releases/6.x.x/6.18.x/6.18.0-rc1`, commits version bumps), then `run-e2e-ios` and `run-e2e-android` in parallel.

## Step 2 - Wait for the automated gates

Four checks must go green before you do anything:

| Check | Workflow | Notes |
|-------|----------|-------|
| `CI` | `ci.yml` (via `rc-release.yml`) | Unit + lint |
| `E2E - Full Integration Tests` | `e2e.yml` | RC-E2E iOS gate |
| `E2E - Android Integration Tests` | `e2e-android.yml` | RC-E2E Android gate |
| `rc-smoke/pub.dev` | `rc-smoke.yml` | Only appears after `publish-rc` succeeds with `dry_run=false` |

- If any E2E gate fails, fix the code on the release branch and push. E2E re-runs automatically.
- If publish fails on a version collision, bump to `rcN+1` and rerun Step 1 with the new version.
- If `rc-smoke/pub.dev` is red, the RC is broken on pub.dev. Bump to `rcN+1`.
- If `rc-smoke/pub.dev` is `skipped`, the parent run was a dry run or the RC isn't on pub.dev yet. See Troubleshooting → "`rc-smoke/pub.dev` is skipped" before applying the promote label; promotion will reject `skipped` as a green gate.

## Step 3 - Review the auto-opened PR

`rc-release.yml` opens a PR from the release branch to `master` automatically after `publish-rc`. Review:

- Version bumps in `pubspec.yaml`, `android/build.gradle`, `ios/appsflyer_sdk.podspec`, native constants, `README.md`.
- `CHANGELOG.md` — add the new version section if it isn't there yet.
- All four checks green on the PR head SHA.

Slack gets a ping from `notify-team` with the RC link and the Jira tickets pinned to `Flutter SDK v<base_version>`.

## Step 4 - Apply the promote label

When everything is green and the diff looks right, apply the label **`pass QA ready for deploy`** to the PR.

This triggers `promote-release.yml`, which:

1. Verifies `rc-smoke/pub.dev` is `success` on the PR head SHA. A missing, in-progress, or `skipped` check-run fails this step with a PR comment; fix and re-apply the label.
2. Strips `-rcN` from `pubspec.yaml`, native version constants.
3. Commits and pushes to the release branch.
4. Updates the PR description to say "Ready for manual merge."

If the label triggers a failure, read the bot comment; it points at the exact reason.

## Step 5 - Merge the PR

Merge the PR manually. Org branch protection prevents bot merges. This is the single human gate for the entire pipeline.

## Step 6 - Confirm production publish

`production-release.yml` fires on the `master` merge commit:

- Publishes `appsflyer_sdk:^X.Y.Z` to pub.dev.
- Creates GitHub release `vX.Y.Z` with release notes from `CHANGELOG.md`.
- Sends a Slack release notification.

Verify at <https://pub.dev/packages/appsflyer_sdk> (may take a few minutes to index).

## Troubleshooting

### E2E iOS or Android is red

1. Open the failing workflow run and download the `e2e-report` artifact.
2. Open the JSON report; find the first `"status": "FAIL"` check; read its `evidence`.
3. Cross-reference [`appsflyer-mobile-plugin-tooling/docs/troubleshooting.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/docs/troubleshooting.md) for boot timeouts, adb flakes, simctl issues.
4. Fix the plugin source on the release branch, push. E2E re-runs automatically.

### `rc-smoke/pub.dev` is red

1. Open the `rc-smoke.yml` run; download `rc-smoke-ios-<n>` or `rc-smoke-android-<n>` artifacts.
2. Check the JSON report for failing checks.
3. Typical causes: the pub.dev RC has a genuine defect (bump to `rcN+1`), or a test-app regression shared with E2E (fix and bump).
4. After fixing, rerun Step 1 with `rc-release.yml` and the next `rcN`.

### `rc-smoke/pub.dev` is skipped

- Parent run was `dry_run=true`: re-run Step 1 with `dry_run=false`.
- RC isn't indexed on pub.dev yet: wait ~5 minutes and re-run `rc-smoke.yml` manually from the Actions tab with the RC version + release branch as inputs.

### Bumping to `rcN+1`

pub.dev does not allow republishing the same version. If smoke or review catches a defect:

1. Rerun Step 1 with `flutter_version=X.Y.Z-rcN+1` (increment the rc number, keep everything else the same).
2. The existing release branch gets the new version bump on top; old RC stays on pub.dev but is superseded.

### Rerunning smoke only

If you need to re-smoke an already-published RC (e.g. flake), dispatch `rc-smoke.yml` manually with:

- `rc_version`: the exact pub.dev RC version string.
- `release_branch`: the release branch the smoke check should be associated with.

A fresh `rc-smoke/pub.dev` check-run will post on the latest commit of that branch.

### Rolling back a bad production release

Out of scope for this manual. Coordinate with engineering leadership and the on-call. The publish is immutable on pub.dev, so a rollback is "bump the next patch release with a revert commit."

## Dry-run drill path

To exercise the pipeline without touching a real version:

1. Step 1 inputs: `flutter_version=99.99.99-rc1`, `ios_sdk_version=6.17.7`, `android_sdk_version=6.17.4`, `dry_run=true`.
2. Confirm E2E runs, `publish-rc` skips the pub.dev call, PR opens, prerelease tag `99.99.99-rc1` is created on GitHub, `rc-smoke/pub.dev` posts `skipped`.
3. Clean up: delete the release branch, the prerelease tag, and the scratch PR.

For a full local simulation with no CI, run `./scripts/simulate-rc-pipeline.sh --platform ios` on your workstation.

## Reference

- Stage IDs and pass criteria: [`appsflyer-mobile-plugin-tooling/contracts/rc-release-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/rc-release-contract.md)
- Pre-publish E2E meaning: [`appsflyer-mobile-plugin-tooling/contracts/e2e-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/e2e-test-contract.md)
- Post-publish smoke meaning: [`appsflyer-mobile-plugin-tooling/contracts/smoke-test-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/smoke-test-contract.md)
- Test app behavior: [`appsflyer-mobile-plugin-tooling/contracts/test-app-contract.md`](https://github.com/AppsFlyerSDK/appsflyer-mobile-plugin-tooling/blob/main/contracts/test-app-contract.md)
- Local simulation + CI dry-run acceptance test: [`rc-pipeline-poc.md`](./rc-pipeline-poc.md)
