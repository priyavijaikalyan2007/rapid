#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
app_builders=("$repository_root"/src/*/build.sh)

if [[ ${#app_builders[@]} -eq 0 ]]; then
  echo "No application build scripts were found under $repository_root/src."
  exit 1
fi

for builder in "${app_builders[@]}"; do
  app_directory="$(dirname "$builder")"
  echo "Building $(basename "$app_directory")"
  "$builder" "$@"
done

echo "Repository build complete."
