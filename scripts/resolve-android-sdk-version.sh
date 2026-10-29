#!/usr/bin/env bash
# Prints the AppsFlyer Android SDK version this plugin actually ships.
#
# The SDK is never pinned in this repo; af-android-sdk-bom decides it. Release
# contract: af-android-sdk-bom X.Y.Z manages af-android-sdk X.Y.Z, so the pinned
# BOM version is the SDK version. af-android-plugin-bridge is not consulted: it
# is built against an already-released SDK, so it never requires one newer than
# the pinned BOM.
#
# Usage: scripts/resolve-android-sdk-version.sh [path/to/build.gradle]
set -euo pipefail

GRADLE_FILE="${1:-android/build.gradle}"

if [[ ! -f "$GRADLE_FILE" ]]; then
  echo "resolve-android-sdk-version: $GRADLE_FILE not found" >&2
  exit 1
fi

# The ':' stops af-android-sdk-bom matching a shorter artifact's prefix.
bom_version=$(
  sed -nE 's/.*com\.appsflyer:af-android-sdk-bom:([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' \
    "$GRADLE_FILE" | head -1
)

if [[ -z "$bom_version" ]]; then
  echo "resolve-android-sdk-version: no com.appsflyer:af-android-sdk-bom pin found in $GRADLE_FILE" >&2
  exit 1
fi

echo "$bom_version"
