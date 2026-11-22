#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 7fb0d7d0-c536-4cd3-8563-923409a9f06a
# COMPONENT: Monoleaf local cleanup
# PURPOSE: Remove generated products and caches while preserving source, dependencies, and reading state.
set -euo pipefail
if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
    printf '%s\n' 'Usage: clean.sh'
    exit 0
fi
if [[ $# -gt 0 ]]; then
    printf '%s\n' 'Usage: clean.sh' >&2
    exit 2
fi
component_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
outputs=(
    "$component_root/build"
    "$component_root/.build"
    "$component_root/DerivedData"
    "$component_root/renderer/.cache"
    "$component_root/renderer/coverage"
    "$component_root/renderer/.nyc_output"
    "$component_root/renderer/test-results"
)
if [[ "$component_root" == / || -L "$component_root/renderer" ]]; then
    printf '%s\n' 'Refusing to clean a linked or unexpected component path.' >&2
    exit 1
fi
# Validate every target before deleting any output, including ancestors of nested cache directories.
for output in "${outputs[@]}"; do
    if [[ -L "$output" || (-e "$output" && ! -d "$output") ]]; then
        printf 'Refusing to remove a linked or unexpected output: %s\n' "$output" >&2
        exit 1
    fi
done
rm -rf -- "${outputs[@]}"
find "$component_root" -name node_modules -prune -o -name .DS_Store -type f -exec rm -f -- {} +
printf '%s\n' 'Monoleaf generated products and caches removed.' \
    'Source, dependencies, and reading data were preserved.'
