#!/bin/bash

set -euo pipefail

app_root="$(cd "$(dirname "$0")/.." && pwd)"
media_root="$app_root/AppStore/Media"
sample_photo="$media_root/Source/sample-landscape.png"
derived_data="$app_root/build/AppStoreMediaDerivedData"
tool_path="$app_root/build/AppStoreMediaTools/normalize-app-preview"
window_tool_path="$app_root/build/AppStoreMediaTools/macos-window-info"
bundle_id="us.outcrop.apps.cropprint"
iphone_id="${CROPPRINT_IPHONE_SIMULATOR_ID:-FCA4E1CC-1F43-40A6-9498-74BF7D8E2354}"
ipad_id="${CROPPRINT_IPAD_SIMULATOR_ID:-2145876A-3017-446F-AF97-026D073D1698}"
mode="${1:-all}"

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

if [[ ! -f "$sample_photo" ]]; then
  echo "Sample photo not found: $sample_photo" >&2
  exit 1
fi

mkdir -p "$media_root/iPhone" "$media_root/iPad" "$media_root/macOS"
mkdir -p "$derived_data" "$(dirname "$tool_path")"

build_mobile() {
  xcodebuild build -quiet \
    -project "$app_root/CropPrint.xcodeproj" \
    -scheme "CropPrint Mobile" \
    -configuration Debug \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO
}

build_macos() {
  xcodebuild build -quiet \
    -project "$app_root/CropPrint.xcodeproj" \
    -scheme CropPrint \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO
}

build_preview_tool() {
  xcrun swiftc -parse-as-library \
    "$app_root/scripts/normalize-app-preview.swift" \
    -framework AVFoundation \
    -framework CoreImage \
    -o "$tool_path"
  xcrun swiftc \
    "$app_root/scripts/macos-window-info.swift" \
    -framework CoreGraphics \
    -o "$window_tool_path"
}

verify_image_size() {
  local path="$1"
  local expected_width="$2"
  local expected_height="$3"
  local width
  local height
  width="$(sips -g pixelWidth "$path" | awk '/pixelWidth/{print $2}')"
  height="$(sips -g pixelHeight "$path" | awk '/pixelHeight/{print $2}')"
  if [[ "$width" != "$expected_width" || "$height" != "$expected_height" ]]; then
    echo "Unexpected size for $path: ${width}x${height}" >&2
    return 1
  fi
}

normalize_image_size() {
  local image_path="$1"
  local target_width="$2"
  local target_height="$3"
  local current_width
  local current_height
  current_width="$(sips -g pixelWidth "$image_path" | awk '/pixelWidth/{print $2}')"
  current_height="$(sips -g pixelHeight "$image_path" | awk '/pixelHeight/{print $2}')"

  if (( current_width * target_height > current_height * target_width )); then
    sips --resampleHeight "$target_height" "$image_path" >/dev/null
  else
    sips --resampleWidth "$target_width" "$image_path" >/dev/null
  fi
  sips --cropToHeightWidth "$target_height" "$target_width" "$image_path" >/dev/null
  verify_image_size "$image_path" "$target_width" "$target_height"
}

prepare_simulator() {
  local device_id="$1"
  local app_path="$derived_data/Build/Products/Debug-iphonesimulator/CropPrint Mobile.app"
  xcrun simctl boot "$device_id" 2>/dev/null || true
  open -a Simulator --args -CurrentDeviceUDID "$device_id"
  xcrun simctl bootstatus "$device_id" -b
  xcrun simctl install "$device_id" "$app_path"
  xcrun simctl ui "$device_id" appearance light
  xcrun simctl status_bar "$device_id" override \
    --time 9:41 \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4 2>/dev/null || true

  local container
  container="$(xcrun simctl get_app_container "$device_id" "$bundle_id" data)"
  mkdir -p "$container/Documents"
  cp "$sample_photo" "$container/Documents/CropPrint-Screenshot-Sample.png"
}

capture_simulator_set() {
  local device_id="$1"
  local output_root="$2"
  local width="$3"
  local height="$4"
  local scenarios="crop decorate passport print-sheet true-size resources"
  local names="01-crop-selection 02-text-and-frame 03-passport-preset 04-print-sheet 05-true-size 06-remote-resources"
  local scenario
  local name
  local index=1
  local container
  container="$(xcrun simctl get_app_container "$device_id" "$bundle_id" data)"

  for scenario in $scenarios; do
    name="$(echo "$names" | awk -v position="$index" '{print $position}')"
    xcrun simctl launch --terminate-running-process \
      "$device_id" "$bundle_id" \
      --app-store-screenshot "$scenario" \
      --screenshot-photo "$container/Documents/CropPrint-Screenshot-Sample.png" >/dev/null
    sleep 3
    xcrun simctl io "$device_id" screenshot --type=png --mask=black \
      "$output_root/$name.png" >/dev/null
    if ! verify_image_size "$output_root/$name.png" "$width" "$height"; then
      normalize_image_size "$output_root/$name.png" "$width" "$height"
    fi
    xcrun simctl terminate "$device_id" "$bundle_id" 2>/dev/null || true
    index=$((index + 1))
  done
}

