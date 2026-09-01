#!/usr/bin/env bash

# Build and deploy the website through Cloudflare Workers Static Assets.

set -euo pipefail

web_root="$(cd "$(dirname "$0")" && pwd)"
mode="${1:-deploy}"
export WRANGLER_LOG_PATH="$web_root/.wrangler/logs/wrangler.log"
export WRANGLER_SEND_ERROR_REPORTS=false
export WRANGLER_SEND_METRICS=false

if [[ "$mode" != "deploy" && "$mode" != "--dry-run" ]]; then
  echo "Usage: $0 [--dry-run]" >&2
  exit 2
fi

"$web_root/build.sh" web
cd "$web_root"
mkdir -p "$web_root/.wrangler/logs"

if [[ "$mode" == "--dry-run" ]]; then
  npx wrangler deploy --dry-run
  exit 0
fi

npx wrangler deploy
