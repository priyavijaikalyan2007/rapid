#!/bin/bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 3d6423f9-63b1-4cc7-a851-e69984428437
# COMPONENT: Repository cleanup routing
# PURPOSE: Validate the request before invoking component-owned output cleanup.

set -euo pipefail

if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
    printf '%s\n' 'Usage: clean.sh'
    exit 0
fi
if [[ $# -gt 0 ]]; then
    printf '%s\n' 'Usage: clean.sh' >&2
    exit 2
fi

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
shopt -s nullglob
app_cleaners=("$repository_root"/src/*/clean.sh "$repository_root"/src/app/*/clean.sh)

if [[ ${#app_cleaners[@]} -eq 0 ]]; then
    echo "No application clean scripts were found under $repository_root/src."
    exit 0
fi

for cleaner in "${app_cleaners[@]}"; do
    app_directory="$(dirname -- "$cleaner")"
    echo "Cleaning $(basename -- "$app_directory")"
    "$cleaner"
done

find "$repository_root/src" -name '.DS_Store' -type f -delete
rm -f -- "$repository_root/.DS_Store"
echo "Repository cleanup complete."
