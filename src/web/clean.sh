#!/usr/bin/env bash

# Remove generated website files and local Wrangler state.

set -euo pipefail

web_root="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$web_root/dist"
rm -rf "$web_root/.wrangler"
rm -rf "$web_root/node_modules"

find "$web_root" -name '.DS_Store' -type f -delete
echo "Website cleanup complete."
