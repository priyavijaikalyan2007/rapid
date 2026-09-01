#!/usr/bin/env bash

# Build the website and run a local Cloudflare preview server.

set -euo pipefail

web_root="$(cd "$(dirname "$0")" && pwd)"
export WRANGLER_LOG_PATH="$web_root/.wrangler/logs/wrangler.log"
export WRANGLER_SEND_ERROR_REPORTS=false
export WRANGLER_SEND_METRICS=false

mkdir -p "$web_root/.wrangler/logs"

"$web_root/build.sh" web
cd "$web_root"
npx wrangler dev
