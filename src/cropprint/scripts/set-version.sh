#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 96f59792-4ce4-4a7f-9c53-d131d66e7a34
# Created: 2026
# COMPONENT: set-version
# PURPOSE: Validate and record the semantic version for later builds.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf '%s\n' "Usage: $0 <semantic-version>" >&2
    exit 2
fi
if [[ "$1" == --help || "$1" == -h ]]; then
    printf '%s\n' "Usage: $0 <semantic-version>"
    exit 0
fi

app_root="$(cd "$(dirname "$0")/.." && pwd)"
new_version="${1:-}"

if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Usage: $0 <semantic-version>" >&2
    echo "Example: $0 1.2.3" >&2
    exit 2
fi

printf '%s\n' "$new_version" >"$app_root/VERSION"
echo "CropPrint version is now $new_version."
