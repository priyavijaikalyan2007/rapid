#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 25f54b07-b3e8-437a-865c-162706914aaf
# Created: 2026
# COMPONENT: deploy
# PURPOSE: Run the explicitly selected website deployment operation.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

# Build and deploy the website through Cloudflare Workers Static Assets.

set -euo pipefail

if [[ $# -eq 1 && ("$1" == --help || "$1" == -h) ]]; then
    printf '%s\n' "Usage: $0 [--dry-run|deploy]"
    exit 0
fi
if (($# > 1)); then
    printf '%s\n' "Usage: $0 [--dry-run|deploy]" >&2
    exit 2
fi

web_root="$(cd "$(dirname "$0")" && pwd)"
mode="${1:-}"
export WRANGLER_LOG_PATH="$web_root/.wrangler/logs/wrangler.log"
export WRANGLER_SEND_ERROR_REPORTS=false
export WRANGLER_SEND_METRICS=false

if [[ "$mode" != "deploy" && "$mode" != "--dry-run" ]]; then
    echo "Usage: $0 [--dry-run|deploy]" >&2
    exit 2
fi

"$web_root/build.sh" web
cd "$web_root"
mkdir -p "$web_root/.wrangler/logs"

if [[ "$mode" == "--dry-run" ]]; then
    npx --no-install wrangler deploy --dry-run
    exit 0
fi

npx --no-install wrangler deploy
