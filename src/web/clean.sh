#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: e1157007-3f76-47e6-a1d3-e3a48e5a2eed
# Created: 2026
# COMPONENT: clean
# PURPOSE: Remove only generated output and documented component caches.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

# Remove generated website files and local Wrangler state.

set -euo pipefail

if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
    printf '%s\n' "Usage: $0"
    exit 0
fi
if (($# > 0)); then
    printf '%s\n' "Usage: $0" >&2
    exit 2
fi

web_root="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$web_root/dist"
rm -rf "$web_root/.wrangler"
rm -rf "$web_root/node_modules"

find "$web_root" -name '.DS_Store' -type f -delete
echo "Website cleanup complete."
