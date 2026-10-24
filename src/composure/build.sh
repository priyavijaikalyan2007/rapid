#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 37b0bc2b-4d12-4ae8-b19c-215169bb533d
# Created: 2026
# COMPONENT: Composure build entry point
# PURPOSE: Run local core tests and unsigned native builds without publishing.
# RELATES: Composure.xcodeproj, Packages/ComposureCore
# FLOW: Validate mode -> select Xcode -> test or compile selected platforms.

set -euo pipefail

# Validate before tool discovery or output creation, including calls from the root builder.
validate_arguments()
{
    if [[ $# -gt 1 ]]; then
        printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]' >&2
        return 2
    fi
    case "${1:-all}" in
        all | test | macos | ios | web) ;;
        --help | -h)
            printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]'
            exit 0
            ;;
        *)
            printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]' >&2
            return 2
            ;;
    esac
}

# Keep test artifacts and coverage beneath the component-owned output directory.
test_core()
{
    xcrun swift test --package-path "$component_root/Packages/ComposureCore" \
        --scratch-path "$component_root/build/Core" --enable-code-coverage
}

# Signing and distribution remain separate from these development builds.
build_platform()
{
    xcodebuild build -quiet -project "$component_root/Composure.xcodeproj" \
        -scheme "$1" -configuration Debug -destination "$2" \
        -derivedDataPath "$component_root/build/DerivedData" CODE_SIGNING_ALLOWED=NO
}

# Both mobile families share one target. Compile simulator and physical-device variants.
build_mobile()
{
    build_platform 'Composure Mobile' 'generic/platform=iOS Simulator'
    build_platform 'Composure Mobile' 'generic/platform=iOS'
}

main()
{
    validate_arguments "$@"
    local mode="${1:-all}"
    if [[ "$mode" == web ]]; then
        printf '%s\n' 'Composure has no website build.'
        return 0
    fi
    component_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    fi
    case "$mode" in
        all)
            test_core
            build_platform 'Composure Mac' 'generic/platform=macOS'
            build_mobile
            ;;
        test) test_core ;;
        macos) build_platform 'Composure Mac' 'generic/platform=macOS' ;;
        ios) build_mobile ;;
    esac
    printf '%s\n' "Composure $mode checks passed."
}

main "$@"
