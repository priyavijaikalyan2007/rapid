#!/bin/bash

set -euo pipefail

script_root="$(cd "$(dirname "$0")" && pwd)"
platform="${1:-all}"

if [[ "${CONFIRM_APP_STORE_UPLOAD:-}" != "YES" ]]; then
  echo "Set CONFIRM_APP_STORE_UPLOAD=YES to authorize an App Store Connect upload." >&2
  exit 1
fi

"$script_root/archive-app-store.sh" "$platform"
"$script_root/upload-app-store.sh" "$platform"
