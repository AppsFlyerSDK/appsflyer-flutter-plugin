#!/usr/bin/env bash
# Point this clone's git hooks at the tracked .githooks directory so every
# developer gets the same pre-commit checks (currently: dart format on staged
# Dart files, mirroring the CI "Check code formatting" step).
#
# Run once per clone:
#   ./scripts/install-hooks.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [[ ! -d .githooks ]]; then
  echo "install-hooks: .githooks directory not found at $REPO_ROOT" >&2
  exit 1
fi

chmod +x .githooks/* 2>/dev/null || true

git config core.hooksPath .githooks

echo "✅ git hooks now sourced from .githooks/"
echo "   Active hooks:"
ls -1 .githooks | sed 's/^/     - /'
echo ""
echo "   To revert: git config --unset core.hooksPath"
