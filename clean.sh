#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
app_cleaners=("$repository_root"/src/*/clean.sh)

if [[ ${#app_cleaners[@]} -eq 0 ]]; then
  echo "No application clean scripts were found under $repository_root/src."
  exit 0
fi

for cleaner in "${app_cleaners[@]}"; do
  app_directory="$(dirname "$cleaner")"
  echo "Cleaning $(basename "$app_directory")"
  "$cleaner"
done

find "$repository_root" -name '.DS_Store' -type f -delete
echo "Repository cleanup complete."
