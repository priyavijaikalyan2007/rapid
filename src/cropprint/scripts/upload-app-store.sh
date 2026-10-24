#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: dfe7e4fa-4324-4754-bdf3-dc02b203a0eb
# Created: 2026
# COMPONENT: upload-app-store
# PURPOSE: Upload explicitly authorized archives after source and duplicate checks.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

set -euo pipefail

component_script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/cropprint/scripts/script-support.sh
source "$component_script_root/script-support.sh"
validate_mode "${1:-all}" "$#" "Usage: $0 [all|macos|ios]" all macos ios

app_root="$(cd "$(dirname "$0")/.." && pwd)"
archive_root="$app_root/build/AppStore"
publish_state_root="$app_root/.publish-state"
export_options="$app_root/ExportOptions-AppStore.plist"
platform="${1:-all}"

# shellcheck source=src/cropprint/scripts/build-metadata.sh
source "$app_root/scripts/build-metadata.sh"

if [[ "$GIT_FULL_SHA" == "nogit" || "$GIT_SHA" == *-dirty ]]; then
    echo "App Store uploads require a clean Git commit." >&2
    exit 1
fi

if [[ "${CONFIRM_APP_STORE_UPLOAD:-}" != "YES" ]]; then
    echo "Set CONFIRM_APP_STORE_UPLOAD=YES to authorize an App Store Connect upload." >&2
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

# Pass authentication arguments only to the explicitly authorized Xcode operation.
run_xcodebuild()
{
    if ((${#authentication_arguments[@]} > 0)); then
        xcodebuild "$@" "${authentication_arguments[@]}"
    else
        xcodebuild "$@"
    fi
}

# Validate exact archive provenance and duplicate-upload state before upload.
upload_archive()
{
    local archive_path="$1"
    local export_path="$2"
    local upload_marker="$3"

    if [[ -f "$upload_marker" && "$(<"$upload_marker")" == "$GIT_FULL_SHA" && "${FORCE_APP_STORE_UPLOAD:-}" != "YES" ]]; then
        echo "This commit was already uploaded for $(basename "$archive_path")." >&2
        echo "Set FORCE_APP_STORE_UPLOAD=YES to upload it again." >&2
        exit 1
    fi

    if [[ ! -d "$archive_path" ]]; then
        echo "Archive not found: $archive_path" >&2
        echo "Run archive-app-store.sh before uploading." >&2
        exit 1
    fi

    validate_archive_identity "$archive_path" "$GIT_SHA" "$APP_VERSION" "$BUILD_NUMBER"

    run_xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$export_options" \
        -allowProvisioningUpdates

    printf '%s\n' "$GIT_FULL_SHA" >"$upload_marker"
}

case "$platform" in
    all)
        mkdir -p "$publish_state_root"
        upload_archive "$archive_root/CropPrint-macOS.xcarchive" "$archive_root/upload-macOS" "$publish_state_root/last-uploaded-macOS-sha"
        upload_archive "$archive_root/CropPrint-iOS.xcarchive" "$archive_root/upload-iOS" "$publish_state_root/last-uploaded-iOS-sha"
        ;;
    macos)
        mkdir -p "$publish_state_root"
        upload_archive "$archive_root/CropPrint-macOS.xcarchive" "$archive_root/upload-macOS" "$publish_state_root/last-uploaded-macOS-sha"
        ;;
    ios)
        mkdir -p "$publish_state_root"
        upload_archive "$archive_root/CropPrint-iOS.xcarchive" "$archive_root/upload-iOS" "$publish_state_root/last-uploaded-iOS-sha"
        ;;
    *)
        echo "Usage: $0 [all|macos|ios]" >&2
        exit 2
        ;;
esac

echo "The selected archives were uploaded to App Store Connect."
