#!/bin/sh

set -eu

WORKFLOW_NAME="Prod"
TEAM_ID="H2Q833KX49"
APP_APPLICATION_IDENTIFIER="$TEAM_ID.com.mattbolanos.Burthen"
WIDGET_APPLICATION_IDENTIFIER="$TEAM_ID.com.mattbolanos.Burthen.BurthenWidgets"
SCRIPT_DIRECTORY="$(CDPATH= cd -- "$(/usr/bin/dirname -- "$0")" && /bin/pwd)"
WWDR_CERTIFICATE_PATH="$SCRIPT_DIRECTORY/AppleWWDRCAG3.pem"

# Keep local development and non-production Xcode Cloud actions unchanged.
if [ "${CI_XCODE_CLOUD:-FALSE}" != "TRUE" ] || \
   [ "${CI_WORKFLOW:-}" != "$WORKFLOW_NAME" ] || \
   [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
    exit 0
fi

if [ -z "${BURTHEN_DISTRIBUTION_P12_BASE64:-}" ] || \
   [ -z "${BURTHEN_DISTRIBUTION_P12_PASSWORD:-}" ] || \
   [ -z "${BURTHEN_APP_STORE_PROFILE_BASE64:-}" ] || \
   [ -z "${BURTHEN_WIDGET_STORE_PROFILE_BASE64:-}" ]; then
    echo "error: The Prod workflow requires its redacted distribution-signing secrets and profiles."
    exit 1
fi

umask 077
TEMPORARY_DIRECTORY="${TMPDIR:-/tmp}"
TEMPORARY_DIRECTORY="${TEMPORARY_DIRECTORY%/}"
KEYCHAIN_PASSWORD="$(/usr/bin/uuidgen)$(/usr/bin/uuidgen)"
KEYCHAIN_PATH="$TEMPORARY_DIRECTORY/burthen-signing-$(/usr/bin/uuidgen).keychain-db"
P12_PATH="$TEMPORARY_DIRECTORY/burthen-distribution-$(/usr/bin/uuidgen).p12"
APP_PROFILE_TEMP_PATH="$TEMPORARY_DIRECTORY/burthen-app-store-$(/usr/bin/uuidgen).mobileprovision"
WIDGET_PROFILE_TEMP_PATH="$TEMPORARY_DIRECTORY/burthen-widget-store-$(/usr/bin/uuidgen).mobileprovision"
PROFILE_DIRECTORY="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"

cleanup() {
    /bin/rm -f "$P12_PATH" "$APP_PROFILE_TEMP_PATH" "$WIDGET_PROFILE_TEMP_PATH"
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

# A fresh Xcode Cloud worker can lack the G3 intermediate that issued Apple
# Distribution certificates. Apple publishes this certificate publicly, and
# committing it makes signing deterministic without another network request.
/usr/bin/security import "$WWDR_CERTIFICATE_PATH" \
    -k "$KEYCHAIN_PATH" \
    -T /usr/bin/codesign \
    -T /usr/bin/security >/dev/null
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

install_profile() {
    SIGNING_PROFILE_BASE64="$1"
    SIGNING_PROFILE_TEMP_PATH="$2"
    EXPECTED_APPLICATION_IDENTIFIER="$3"

    /usr/bin/printf '%s' "$SIGNING_PROFILE_BASE64" | /usr/bin/base64 --decode > "$SIGNING_PROFILE_TEMP_PATH"
    /bin/chmod 600 "$SIGNING_PROFILE_TEMP_PATH"
    SIGNING_PROFILE_PLIST="$(/usr/bin/security cms -D -i "$SIGNING_PROFILE_TEMP_PATH")"
    SIGNING_PROFILE_UUID="$(/usr/bin/printf '%s' "$SIGNING_PROFILE_PLIST" | /usr/bin/plutil -extract UUID raw -o - -)"
    SIGNING_PROFILE_TEAM_ID="$(/usr/bin/printf '%s' "$SIGNING_PROFILE_PLIST" | /usr/bin/plutil -extract TeamIdentifier.0 raw -o - -)"
    SIGNING_PROFILE_APPLICATION_IDENTIFIER="$(/usr/bin/printf '%s' "$SIGNING_PROFILE_PLIST" | /usr/bin/plutil -extract Entitlements.application-identifier raw -o - -)"
    SIGNING_PROFILE_CERTIFICATE_BASE64="$(/usr/bin/printf '%s' "$SIGNING_PROFILE_PLIST" | /usr/bin/plutil -extract DeveloperCertificates.0 raw -o - -)"
    SIGNING_PROFILE_CERTIFICATE_SHA1="$(/usr/bin/printf '%s' "$SIGNING_PROFILE_CERTIFICATE_BASE64" | /usr/bin/base64 --decode | /usr/bin/shasum -a 1 | /usr/bin/awk '{ print toupper($1) }')"

    if [ "$SIGNING_PROFILE_TEAM_ID" != "$TEAM_ID" ] || \
       [ "$SIGNING_PROFILE_APPLICATION_IDENTIFIER" != "$EXPECTED_APPLICATION_IDENTIFIER" ] || \
       [ "$SIGNING_PROFILE_CERTIFICATE_SHA1" != "$IMPORTED_CERTIFICATE_SHA1" ] || \
       ! /usr/bin/printf '%s' "$SIGNING_PROFILE_UUID" | /usr/bin/grep -E '^[0-9A-Fa-f-]{36}$' >/dev/null; then
        echo "error: A signing profile does not match the imported certificate and expected application identifier."
        exit 1
    fi

    /bin/mkdir -p "$PROFILE_DIRECTORY"
    /bin/cp "$SIGNING_PROFILE_TEMP_PATH" "$PROFILE_DIRECTORY/$SIGNING_PROFILE_UUID.mobileprovision"
    /bin/chmod 600 "$PROFILE_DIRECTORY/$SIGNING_PROFILE_UUID.mobileprovision"
}

install_profile \
    "$BURTHEN_APP_STORE_PROFILE_BASE64" \
    "$APP_PROFILE_TEMP_PATH" \
    "$APP_APPLICATION_IDENTIFIER"
install_profile \
    "$BURTHEN_WIDGET_STORE_PROFILE_BASE64" \
    "$WIDGET_PROFILE_TEMP_PATH" \
    "$WIDGET_APPLICATION_IDENTIFIER"
cleanup

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
