#!/usr/bin/env bash
# Asserts every file that carries a version agrees with pubspec.yaml.
#
# Separate pipeline steps rewrite each surface and nothing else compares them:
# production-release.yml validates only the pubspec version's format, and no
# unit test covers the native constants.
#
# Usage: scripts/verify-version-consistency.sh
set -euo pipefail

fail=0

# $1 label, $2 file, $3 expected, $4 sed script producing the actual value
check() {
  local label="$1" file="$2" expected="$3" script="$4" actual
  if [[ ! -f "$file" ]]; then
    echo "::error::$label: $file not found"
    fail=1
    return
  fi
  actual=$(sed -nE "$script" "$file" | head -1)
  if [[ -z "$actual" ]]; then
    echo "::error::$label: no version found in $file"
    fail=1
  elif [[ "$actual" != "$expected" ]]; then
    echo "::error::$label: $file has '$actual', expected '$expected'"
    fail=1
  else
    echo "ok  $label: $actual"
  fi
}

pubspec=$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' pubspec.yaml | head -1)
if [[ -z "$pubspec" ]]; then
  echo "::error::pubspec.yaml declares no version"
  exit 1
fi
echo "pubspec.yaml version: $pubspec"

# CocoaPods rejects prerelease/build metadata, so the podspec carries the bare
# X.Y.Z while the plugin constants carry the full version including -rcN.
podspec_expected=$(echo "$pubspec" | sed -E 's/(\+[0-9]+)?(-rc[0-9]+)?$//')

check "Dart PLUGIN_VERSION" \
  lib/src/appsflyer_constants.dart "$pubspec" \
  's/.*PLUGIN_VERSION[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p'

check "Android PLUGIN_VERSION" \
  android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsFlyerConstants.kt "$pubspec" \
  's/.*PLUGIN_VERSION[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p'

check "iOS kAppsFlyerPluginVersion" \
  ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift "$pubspec" \
  's/.*kAppsFlyerPluginVersion[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p'

check "podspec s.version" \
  ios/appsflyer_sdk.podspec "$podspec_expected" \
  "s/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*'([^']+)'.*/\1/p"

# SPM and CocoaPods are two delivery paths for the same release. Only the
# podspec is rewritten by rc-release.yml, so Package.swift is compared against
# it to keep both paths on one set of native versions.
podspec_af=$(sed -nE "s/.*ss\.ios\.dependency 'AppsFlyerFramework',[[:space:]]*'([^']+)'.*/\1/p" \
  ios/appsflyer_sdk.podspec | head -1)
podspec_rpc=$(sed -nE "s/.*ss\.ios\.dependency 'AppsFlyerRPC',[[:space:]]*'([^']+)'.*/\1/p" \
  ios/appsflyer_sdk.podspec | head -1)

if [[ -z "$podspec_af" || -z "$podspec_rpc" ]]; then
  echo "::error::podspec is missing an AppsFlyerFramework or AppsFlyerRPC pin"
  fail=1
else
  check "Package.swift AppsFlyerFramework" \
    ios/appsflyer_sdk/Package.swift "$podspec_af" \
    's/.*exact:[[:space:]]*"([^"]+)".*/\1/p'

  check "Package.swift AppsFlyerRPC" \
    ios/appsflyer_sdk/Package.swift "$podspec_rpc" \
    's;.*/appsflyer-apple-rpc/releases/download/([^/]+)/.*;\1;p'
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Version surfaces disagree — refusing to release." >&2
  exit 1
fi

echo "All version surfaces agree."
