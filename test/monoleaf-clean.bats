#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: fa2ba26b-cfd7-48b8-86cb-bc3b6f72450f
# COMPONENT: Monoleaf cleanup safety contracts
# PURPOSE: Remove stale generated products without touching source, dependencies, or external data.

setup() {
    repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    clean_fixture="$BATS_TEST_TMPDIR/component with spaces"
    mkdir -p "$clean_fixture"
}

prepare_component() {
    cp "$repository_root/src/app/monomark/clean.sh" "$clean_fixture/clean.sh"
}

prepare_repository() {
    cp "$repository_root/clean.sh" "$clean_fixture/clean.sh"
    mkdir -p "$clean_fixture/src/app/example"
    printf '#!/bin/bash\ntouch "$(dirname "$0")/called"\n' > "$clean_fixture/src/app/example/clean.sh"
    chmod +x "$clean_fixture/src/app/example/clean.sh"
}

@test "root cleanup rejects arguments before calling components" {
    prepare_repository
    run bash "$clean_fixture/clean.sh" unexpected
    [ "$status" -eq 2 ]
    [ ! -e "$clean_fixture/src/app/example/called" ]
}

@test "root cleanup help does not call components" {
    prepare_repository
    run bash "$clean_fixture/clean.sh" --help
    [ "$status" -eq 0 ]
    [ ! -e "$clean_fixture/src/app/example/called" ]
}

@test "component cleanup removes stale products and caches while preserving inputs" {
    prepare_component
    for directory in build .build DerivedData renderer/.cache renderer/coverage renderer/.nyc_output renderer/test-results; do
        mkdir -p "$clean_fixture/$directory"
        touch "$clean_fixture/$directory/generated"
    done
    mkdir -p "$clean_fixture/build/MonoMark.app" "$clean_fixture/build/Monoleaf.app"
    mkdir -p "$clean_fixture/apple" "$clean_fixture/renderer/node_modules/library" "$clean_fixture/.swiftpm/configuration"
    touch "$clean_fixture/apple/Keep.swift" "$clean_fixture/renderer/node_modules/library/index.js"
    touch "$clean_fixture/.swiftpm/configuration/keep.json" "$BATS_TEST_TMPDIR/reading-notes.sqlite"
    run bash "$clean_fixture/clean.sh"
    [ "$status" -eq 0 ]
    for directory in build .build DerivedData renderer/.cache renderer/coverage renderer/.nyc_output renderer/test-results; do
        [ ! -e "$clean_fixture/$directory" ]
    done
    [ -f "$clean_fixture/apple/Keep.swift" ]
    [ -f "$clean_fixture/renderer/node_modules/library/index.js" ]
    [ -f "$clean_fixture/.swiftpm/configuration/keep.json" ]
    [ -f "$BATS_TEST_TMPDIR/reading-notes.sqlite" ]
}

@test "component cleanup preflights every output before deleting any directory" {
    prepare_component
    mkdir -p "$clean_fixture/build" "$BATS_TEST_TMPDIR/outside"
    touch "$clean_fixture/build/keep" "$BATS_TEST_TMPDIR/outside/keep"
    ln -s "$BATS_TEST_TMPDIR/outside" "$clean_fixture/.build"
    run bash "$clean_fixture/clean.sh"
    [ "$status" -ne 0 ]
    [ -f "$clean_fixture/build/keep" ]
    [ -f "$BATS_TEST_TMPDIR/outside/keep" ]
}

@test "component cleanup rejects a linked renderer parent" {
    prepare_component
    mkdir -p "$clean_fixture/build" "$BATS_TEST_TMPDIR/outside/.cache"
    touch "$clean_fixture/build/keep" "$BATS_TEST_TMPDIR/outside/.cache/keep"
    ln -s "$BATS_TEST_TMPDIR/outside" "$clean_fixture/renderer"
    run bash "$clean_fixture/clean.sh"
    [ "$status" -ne 0 ]
    [ -f "$clean_fixture/build/keep" ]
    [ -f "$BATS_TEST_TMPDIR/outside/.cache/keep" ]
}

@test "component cleanup preserves an unexpected file at an output path" {
    prepare_component
    mkdir -p "$clean_fixture/build"
    touch "$clean_fixture/build/keep" "$clean_fixture/DerivedData"
    run bash "$clean_fixture/clean.sh"
    [ "$status" -ne 0 ]
    [ -f "$clean_fixture/build/keep" ]
    [ -f "$clean_fixture/DerivedData" ]
}
