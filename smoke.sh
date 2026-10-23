#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 228321f6-bc7f-4e67-bdf5-8c63a5bdb2f6
# Created: 2026

# COMPONENT: Local static-site smoke check
# PURPOSE: Build the website and validate generated files without contacting production.
# RELATES: src/web/build.sh, src/web/scripts/check-site.mjs
# FLOW: Validate explicit website selection -> run the component static checks.

set -euo pipefail
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage()
{
    printf '%s\n' 'Usage: ./smoke.sh web' 'Checks generated website files and local links.'
}

main()
{
    if [[ $# -ne 1 ]]; then
        usage >&2
        return 2
    fi
    case "$1" in
        --help|-h) usage ;;
        web) exec "$repository_root/src/web/build.sh" test ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
