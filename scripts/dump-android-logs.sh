#!/usr/bin/env bash
# Dump logcat buffers when the Android E2E smoke run fails. Called from
# .github/workflows/android-e2e.yml as the `||`-branch of the smoke runner
# inside reactivecircus/android-emulator-runner. That action invokes each
# line of its `script:` block as a separate `sh -c <line>`, so the dump
# logic must live in a single self-contained command — hence this script
# instead of an inline bash block.
#
# The script always exits 1 so the calling step is marked failed even
# though the dump itself succeeds.

set +e

echo "::group::adb logcat dump (last 500 lines, unfiltered)"
adb logcat -d -t 500
echo "::endgroup::"

echo "::group::AndroidRuntime crashes + flutter (full crash buffer)"
adb logcat -d -b crash 2>/dev/null | tail -200
adb logcat -d AndroidRuntime:E DEBUG:E flutter:I '*:S' 2>/dev/null | tail -100
echo "::endgroup::"

exit 1
