#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")" && pwd)"
mode="${1:-all}"
shopt -s nullglob
app_builders=("$repository_root"/src/*/build.sh)

if [[ ${#app_builders[@]} -eq 0 ]]; then
  echo "No application build scripts were found under $repository_root/src."
  exit 1
fi

if [[ "$mode" == "web" ]]; then
  web_builder="$repository_root/src/web/build.sh"
  if [[ ! -x "$web_builder" ]]; then
    echo "The website build script was not found: $web_builder" >&2
    exit 1
  fi

  "$web_builder" web
  echo "Repository web build complete."
  exit 0
fi

for builder in "${app_builders[@]}"; do
  app_directory="$(dirname "$builder")"
  echo "Building $(basename "$app_directory")"
  "$builder" "$@"
done

echo "Repository build complete."
