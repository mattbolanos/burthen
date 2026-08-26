#!/bin/sh

set -eu

WORKFLOW_NAME="Prod"
TEAM_ID="H2Q833KX49"

# Keep local development and non-production Xcode Cloud actions unchanged.
if [ "${CI_XCODE_CLOUD:-FALSE}" != "TRUE" ] || \
   [ "${CI_WORKFLOW:-}" != "$WORKFLOW_NAME" ] || \
   [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
    exit 0
fi

if [ -z "${BURTHEN_DISTRIBUTION_P12_BASE64:-}" ] || \
   [ -z "${BURTHEN_DISTRIBUTION_P12_PASSWORD:-}" ]; then
    echo "error: The Prod workflow requires its redacted distribution-signing secrets."
    exit 1
fi

umask 077
TEMPORARY_DIRECTORY="${TMPDIR:-/tmp}"
TEMPORARY_DIRECTORY="${TEMPORARY_DIRECTORY%/}"
KEYCHAIN_PASSWORD="$(/usr/bin/uuidgen)$(/usr/bin/uuidgen)"
KEYCHAIN_PATH="$TEMPORARY_DIRECTORY/burthen-signing-$(/usr/bin/uuidgen).keychain-db"
P12_PATH="$TEMPORARY_DIRECTORY/burthen-distribution-$(/usr/bin/uuidgen).p12"

cleanup() {
    /bin/rm -f "$P12_PATH"
}
trap cleanup EXIT HUP INT TERM

/usr/bin/printf '%s' "$BURTHEN_DISTRIBUTION_P12_BASE64" | /usr/bin/base64 --decode > "$P12_PATH"
/bin/chmod 600 "$P12_PATH"

/usr/bin/security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
/usr/bin/security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
/usr/bin/security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
/usr/bin/security import "$P12_PATH" \
    -k "$KEYCHAIN_PATH" \
    -P "$BURTHEN_DISTRIBUTION_P12_PASSWORD" \
    -T /usr/bin/codesign \
    -T /usr/bin/security
cleanup
/usr/bin/security set-key-partition-list \
    -S apple-tool:,apple:,codesign: \
    -s \
    -k "$KEYCHAIN_PASSWORD" \
    "$KEYCHAIN_PATH" >/dev/null

IMPORTED_CERTIFICATES="$(/usr/bin/security find-certificate -a -Z -c 'Apple Distribution:' "$KEYCHAIN_PATH")"
IMPORTED_CERTIFICATE_COUNT="$(/usr/bin/printf '%s\n' "$IMPORTED_CERTIFICATES" | /usr/bin/grep -c '^SHA-1 hash:' || true)"

if [ "$IMPORTED_CERTIFICATE_COUNT" -ne 1 ] || \
   ! /usr/bin/printf '%s\n' "$IMPORTED_CERTIFICATES" | /usr/bin/grep -F "$TEAM_ID" >/dev/null; then
    echo "error: The signing secret must contain one Apple Distribution certificate for team $TEAM_ID."
    exit 1
fi

IMPORTED_CERTIFICATE_SHA1="$(/usr/bin/printf '%s\n' "$IMPORTED_CERTIFICATES" | /usr/bin/awk '/^SHA-1 hash:/ { print $3; exit }')"

# Xcode's distribution exporter prefers a local Apple Distribution identity in
# the user's keychain search list and otherwise falls back to cloud signing.
EXISTING_KEYCHAINS="$(/usr/bin/security list-keychains -d user | /usr/bin/tr -d '\"')"
# The paths Xcode Cloud creates don't contain whitespace. Intentional splitting
# preserves every existing worker keychain after adding the temporary one.
# shellcheck disable=SC2086
/usr/bin/security list-keychains -d user -s "$KEYCHAIN_PATH" $EXISTING_KEYCHAINS

# Validate after extending the search list. On a clean Xcode Cloud worker, the
# Apple intermediate certificate can live in one of the worker's keychains, so
# querying the temporary keychain in isolation incorrectly reports no valid
# identities even though the imported certificate and private key are intact.
VALID_IDENTITIES="$(/usr/bin/security find-identity -v -p codesigning)"
if ! /usr/bin/printf '%s\n' "$VALID_IDENTITIES" | \
   /usr/bin/grep -F "$IMPORTED_CERTIFICATE_SHA1" | \
   /usr/bin/grep -F 'Apple Distribution:' | \
   /usr/bin/grep -F "($TEAM_ID)" >/dev/null; then
    echo "error: The imported Apple Distribution identity is not valid for team $TEAM_ID."
    exit 1
fi

echo "Configured an ephemeral Apple Distribution identity for team $TEAM_ID."
