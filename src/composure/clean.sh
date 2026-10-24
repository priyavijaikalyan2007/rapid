#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 8761d5cc-0f22-45f6-8849-fcfb341f613e
# Created: 2026
# COMPONENT: Composure cleanup entry point
# PURPOSE: Remove the component's generated build directory without touching source.
# RELATES: build.sh
# FLOW: Validate request -> verify owned output -> remove generated files.

set -euo pipefail

main()
{
    if [[ $# -gt 0 ]]; then
        printf '%s\n' 'Usage: clean.sh' >&2
        return 2
    fi
    local component_root
    component_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$component_root" == / || -L "$component_root/build" ]]; then
        printf '%s\n' 'Cannot clean a linked or unexpected output directory. Check the component path.' >&2
        return 1
    fi
    rm -rf -- "$component_root/build"
    printf '%s\n' 'Removed Composure build output.'
}

main "$@"
