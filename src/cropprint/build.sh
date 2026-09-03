#!/bin/bash

set -euo pipefail

app_root="$(cd "$(dirname "$0")" && pwd)"
build_root="$app_root/build"
project="$app_root/CropPrint.xcodeproj"
mode="${1:-all}"

source "$app_root/scripts/build-metadata.sh"

version_arguments=(
  MARKETING_VERSION="$APP_VERSION"
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
  GIT_SHA="$GIT_SHA"
)

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

build_tests() {
  xcodebuild test -quiet \
    -project "$project" \
    -scheme CropPrint \
    -configuration Debug \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$build_root/TestDerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CLANG_MODULE_CACHE_PATH="$build_root/TestModuleCache" \
    "${version_arguments[@]}"
}

build_macos() {
  "$app_root/scripts/package-unsigned.sh"
}

build_ios() {
  if ! xcodebuild build -quiet \
    -project "$project" \
    -scheme 'CropPrint Mobile' \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$build_root/MobileSimulatorDerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    "${version_arguments[@]}"; then
    echo "The iOS simulator build failed." >&2
    echo "Install the iOS platform in Xcode Settings > Components, then retry." >&2
    return 1
  fi

  if ! xcodebuild build -quiet \
    -project "$project" \
    -scheme 'CropPrint Mobile' \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$build_root/MobileDeviceDerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    "${version_arguments[@]}"; then
    echo "The iPhone device build failed." >&2
    echo "Install the iOS platform in Xcode Settings > Components, then retry." >&2
    return 1
  fi

  local mobile_info="$build_root/MobileDeviceDerivedData/Build/Products/Release-iphoneos/CropPrint Mobile.app/Info.plist"
  if [[ "$(plutil -extract UIDeviceFamily.0 raw "$mobile_info")" != "1" \
    || "$(plutil -extract UIDeviceFamily.1 raw "$mobile_info")" != "2" ]]; then
    echo "The mobile application must support both iPhone and iPad." >&2
    return 1
  fi
}

case "$mode" in
  all)
    build_tests
    build_macos
    build_ios
    ;;
  test)
    build_tests
    ;;
  macos)
    build_macos
    ;;
  ios)
    build_ios
    ;;
  *)
    echo "Usage: $0 [all|test|macos|ios]" >&2
    exit 2
    ;;
esac

echo "CropPrint $mode build complete."
