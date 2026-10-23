#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 1e98245a-250d-4bd3-950e-eaf0cd53bd2f
# Created: 2026

# COMPONENT: Explicit website deployment entry point
# PURPOSE: Route an explicitly requested dry run or deployment to the existing website script.
# RELATES: src/web/deploy.sh, src/web/README.md
# FLOW: Require explicit mode -> delegate to the configured website deployment.

set -euo pipefail
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage()
{
    printf '%s\n' 'Usage: ./deploy.sh --dry-run | deploy' \
        'The deploy argument publishes the website. No mode is selected by default.'
}

main()
{
    if [[ $# -ne 1 ]]; then
        usage >&2
        return 2
    fi
    case "$1" in
        --help|-h) usage ;;
        --dry-run|deploy) exec "$repository_root/src/web/deploy.sh" "$1" ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
