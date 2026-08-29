#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="$project_root/build"

source "$project_root/scripts/build-metadata.sh"

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

xcodebuild \
  -quiet \
  -project "$project_root/CropPrint.xcodeproj" \
  -scheme CropPrint \
  -configuration Release \
  -derivedDataPath "$build_root/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION="$APP_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  GIT_SHA="$GIT_SHA" \
  clean build

ditto -c -k --keepParent \
  "$build_root/DerivedData/Build/Products/Release/CropPrint.app" \
  "$build_root/CropPrint-unsigned.zip"

echo "Created $build_root/CropPrint-unsigned.zip"
