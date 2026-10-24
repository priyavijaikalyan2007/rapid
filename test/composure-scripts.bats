#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: cee78758-eec5-4489-ad71-4d00f6e22883
# Created: 2026
# COMPONENT: Composure command contracts
# PURPOSE: Reject invalid requests before builds or cleanup can change files.
# RELATES: src/composure/build.sh, src/composure/clean.sh
# FLOW: Isolated component path -> command -> exit and side-effect checks.

setup()
{
    repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    fixture="$BATS_TEST_TMPDIR/composure with spaces"
    mkdir -p "$fixture"
    cp "$repository_root/src/composure/build.sh" "$repository_root/src/composure/clean.sh" "$fixture/"
}

@test "Composure rejects unknown build modes before creating output" {
    run bash "$fixture/build.sh" unexpected
    [[ "$status" -eq 2 ]]
    [[ ! -e "$fixture/build" ]]
}

@test "Composure rejects extra build arguments before creating output" {
    run bash "$fixture/build.sh" test unexpected
    [[ "$status" -eq 2 ]]
    [[ ! -e "$fixture/build" ]]
}

@test "Composure cleanup rejects arguments and preserves output" {
    mkdir -p "$fixture/build"
    touch "$fixture/build/retained"
    run bash "$fixture/clean.sh" unexpected
    [[ "$status" -eq 2 ]]
    [[ -f "$fixture/build/retained" ]]
}

@test "Composure skips website-only builds without starting Xcode" {
    run bash "$fixture/build.sh" web
    [[ "$status" -eq 0 ]]
    [[ ! -e "$fixture/build" ]]
}

@test "Composure cleanup removes only owned build output" {
    mkdir -p "$fixture/build" "$fixture/Packages/ComposureCore"
    touch "$fixture/build/generated" "$fixture/Packages/ComposureCore/source"
    run bash "$fixture/clean.sh"
    [[ "$status" -eq 0 ]]
    [[ ! -e "$fixture/build" ]]
    [[ -f "$fixture/Packages/ComposureCore/source" ]]
}

@test "Composure cleanup rejects a linked output directory" {
    mkdir -p "$fixture/source"
    touch "$fixture/source/retained"
    ln -s "$fixture/source" "$fixture/build"
    run bash "$fixture/clean.sh"
    [[ "$status" -eq 1 ]]
    [[ -f "$fixture/source/retained" ]]
}
