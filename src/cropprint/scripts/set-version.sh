#!/bin/bash

set -euo pipefail

app_root="$(cd "$(dirname "$0")/.." && pwd)"
new_version="${1:-}"

if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Usage: $0 <semantic-version>" >&2
  echo "Example: $0 1.2.3" >&2
  exit 2
fi

printf '%s\n' "$new_version" > "$app_root/VERSION"
echo "CropPrint version is now $new_version."
