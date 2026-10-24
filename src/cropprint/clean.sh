#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 97a56042-b359-498b-a8c9-2d3b7c1f91c7
# Created: 2026
# COMPONENT: clean
# PURPOSE: Remove only generated output and documented component caches.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

set -euo pipefail

component_script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/cropprint/scripts/script-support.sh
source "$component_script_root/scripts/script-support.sh"
validate_no_arguments "$#" "${1:-}" "Usage: $0"

app_root="$(cd "$(dirname "$0")" && pwd)"
build_root="$app_root/build"

if [[ "$build_root" != "$app_root/build" || "$app_root" == "/" ]]; then
    echo "Refusing to clean an unexpected path: $build_root" >&2
    exit 1
fi

rm -rf "$build_root"

find "$app_root" -name '.DS_Store' -type f -delete
find "$app_root" -name 'xcuserdata' -type d -prune -exec rm -rf {} +
find "$app_root" -name '.build' -type d -prune -exec rm -rf {} +
find "$app_root" -name '.swiftpm' -type d -prune -exec rm -rf {} +
find "$app_root" -name 'DerivedData' -type d -prune -exec rm -rf {} +

echo "Cleaned CropPrint temporary files and build outputs."
