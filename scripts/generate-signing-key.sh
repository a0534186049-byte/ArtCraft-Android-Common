#!/usr/bin/env bash
set -Eeuo pipefail

APP="${1:-}"
if [[ ! "$APP" =~ ^(gridcraft|photocraft)$ ]]; then
  echo "Usage: bash scripts/generate-signing-key.sh <gridcraft|photocraft>" >&2
  exit 2
fi

command -v keytool >/dev/null 2>&1 || { echo "keytool is required (install JDK 21 or newer)." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "openssl is required." >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_DIR="$ROOT/keys"
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

KEY="$KEY_DIR/$APP-release.jks"
PASSWORD_FILE="$KEY_DIR/$APP-release-password.txt"
BASE64_FILE="$KEY_DIR/$APP-release-keystore-base64.txt"

if [[ -e "$KEY" || -e "$PASSWORD_FILE" || -e "$BASE64_FILE" ]]; then
  echo "::error::Signing material already exists for $APP. Refusing to overwrite it."
  exit 1
fi

PASSWORD="$(openssl rand -hex 32)"
keytool -genkeypair -noprompt -v \
  -keystore "$KEY" -storetype JKS \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -alias artcraftbuilder -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=$APP ArtCraft Android, OU=Release Signing, O=ArtCraft, C=US"

printf '%s' "$PASSWORD" > "$PASSWORD_FILE"
base64 < "$KEY" | tr -d '\r\n' > "$BASE64_FILE"
chmod 600 "$KEY" "$PASSWORD_FILE" "$BASE64_FILE"

FINGERPRINT="$(keytool -list -v -keystore "$KEY" -storepass "$PASSWORD" -alias artcraftbuilder |
  sed -n 's/^[[:space:]]*SHA256: *//p' | head -n 1)"

echo
echo "Created a permanent signing key for $APP."
echo "Do NOT commit or share anything inside: $KEY_DIR"
echo
echo "Add these values as Actions Secrets in the $APP repository:"
echo "  ARTCRAFT_SIGNING_KEYSTORE_BASE64  <- contents of $BASE64_FILE"
echo "  ARTCRAFT_SIGNING_PASSWORD         <- contents of $PASSWORD_FILE"
echo "  ARTCRAFT_EXPECTED_CERT_SHA256     <- $FINGERPRINT"
echo
echo "Back up the key, password and fingerprint securely offline."
echo "Losing this key prevents future APKs from installing as updates over the existing app."
