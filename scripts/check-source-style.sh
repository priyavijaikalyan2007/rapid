#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 9fb1a02c-2807-43ca-8217-4b73891c3804
# Created: 2026
# COMPONENT: Source style validation
# PURPOSE: Check authored Swift and component shell source without modifying files or downloading tools.
# RELATES: src/.swiftformat, src/.editorconfig, test/source-style.bats
# FLOW: Validate arguments -> resolve installed tools -> lint native source and shell scripts.

set -euo pipefail

# Prefer the audited local tool, then use an explicitly installed command from PATH.
resolve_tool()
{
    local command_name="$1" local_path="$2"
    if [[ -x "$repository_root/$local_path" ]]; then
        printf '%s\n' "$repository_root/$local_path"
    elif command -v "$command_name" >/dev/null 2>&1; then
        command -v "$command_name"
    else
        printf '%s\n' "Missing $command_name. Install the source-check prerequisites from CONTRIBUTING.md." >&2
        return 1
    fi
}

# Reject unsupported requests before resolving or starting any developer tool.
validate_arguments()
{
    if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
        printf '%s\n' 'Usage: ./scripts/check-source-style.sh'
        exit 0
    fi
    if (($# > 0)); then
        printf '%s\n' 'Usage: ./scripts/check-source-style.sh' >&2
        return 2
    fi
}

# Keep every check read-only and preserve a failing tool's exit status.
main()
{
    validate_arguments "$@"
    repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "$repository_root"
    local swift_formatter shell_checker shell_formatter
    swift_formatter="$(resolve_tool swiftformat local/tools/swiftformat/swiftformat)"
    shell_checker="$(resolve_tool shellcheck local/tools/shellcheck-v0.11.0/shellcheck)"
    shell_formatter="$(resolve_tool shfmt local/tools/shfmt)"
    "$swift_formatter" src/cropprint src/composure --config src/.swiftformat --cache ignore --lint --quiet
    local sources=(src/cropprint/*.sh src/cropprint/scripts/*.sh src/composure/*.sh src/web/*.sh
        scripts/check-source-style.sh)
    "$shell_checker" -x "${sources[@]}"
    "$shell_formatter" -d -i 4 -ci -fn "${sources[@]}"
    printf '%s\n' 'Native and shell source style checks passed.'
}

main "$@"
