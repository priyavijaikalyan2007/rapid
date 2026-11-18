#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 040c3177-4086-431f-b3e2-686bbfb53074
# COMPONENT: MonoMark build entry point
# PURPOSE: Test native and renderer contracts and build unsigned Apple applications.
# FLOW: Validate mode -> build local renderer -> test or compile native targets.
set -euo pipefail
if [[ $# -gt 1 ]]; then
    printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]' >&2
    exit 2
fi
mode="${1:-all}"
case "$mode" in
    all | test | macos | ios) ;;
    web)
        printf '%s\n' 'MonoMark has no website build.'
        exit 0
        ;;
    --help | -h)
        printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]'
        exit 0
        ;;
    *)
        printf '%s\n' 'Usage: build.sh [all|test|macos|ios|web]' >&2
        exit 2
        ;;
esac
component_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_number="${BUILD_NUMBER:-}"
if [[ -z "$build_number" ]]; then
    build_number="$(git -C "$component_root" rev-list --count HEAD 2>/dev/null || printf '1')"
fi
if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s\n' 'The build number must be a positive integer. Set BUILD_NUMBER or use a committed checkout.' >&2
    exit 2
fi
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
if [[ ! -d "$component_root/renderer/node_modules" ]]; then
    printf '%s\n' 'Install locked renderer tools with npm ci --prefix src/app/monomark/renderer --ignore-scripts.' >&2
    exit 1
fi
npm run build --prefix "$component_root/renderer"
if [[ "$mode" == test || "$mode" == all ]]; then
    npm test --prefix "$component_root/renderer"
    swift test --package-path "$component_root" --scratch-path "$component_root/build/Core" --enable-code-coverage
fi
build_target()
{
    xcodebuild build -quiet -project "$component_root/apple/MonoMark.xcodeproj" -scheme "$1" \
        -configuration Release -destination "$2" -derivedDataPath "$component_root/build/DerivedData" \
        CODE_SIGNING_ALLOWED=NO CURRENT_PROJECT_VERSION="$build_number" "${@:3}"
}
if [[ "$mode" == macos || "$mode" == all ]]; then
    build_target MonoMark 'platform=macOS,arch=arm64' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES
    build_target MonoMark 'generic/platform=macOS' 'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO
fi
if [[ "$mode" == ios || "$mode" == all ]]; then
    build_target MonoMarkMobile 'generic/platform=iOS Simulator'
    build_target MonoMarkMobile 'generic/platform=iOS'
fi
printf '%s\n' "MonoMark $mode checks passed."
