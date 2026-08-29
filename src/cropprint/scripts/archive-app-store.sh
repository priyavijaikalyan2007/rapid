#!/bin/bash

set -euo pipefail

app_root="$(cd "$(dirname "$0")/.." && pwd)"
project="$app_root/CropPrint.xcodeproj"
archive_root="$app_root/build/AppStore"
platform="${1:-all}"

source "$app_root/scripts/build-metadata.sh"

if [[ "$GIT_FULL_SHA" == "nogit" || "$GIT_SHA" == *-dirty ]]; then
  echo "App Store archives require a clean Git commit." >&2
  exit 1
fi

if [[ -z "${APPLE_TEAM_ID:-}" ]]; then
  echo "Set APPLE_TEAM_ID to your Apple Developer team identifier." >&2
  exit 1
fi

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

authentication_arguments=()
if [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" || -n "${APP_STORE_CONNECT_API_KEY_ID:-}" || -n "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]]; then
  if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" || -z "${APP_STORE_CONNECT_API_KEY_ID:-}" || -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]]; then
    echo "Set all three App Store Connect API key variables, or set none of them." >&2
    exit 1
  fi
  authentication_arguments=(
    -authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
    -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_API_ISSUER_ID"
  )
fi

version_arguments=(
  MARKETING_VERSION="$APP_VERSION"
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
  GIT_SHA="$GIT_SHA"
)

archive_macos() {
  xcodebuild archive \
    -project "$project" \
    -scheme CropPrint \
    -configuration Release \
    -sdk macosx \
    -archivePath "$archive_root/CropPrint-macOS.xcarchive" \
    -allowProvisioningUpdates \
    "${authentication_arguments[@]}" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    "${version_arguments[@]}"
}

archive_ios() {
  xcodebuild archive \
    -project "$project" \
    -scheme 'CropPrint Mobile' \
    -configuration Release \
    -sdk iphoneos \
    -archivePath "$archive_root/CropPrint-iOS.xcarchive" \
    -allowProvisioningUpdates \
    "${authentication_arguments[@]}" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    "${version_arguments[@]}"
}

mkdir -p "$archive_root"

case "$platform" in
  all)
    archive_macos
    archive_ios
    ;;
  macos)
    archive_macos
    ;;
  ios)
    archive_ios
    ;;
  *)
    echo "Usage: $0 [all|macos|ios]" >&2
    exit 2
    ;;
esac

echo "Created App Store archives under $archive_root."
