#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 3195ca53-f860-4f0d-a3f1-c1e469e8f081
# Created: 2026
# COMPONENT: Component script boundary tests
# PURPOSE: Reject invalid arguments before build, cleanup, or publishing side effects.
# RELATES: src/cropprint/scripts/, src/web/
# FLOW: Isolated fixture -> command arguments -> status and side-effect assertions.

setup()
{
    repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    fixture="$BATS_TEST_TMPDIR/source repository"
    mkdir -p "$fixture/src/cropprint/scripts" "$fixture/src/web" "$fixture/config" "$fixture/bin"
    cp "$repository_root"/src/cropprint/*.sh "$fixture/src/cropprint/"
    cp "$repository_root"/src/cropprint/scripts/*.sh "$fixture/src/cropprint/scripts/"
    cp "$repository_root"/src/web/*.sh "$fixture/src/web/"
    cp "$repository_root/config/apple-developer.env" "$fixture/config/"
    printf '%s\n' '1.0.0' > "$fixture/src/cropprint/VERSION"
    export CALL_LOG="$fixture/calls"
    component_test_path="$fixture/bin:$PATH"
    for command_name in git xcodebuild xcrun ditto node npx open sips rm find; do
        cat > "$fixture/bin/$command_name" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "${0##*/}" >> "$CALL_LOG"
exit 99
STUB
        chmod +x "$fixture/bin/$command_name"
    done
}

@test "CropPrint build rejects extra arguments before reading Git or starting Xcode" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/build.sh" test unexpected
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "CropPrint packaging rejects extra arguments before starting Xcode" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/scripts/package-unsigned.sh" unexpected
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "version updates reject extra arguments before changing VERSION" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/scripts/set-version.sh" 2.0.0 unexpected
    [[ "$status" -eq 2 ]]
    [[ "$(cat "$fixture/src/cropprint/VERSION")" == '1.0.0' ]]
}

@test "archive rejects an invalid platform before reading credentials or creating output" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/scripts/archive-app-store.sh" unknown
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "upload rejects an invalid platform before reading credentials or creating output" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/scripts/upload-app-store.sh" unknown
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "media capture rejects an invalid mode before starting tools" {
    run env PATH="$component_test_path" bash "$fixture/src/cropprint/scripts/capture-app-store-media.sh" unknown
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "component cleanup rejects arguments before deleting files" {
    for component in cropprint web; do
        run env PATH="$component_test_path" bash "$fixture/src/$component/clean.sh" unexpected
        [[ "$status" -eq 2 ]]
    done
    [[ ! -e "$CALL_LOG" ]]
}

@test "website commands reject extra arguments before starting build or deployment tools" {
    for operation in build deploy preview; do
        run env PATH="$component_test_path" bash "$fixture/src/web/$operation.sh" web unexpected
        [[ "$status" -eq 2 ]]
    done
    [[ ! -e "$CALL_LOG" ]]
}

@test "archive identity validation rejects stale source before upload" {
    archive="$fixture/stale.xcarchive"
    mkdir -p "$archive/Products/Applications/CropPrint.app"
    cat > "$archive/Products/Applications/CropPrint.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CropPrintGitSHA</key><string>stale</string><key>CFBundleShortVersionString</key><string>1.0.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>
PLIST
    run bash -c 'source "$1"; validate_archive_identity "$2" current 1.0.0 1' _ "$fixture/src/cropprint/scripts/script-support.sh" "$archive"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *'does not match'* ]]
}

@test "archive identity validation accepts the exact source version and build" {
    archive="$fixture/current.xcarchive"
    mkdir -p "$archive/Products/Applications/CropPrint.app"
    cat > "$archive/Products/Applications/CropPrint.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CropPrintGitSHA</key><string>current</string><key>CFBundleShortVersionString</key><string>1.0.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>
PLIST
    run bash -c 'source "$1"; validate_archive_identity "$2" current 1.0.0 1' _ "$fixture/src/cropprint/scripts/script-support.sh" "$archive"
    [[ "$status" -eq 0 ]]
}
