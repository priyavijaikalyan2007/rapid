#!/bin/bash

set -euo pipefail

app_root="$(cd "$(dirname "$0")" && pwd)"
build_root="$app_root/build"

if [[ "$build_root" != "$app_root/build" || "$app_root" == "/" ]]; then
  echo "Refusing to clean an unexpected path: $build_root" >&2
  exit 1
fi

rm -rf "$build_root"

find "$app_root" -name '.DS_Store' -type f -delete
find "$app_root" -name 'xcuserdata' -type d -prune -exec rm -rf {} +
find "$app_root" -name '.build' -type d -prune -exec rm -rf {} +
find "$app_root" -name '.swiftpm' -type d -prune -exec rm -rf {} +
find "$app_root" -name 'DerivedData' -type d -prune -exec rm -rf {} +

echo "Cleaned CropPrint temporary files and build outputs."
