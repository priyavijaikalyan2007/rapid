#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: ff17b892-228a-4e18-b5bd-473f55dfb53b
# Created: 2026
# COMPONENT: preview
# PURPOSE: Build the website and start a local development preview.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

# Build the website and run a local Cloudflare preview server.

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
export WRANGLER_LOG_PATH="$web_root/.wrangler/logs/wrangler.log"
export WRANGLER_SEND_ERROR_REPORTS=false
export WRANGLER_SEND_METRICS=false

mkdir -p "$web_root/.wrangler/logs"

"$web_root/build.sh" web
cd "$web_root"
npx --no-install wrangler dev
