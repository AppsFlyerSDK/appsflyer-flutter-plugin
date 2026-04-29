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

PKG="${PACKAGE_NAME:-com.appsflyer.appsflyersdkexample}"

echo "::group::App private storage (run-as ${PKG})"
echo "--- ls -la (root) ---"
adb shell "run-as ${PKG} ls -la" 2>&1
echo "--- ls -la app_flutter ---"
adb shell "run-as ${PKG} ls -la app_flutter" 2>&1
echo "--- ls -la files ---"
adb shell "run-as ${PKG} ls -la files" 2>&1
echo "--- cat app_flutter/af_qa_logs.txt ---"
adb shell "run-as ${PKG} cat app_flutter/af_qa_logs.txt" 2>&1
echo "::endgroup::"

echo "::group::Process check"
adb shell "ps -A | grep -E '${PKG}|flutter' || true" 2>&1
echo "::endgroup::"

echo "::group::adb logcat dump (last 500 lines, unfiltered)"
adb logcat -d -t 500
echo "::endgroup::"

echo "::group::AndroidRuntime crashes + flutter (full crash buffer)"
adb logcat -d -b crash 2>/dev/null | tail -200
adb logcat -d AndroidRuntime:E DEBUG:E flutter:I '*:S' 2>/dev/null | tail -100
echo "::endgroup::"

exit 1
