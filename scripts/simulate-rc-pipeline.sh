#!/usr/bin/env bash
#
# simulate-rc-pipeline.sh — Local dry-run of the RC pipeline end-to-end
# -----------------------------------------------------------------------------
# Exercises the same stages the CI pipeline runs (see
# appsflyer-mobile-plugin-tooling/contracts/rc-release-contract.md), minus the
# real pub.dev publish and the GitHub Actions environment.
#
#   1. Cut a throwaway release branch (releases/99.99.99-rc1-poc).
#   2. Apply the version bumps that rc-release.yml would apply.
#   3. Run the E2E test plan (.af-e2e/test-plan.json) against example/ via
#      scripts/af-smoke-runner.sh.
#   4. Run the smoke test plan (.af-smoke/rc-test-plan.json) against example/,
#      simulating the pub.dev pin with a local path: .. dependency.
#   5. Emit a combined PASS/FAIL summary and reset local state.
#
# Use this to prove the flow end-to-end on your workstation without burning
# CI minutes or publishing anything. It never touches the remote.
#
# Usage:
#   ./scripts/simulate-rc-pipeline.sh [--platform ios|android|both] [--keep-branch]
#
# Requirements:
#   - git, flutter, jq
#   - an Android emulator booted (for --platform android|both)
#   - an iOS simulator booted (for --platform ios|both, macOS only)
# -----------------------------------------------------------------------------

set -euo pipefail

PLATFORM="both"
KEEP_BRANCH="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      PLATFORM="$2"; shift 2
      ;;
    --platform=*)
      PLATFORM="${1#*=}"; shift
      ;;
    --keep-branch)
      KEEP_BRANCH="true"; shift
      ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2
      ;;
  esac
done

case "$PLATFORM" in
  ios|android|both) ;;
  *) echo "Invalid --platform: $PLATFORM (ios|android|both)" >&2; exit 2 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

POC_VERSION="99.99.99-rc1-poc"
POC_BRANCH="releases/poc/99.99.99-rc1-poc"
ORIGINAL_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

cleanup() {
  local rc=$?
  if [[ "$KEEP_BRANCH" == "false" ]]; then
    echo "▶ Cleanup: restoring $ORIGINAL_BRANCH"
    git checkout --quiet "$ORIGINAL_BRANCH" 2>/dev/null || true
    git branch -D "$POC_BRANCH" 2>/dev/null || true
  else
    echo "▶ Cleanup skipped (--keep-branch); branch $POC_BRANCH retained"
  fi
  exit $rc
}
trap cleanup EXIT INT TERM

log() { printf "\n\033[1;36m▶ %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m✓ %s\033[0m\n" "$*"; }
err() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; }

# ---------------------------------------------------------------------------
# Stage 1: RC-PREP (local simulation)
# ---------------------------------------------------------------------------
log "Stage 1: RC-PREP — create throwaway branch and apply version bumps"
if git show-ref --verify --quiet "refs/heads/$POC_BRANCH"; then
  git branch -D "$POC_BRANCH" >/dev/null
fi
git checkout -b "$POC_BRANCH" >/dev/null
ok "Branch created: $POC_BRANCH"

PUBSPEC_BACKUP="$(mktemp)"
cp pubspec.yaml "$PUBSPEC_BACKUP"
sed -i.bak "s/^version: .*/version: $POC_VERSION/" pubspec.yaml
rm -f pubspec.yaml.bak
ok "pubspec.yaml version set to $POC_VERSION"

# ---------------------------------------------------------------------------
# Stage 2: RC-E2E (local simulation via example/)
# ---------------------------------------------------------------------------
log "Stage 2: RC-E2E — run .af-e2e/test-plan.json against example/"
if [[ ! -f .af-e2e/test-plan.json ]]; then
  err ".af-e2e/test-plan.json not found"; exit 1
fi

E2E_OK="true"
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "both" ]]; then
  if scripts/af-smoke-runner.sh --platform ios --plan .af-e2e/test-plan.json --build; then
    ok "RC-E2E iOS: PASS"
  else
    err "RC-E2E iOS: FAIL"
    E2E_OK="false"
  fi
fi
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "both" ]]; then
  if scripts/af-smoke-runner.sh --platform android --plan .af-e2e/test-plan.json --build; then
    ok "RC-E2E Android: PASS"
  else
    err "RC-E2E Android: FAIL"
    E2E_OK="false"
  fi
fi

if [[ "$E2E_OK" != "true" ]]; then
  err "Aborting: RC-E2E failed. Post-publish smoke would not run in real pipeline."
  mv "$PUBSPEC_BACKUP" pubspec.yaml
  exit 1
fi

# ---------------------------------------------------------------------------
# Stage 3: RC-PUBLISH (skipped locally, simulated)
# ---------------------------------------------------------------------------
log "Stage 3: RC-PUBLISH — skipped locally (real pipeline publishes to pub.dev)"
ok "Simulated publish of appsflyer_sdk@$POC_VERSION"

# ---------------------------------------------------------------------------
# Stage 4: RC-SMOKE (local simulation using example/ with path: ..)
# ---------------------------------------------------------------------------
log "Stage 4: RC-SMOKE — run .af-smoke/rc-test-plan.json (using example/ via path: ..)"

SMOKE_PLAN_TMP="$(mktemp -d)/rc-test-plan.local.json"
jq '(.config.android.build_cmd) = "cd example && flutter pub get && flutter build apk --debug"
  | (.config.ios.build_cmd) = "cd example && flutter pub get && flutter build ios --simulator --debug"
  | (.config.android.apk_path) = "example/build/app/outputs/flutter-apk/app-debug.apk"
  | (.config.ios.app_path) = "example/build/ios/iphonesimulator/Runner.app"
  | (._meta.description) += " [LOCAL SIMULATION: example/ substituted for example_rc_smoke/]"' \
  .af-smoke/rc-test-plan.json > "$SMOKE_PLAN_TMP"

SMOKE_OK="true"
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "both" ]]; then
  if scripts/af-smoke-runner.sh --platform ios --plan "$SMOKE_PLAN_TMP" --build; then
    ok "RC-SMOKE iOS: PASS"
  else
    err "RC-SMOKE iOS: FAIL"
    SMOKE_OK="false"
  fi
fi
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "both" ]]; then
  if scripts/af-smoke-runner.sh --platform android --plan "$SMOKE_PLAN_TMP" --build; then
    ok "RC-SMOKE Android: PASS"
  else
    err "RC-SMOKE Android: FAIL"
    SMOKE_OK="false"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "Summary"
echo "Branch:   $POC_BRANCH (throwaway)"
echo "Version:  $POC_VERSION"
echo "Platform: $PLATFORM"
if [[ "$E2E_OK" == "true" && "$SMOKE_OK" == "true" ]]; then
  ok "All simulated RC stages PASS"
  mv "$PUBSPEC_BACKUP" pubspec.yaml
  exit 0
else
  err "Simulated RC failed — see output above"
  mv "$PUBSPEC_BACKUP" pubspec.yaml
  exit 1
fi
