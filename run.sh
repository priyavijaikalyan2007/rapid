#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: e13f3475-899f-4af7-8162-e2409d4600f9
# Created: 2026

# COMPONENT: Local development entry point
# PURPOSE: Start the existing website preview without choosing a native device.
# RELATES: src/web/preview.sh, src/cropprint/README.md
# FLOW: Validate explicit component -> run its local development command.

set -euo pipefail
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage()
{
    printf '%s\n' 'Usage: ./run.sh web' \
        'Native apps: open src/cropprint/CropPrint.xcodeproj and select a scheme and device in Xcode.'
}

main()
{
    if [[ $# -ne 1 ]]; then
        usage >&2
        return 2
    fi
    case "$1" in
        --help|-h) usage ;;
        web) exec "$repository_root/src/web/preview.sh" ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
