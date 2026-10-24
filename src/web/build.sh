#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 3e7b1365-c9ed-42d7-b1b8-e6ba44df0d73
# Created: 2026
# COMPONENT: build
# PURPOSE: Build and verify the owning component without publishing it.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

# Build and validate the Outcrop Inc static website.

set -euo pipefail

if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
    printf '%s\n' "Usage: $0 [mode]"
    exit 0
fi
if (($# > 1)); then
    printf '%s\n' "Usage: $0 [mode]" >&2
    exit 2
fi

web_root="$(cd "$(dirname "$0")" && pwd)"
mode="${1:-all}"

case "$mode" in
    all | web | test)
        ;;
    macos | ios)
        echo "Skipping the website for the $mode-only repository build."
        exit 0
        ;;
    *)
        echo "Usage: $0 [all|web|test|macos|ios]" >&2
        exit 2
        ;;
esac

node --test "$web_root/test"/*.test.mjs
node "$web_root/scripts/build-site.mjs"
node "$web_root/scripts/check-site.mjs" "$web_root/dist"

echo "Website build complete: $web_root/dist"