record_simulator_preview() {
  local device_id="$1"
  local output_root="$2"
  local width="$3"
  local height="$4"
  local raw_path="$output_root/CropPrint-preview-raw.mov"
  local final_path="$output_root/CropPrint-preview.mp4"
  local container
  container="$(xcrun simctl get_app_container "$device_id" "$bundle_id" data)"

  xcrun simctl launch --terminate-running-process \
    "$device_id" "$bundle_id" \
    --app-store-screenshot preview \
    --screenshot-photo "$container/Documents/CropPrint-Screenshot-Sample.png" >/dev/null
  xcrun simctl io "$device_id" recordVideo --codec=h264 --mask=black --force "$raw_path" &
  local record_pid=$!
  sleep 18
  kill -INT "$record_pid"
  wait "$record_pid"
  "$tool_path" "$raw_path" "$final_path" "$width" "$height"
  rm "$raw_path"
}

capture_iphone() {
  prepare_simulator "$iphone_id"
  capture_simulator_set "$iphone_id" "$media_root/iPhone" 1284 2778
  record_simulator_preview "$iphone_id" "$media_root/iPhone" 886 1920
}

capture_ipad() {
  prepare_simulator "$ipad_id"
  capture_simulator_set "$ipad_id" "$media_root/iPad" 2064 2752
  record_simulator_preview "$ipad_id" "$media_root/iPad" 1200 1600
}

launch_macos_scenario() {
  local scenario="$1"
  local app_path="$derived_data/Build/Products/Debug/CropPrint.app"
  pkill -x CropPrint 2>/dev/null || true
  open -na "$app_path" --args \
    --app-store-screenshot "$scenario" \
    --screenshot-photo "$sample_photo"
}

capture_macos() {
  local scenarios="crop decorate passport print-sheet true-size resources"
  local names="01-crop-selection 02-text-and-frame 03-passport-preset 04-print-sheet 05-true-size 06-remote-resources"
  local scenario
  local name
  local index=1
  local window_info
  local window_id
  local window_x
  local window_y
  local window_width
  local window_height

  # Keep Simulator content out of the desktop behind the rounded window corners.
  pkill -x Simulator 2>/dev/null || true

  for scenario in $scenarios; do
    name="$(echo "$names" | awk -v position="$index" '{print $position}')"
    launch_macos_scenario "$scenario"
    sleep 3
    window_info="$("$window_tool_path" CropPrint)"
    read -r window_id window_x window_y window_width window_height <<< "$window_info"
    screencapture -x -R"$window_x,$window_y,$window_width,$window_height" \
      "$media_root/macOS/$name.png"
    if ! verify_image_size "$media_root/macOS/$name.png" 2560 1600; then
      sips --resampleHeightWidth 1600 2560 "$media_root/macOS/$name.png" >/dev/null
      verify_image_size "$media_root/macOS/$name.png" 2560 1600
    fi
    index=$((index + 1))
  done

  launch_macos_scenario preview
  sleep 1
  window_info="$("$window_tool_path" CropPrint)"
  read -r window_id window_x window_y window_width window_height <<< "$window_info"
  screencapture -x -v -V 20 -R"$window_x,$window_y,$window_width,$window_height" \
    "$media_root/macOS/CropPrint-preview-raw.mov"
  "$tool_path" \
    "$media_root/macOS/CropPrint-preview-raw.mov" \
    "$media_root/macOS/CropPrint-preview.mp4" \
    1920 1080
  rm "$media_root/macOS/CropPrint-preview-raw.mov"
  pkill -x CropPrint 2>/dev/null || true
}

build_preview_tool
case "$mode" in
  all)
    build_mobile
    capture_iphone
    capture_ipad
    build_macos
    capture_macos
    ;;
  iphone)
    build_mobile
    capture_iphone
    ;;
  ipad)
    build_mobile
    capture_ipad
    ;;
  macos)
    build_macos
    capture_macos
    ;;
  *)
    echo "Usage: $0 [all|iphone|ipad|macos]" >&2
    exit 2
    ;;
esac

echo "App Store media is ready under $media_root."
