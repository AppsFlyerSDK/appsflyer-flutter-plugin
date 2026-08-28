#!/usr/bin/env bash
# Prints the AppsFlyer Android SDK version this plugin actually ships.
#
# The plugin pins com.appsflyer:af-android-plugin-bridge; the SDK itself is only
# a transitive dependency of that bridge (compile scope in its POM), so there is
# no pin to read locally — the bridge's published POM is the source.
#
# Usage: scripts/resolve-android-sdk-version.sh [path/to/build.gradle]
set -euo pipefail

GRADLE_FILE="${1:-android/build.gradle}"
MAVEN_BASE="${MAVEN_BASE:-https://repo1.maven.org/maven2}"

if [[ ! -f "$GRADLE_FILE" ]]; then
  echo "resolve-android-sdk-version: $GRADLE_FILE not found" >&2
  exit 1
fi

bridge_version=$(
  sed -nE 's/.*com\.appsflyer:af-android-plugin-bridge:([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' \
    "$GRADLE_FILE" | head -1
)
if [[ -z "$bridge_version" ]]; then
  echo "resolve-android-sdk-version: no af-android-plugin-bridge pin found in $GRADLE_FILE" >&2
  exit 1
fi

pom_url="${MAVEN_BASE}/com/appsflyer/af-android-plugin-bridge/${bridge_version}/af-android-plugin-bridge-${bridge_version}.pom"

# af-android-sdk-base is a separate artifact, so the exact <artifactId> tag is
# matched rather than a prefix.
sdk_version=$(
  curl -fsSL --retry 3 --retry-delay 2 "$pom_url" | tr -d '\n' \
    | sed -nE 's;.*<artifactId>af-android-sdk</artifactId>[[:space:]]*<version>([^<]+)</version>.*;\1;p'
)
if [[ -z "$sdk_version" ]]; then
  echo "resolve-android-sdk-version: af-android-sdk not listed in $pom_url" >&2
  exit 1
fi

echo "$sdk_version"
