#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 0ad233d3-6b98-46be-ad65-2de22ee21957
# Created: 2026

# COMPONENT: Repository validation entry point
# PURPOSE: Run repository checks and selected component tests without publishing.
# RELATES: test/, configure.sh, src/cropprint/build.sh, src/web/build.sh
# FLOW: Validate selection -> check profile -> test repository and components.

set -euo pipefail
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage()
{
    printf '%s\n' 'Usage: ./test.sh [all|repository|cropprint|composure|web]' \
        'Default: all. Repository checks require Python 3.10+ and Bats 1.12+.'
}

# Keep shell contract tests separate from the Apple test services.
check_repository()
{
    local bats_bin="${BATS_BIN:-bats}"
    if [[ -z "${BATS_BIN:-}" && -x "$repository_root/local/tools/bats-core/bin/bats" ]]; then
        bats_bin="$repository_root/local/tools/bats-core/bin/bats"
    fi
    if ! command -v "$bats_bin" >/dev/null 2>&1; then
        printf '%s\n' 'Bats is unavailable. Install bats-core or set BATS_BIN to its executable.' >&2
        return 1
    fi
    python3 -m unittest discover -s "$repository_root/test" -p 'test_*.py'
    "$bats_bin" "$repository_root"/test/*.bats
}

validate_arguments()
{
    if [[ $# -gt 1 ]]; then
        usage >&2
        return 2
    fi
    case "${1:-all}" in
        all | repository | cropprint | composure | web | --help | -h) ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main()
{
    validate_arguments "$@"
    if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
        usage
        return 0
    fi
    local mode="${1:-all}"
    "$repository_root/configure.sh" --check
    if [[ "$mode" == all || "$mode" == repository ]]; then
        check_repository
    fi
    if [[ "$mode" == all || "$mode" == cropprint ]]; then
        "$repository_root/src/cropprint/build.sh" test
    fi
    if [[ "$mode" == all || "$mode" == composure ]]; then
        "$repository_root/src/composure/build.sh" test
    fi
    if [[ "$mode" == all || "$mode" == web ]]; then
        "$repository_root/src/web/build.sh" test
    fi
    printf '%s\n' "Repository $mode checks passed."
}

main "$@"
