#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 9e997a26-16b3-4922-a50d-0233eb6c92ed
# Created: 2026
# COMPONENT: publish-app-store
# PURPOSE: Sequence an authorized clean archive and upload operation.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

set -euo pipefail

component_script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/cropprint/scripts/script-support.sh
source "$component_script_root/script-support.sh"
validate_mode "${1:-all}" "$#" "Usage: $0 [all|macos|ios]" all macos ios

script_root="$(cd "$(dirname "$0")" && pwd)"
platform="${1:-all}"

if [[ "${CONFIRM_APP_STORE_UPLOAD:-}" != "YES" ]]; then
    echo "Set CONFIRM_APP_STORE_UPLOAD=YES to authorize an App Store Connect upload." >&2
    exit 1
fi

"$script_root/archive-app-store.sh" "$platform"
"$script_root/upload-app-store.sh" "$platform"
