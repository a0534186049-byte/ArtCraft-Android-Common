#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: verify-apk.sh <apk-path> <expected-application-id> [expected-cert-sha256]" >&2
  exit 2
fi

APK="$1"
EXPECTED_PACKAGE="$2"
EXPECTED_CERT="${3:-}"

[[ -f "$APK" ]] || { echo "::error::APK not found: $APK"; exit 1; }
SIZE="$(stat -c%s "$APK")"
[[ "$SIZE" -gt 100000 ]] || { echo "::error::APK is unexpectedly small ($SIZE bytes)."; exit 1; }

unzip -tq "$APK" >/dev/null || { echo "::error::APK failed ZIP integrity validation."; exit 1; }

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[[ -n "$SDK" && -d "$SDK/build-tools" ]] || {
  echo "::error::Android SDK build-tools directory not found."; exit 1;
}

AAPT="$(find "$SDK/build-tools" -type f -name aapt -print | sort -V | tail -n 1)"
APKSIGNER="$(find "$SDK/build-tools" -type f -name apksigner -print | sort -V | tail -n 1)"
[[ -x "$AAPT" ]] || { echo "::error::Android aapt was not found."; exit 1; }
[[ -x "$APKSIGNER" ]] || { echo "::error::Android apksigner was not found."; exit 1; }

PACKAGE="$("$AAPT" dump badging "$APK" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)"
[[ "$PACKAGE" == "$EXPECTED_PACKAGE" ]] || {
  echo "::error::Package ID mismatch. Expected '$EXPECTED_PACKAGE', got '$PACKAGE'."
  exit 1
}

SIGNATURE="$("$APKSIGNER" verify --verbose --print-certs "$APK")"
CERT_SHA256="$(printf '%s\n' "$SIGNATURE" | sed -n 's/.*certificate SHA-256 digest: *//p' | head -n 1 | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')"
[[ -n "$CERT_SHA256" ]] || { echo "::error::Could not read APK signing certificate fingerprint."; exit 1; }

if [[ -n "$EXPECTED_CERT" ]]; then
  NORMALIZED_EXPECTED="$(printf '%s' "$EXPECTED_CERT" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')"
  [[ "$CERT_SHA256" == "$NORMALIZED_EXPECTED" ]] || {
    echo "::error::APK signing certificate differs from the configured expected certificate."
    exit 1
  }
else
  echo "::warning::ARTCRAFT_EXPECTED_CERT_SHA256 is not configured; the APK signature is valid, but the workflow cannot detect an accidentally replaced signing key."
fi

echo "Verified APK: $APK"
echo "Package ID: $PACKAGE"
echo "Size: $SIZE bytes"
echo "Signing certificate SHA-256: $CERT_SHA256"
