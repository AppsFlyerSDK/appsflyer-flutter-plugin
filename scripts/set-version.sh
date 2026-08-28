#!/usr/bin/env bash
# Single writer for every file that carries a version.
#
# Usage:
#   scripts/set-version.sh --plugin-version X.Y.Z[-rcN] [options]
#
#   --plugin-version V   pubspec.yaml, the three plugin constants, podspec s.version
#   --ios-sdk V          podspec AppsFlyerFramework and the SPM exact pin
#   --ios-pc V           podspec PurchaseConnector (optional subspec)
#   --android-bridge V   android/build.gradle af-android-plugin-bridge
#   --android-pc V       android/build.gradle purchase-connector
#
# Native pins are rewritten only when passed; an omitted one is left as is.
# Every rewrite asserts that its pattern matched first, because sed reports
# success when it changes nothing, which turns a stale pattern into a silent
# no-op instead of a failed release.
#
# scripts/verify-version-consistency.sh reads the same surfaces back.
set -euo pipefail

PLUGIN_VERSION=""
IOS_SDK=""
IOS_PC=""
ANDROID_BRIDGE=""
ANDROID_PC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin-version) PLUGIN_VERSION="$2"; shift 2 ;;
    --ios-sdk)        IOS_SDK="$2";        shift 2 ;;
    --ios-pc)         IOS_PC="$2";         shift 2 ;;
    --android-bridge) ANDROID_BRIDGE="$2"; shift 2 ;;
    --android-pc)     ANDROID_PC="$2";     shift 2 ;;
    *) echo "set-version: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

if [[ -z "$PLUGIN_VERSION" ]]; then
  echo "set-version: --plugin-version is required" >&2
  exit 1
fi

# Versions are interpolated into sed replacements, where '/' and '&' carry
# meaning. Reject anything outside the character set a version can legitimately
# use rather than let it corrupt a file silently.
for pair in "plugin-version:$PLUGIN_VERSION" "ios-sdk:$IOS_SDK" "ios-pc:$IOS_PC" \
            "android-bridge:$ANDROID_BRIDGE" "android-pc:$ANDROID_PC"; do
  value="${pair#*:}"
  if [[ -n "$value" && ! "$value" =~ ^[0-9A-Za-z.+-]+$ ]]; then
    echo "set-version: --${pair%%:*} value '$value' is not a valid version" >&2
    exit 1
  fi
done

PODSPEC='ios/appsflyer_sdk.podspec'
SPM='ios/appsflyer_sdk/Package.swift'
GRADLE='android/build.gradle'

# $1 label, $2 file, $3 pattern that must exist, $4 sed expression
rewrite() {
  local label="$1" file="$2" check="$3" expr="$4"
  if [[ ! -f "$file" ]]; then
    echo "::error::$label: $file not found"
    exit 1
  fi
  if ! grep -qE "$check" "$file"; then
    echo "::error::$label: $file has nothing matching /$check/ to update"
    exit 1
  fi
  sed -i.bak -E "$expr" "$file"
  rm -f "$file.bak"
  echo "set $label"
}

rewrite "pubspec version" pubspec.yaml \
  '^version:[[:space:]]' \
  "s/^version:[[:space:]].*/version: ${PLUGIN_VERSION}/"

rewrite "Dart PLUGIN_VERSION" lib/src/appsflyer_constants.dart \
  'PLUGIN_VERSION[[:space:]]*=' \
  "s/(PLUGIN_VERSION[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\1\"${PLUGIN_VERSION}\"/"

rewrite "Android PLUGIN_VERSION" \
  android/src/main/kotlin/com/appsflyer/appsflyersdk/AppsFlyerConstants.kt \
  'PLUGIN_VERSION[[:space:]]*=' \
  "s/(PLUGIN_VERSION[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\1\"${PLUGIN_VERSION}\"/"

rewrite "iOS kAppsFlyerPluginVersion" \
  ios/appsflyer_sdk/Sources/appsflyer_sdk/AppsflyerSdkPlugin.swift \
  'kAppsFlyerPluginVersion[[:space:]]*=' \
  "s/(kAppsFlyerPluginVersion[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\1\"${PLUGIN_VERSION}\"/"

# CocoaPods rejects prerelease and build metadata, so the podspec carries the
# bare X.Y.Z while the plugin constants keep the full version.
PODSPEC_VERSION=$(echo "$PLUGIN_VERSION" | sed -E 's/(\+[0-9]+)?(-rc[0-9]+)?$//')
rewrite "podspec s.version" "$PODSPEC" \
  "^[[:space:]]*s\.version[[:space:]]*=" \
  "s/^([[:space:]]*s\.version[[:space:]]*=[[:space:]]*)'[^']*'/\1'${PODSPEC_VERSION}'/"

if [[ -n "$IOS_SDK" ]]; then
  # Spacing after the comma varies between podspec entries, so it is matched
  # loosely.
  rewrite "podspec AppsFlyerFramework" "$PODSPEC" \
    "ss\.ios\.dependency 'AppsFlyerFramework'," \
    "s/(ss\.ios\.dependency 'AppsFlyerFramework',[[:space:]]*)'[^']*'/\1'${IOS_SDK}'/"

  # SPM and CocoaPods deliver the same release, so the exact pin moves with the
  # podspec dependency. The AppsFlyerRPC binary target is not touched here: it
  # carries a checksum that cannot be derived from a version.
  rewrite "SPM AppsFlyerFramework" "$SPM" \
    'exact:[[:space:]]*"[^"]*"' \
    "s/(exact:[[:space:]]*)\"[^\"]*\"/\1\"${IOS_SDK}\"/"
fi

# PurchaseConnector lives in an optional subspec, so its absence is a skip.
if [[ -n "$IOS_PC" ]]; then
  if grep -qE "ss\.ios\.dependency 'PurchaseConnector'," "$PODSPEC"; then
    rewrite "podspec PurchaseConnector" "$PODSPEC" \
      "ss\.ios\.dependency 'PurchaseConnector'," \
      "s/(ss\.ios\.dependency 'PurchaseConnector',[[:space:]]*)'[^']*'/\1'${IOS_PC}'/"
  else
    echo "skip podspec PurchaseConnector — subspec not present"
  fi
fi

if [[ -n "$ANDROID_BRIDGE" ]]; then
  rewrite "gradle af-android-plugin-bridge" "$GRADLE" \
    'com\.appsflyer:af-android-plugin-bridge:' \
    "s/com\.appsflyer:af-android-plugin-bridge:[0-9]+\.[0-9]+\.[0-9]+/com.appsflyer:af-android-plugin-bridge:${ANDROID_BRIDGE}/"
fi

if [[ -n "$ANDROID_PC" ]]; then
  rewrite "gradle purchase-connector" "$GRADLE" \
    'com\.appsflyer:purchase-connector:' \
    "s/com\.appsflyer:purchase-connector:[0-9]+\.[0-9]+\.[0-9]+/com.appsflyer:purchase-connector:${ANDROID_PC}/"
fi
