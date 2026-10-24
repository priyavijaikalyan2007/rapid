#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: f03fd152-1224-4bcf-b64b-f44ddc3bf1e1
# Created: 2026
# COMPONENT: build
# PURPOSE: Build and verify the owning component without publishing it.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

set -euo pipefail

component_script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/cropprint/scripts/script-support.sh
source "$component_script_root/scripts/script-support.sh"
validate_mode "${1:-all}" "$#" "Usage: $0 [all|test|macos|ios]" all test macos ios

app_root="$(cd "$(dirname "$0")" && pwd)"
build_root="$app_root/build"
project="$app_root/CropPrint.xcodeproj"
mode="${1:-all}"

# shellcheck source=src/cropprint/scripts/build-metadata.sh
source "$app_root/scripts/build-metadata.sh"

version_arguments=(
    MARKETING_VERSION="$APP_VERSION"
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
    GIT_SHA="$GIT_SHA"
)

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

# Run the native regression suite using the selected Xcode toolchain.
build_tests()
{
    xcodebuild test -quiet \
        -project "$project" \
        -scheme CropPrint \
        -configuration Debug \
        -enableCodeCoverage "${CROPPRINT_CODE_COVERAGE:-NO}" \
        -destination 'platform=macOS,arch=arm64' \
        -derivedDataPath "$build_root/TestDerivedData" \
        CODE_SIGNING_ALLOWED=NO \
        CLANG_MODULE_CACHE_PATH="$build_root/TestModuleCache" \
        "${version_arguments[@]}"
}

# Build the unsigned macOS development product.
build_macos()
{
    "$app_root/scripts/package-unsigned.sh"
}

# Compile both mobile platform variants and verify iPhone and iPad support.
build_ios()
{
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
    if [[ "$(plutil -extract UIDeviceFamily.0 raw "$mobile_info")" != "1" ||
    "$(plutil -extract UIDeviceFamily.1 raw "$mobile_info")" != "2" ]]; then
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
