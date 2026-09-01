#!/usr/bin/env bash

# Build and validate the Outcrop Inc static website.

set -euo pipefail

web_root="$(cd "$(dirname "$0")" && pwd)"
mode="${1:-all}"

case "$mode" in
  all|web|test)
    ;;
  macos|ios)
    echo "Skipping the website for the $mode-only repository build."
    exit 0
    ;;
  *)
    echo "Usage: $0 [all|web|test|macos|ios]" >&2
    exit 2
    ;;
esac

node "$web_root/scripts/build-site.mjs"
node "$web_root/scripts/check-site.mjs" "$web_root/dist"

echo "Website build complete: $web_root/dist"
