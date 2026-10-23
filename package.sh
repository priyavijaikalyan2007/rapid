#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 768ceab1-348e-411b-8571-9603bc61b415
# Created: 2026

# COMPONENT: Unsigned development packaging entry point
# PURPOSE: Create the existing macOS ZIP without signing, uploading, or submitting it.
# RELATES: src/cropprint/scripts/package-unsigned.sh, PUBLISHING.md
# FLOW: Validate explicit development target -> invoke the component packager.

set -euo pipefail
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage()
{
    printf '%s\n' 'Usage: ./package.sh macos' \
        'Output: src/cropprint/build/CropPrint-unsigned.zip. App Store releases use PUBLISHING.md.'
}

main()
{
    if [[ $# -ne 1 ]]; then
        usage >&2
        return 2
    fi
    case "$1" in
        --help|-h) usage ;;
        macos) exec "$repository_root/src/cropprint/scripts/package-unsigned.sh" ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
