#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 028cfce5-1081-4b17-b7bc-8be72cf35501
# COMPONENT: MonoMark build contracts
# PURPOSE: Keep unsupported build requests away from native and package tools.

setup() { repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }
@test "MonoMark rejects unknown modes before tool discovery" {
    run "$repository_root/src/app/monomark/build.sh" unknown
    [ "$status" -eq 2 ]
}
@test "MonoMark rejects extra build arguments" {
    run "$repository_root/src/app/monomark/build.sh" macos extra
    [ "$status" -eq 2 ]
}
@test "MonoMark web mode does not run native tools" {
    run "$repository_root/src/app/monomark/build.sh" web
    [ "$status" -eq 0 ]
    [[ "$output" == *"no website"* ]]
}
@test "MonoMark cleanup rejects arguments before deletion" {
    run "$repository_root/src/app/monomark/clean.sh" extra
    [ "$status" -eq 2 ]
}
@test "root build discovers native apps in the named app folder" {
    fixture="$BATS_TEST_TMPDIR/root-build"
    mkdir -p "$fixture/src/app/fake"
    cp "$repository_root/build.sh" "$fixture/build.sh"
    printf '#!/bin/sh\nprintf "nested app built\\n"\n' > "$fixture/src/app/fake/build.sh"
    chmod +x "$fixture/src/app/fake/build.sh"
    run bash "$fixture/build.sh" macos
    [ "$status" -eq 0 ]
    [[ "$output" == *"nested app built"* ]]
}
@test "root test routes MonoMark to its owning component" {
    fixture="$BATS_TEST_TMPDIR/root-test"
    mkdir -p "$fixture/src/app/monomark"
    cp "$repository_root/test.sh" "$fixture/test.sh"
    printf '#!/bin/sh\nexit 0\n' > "$fixture/configure.sh"
    printf '#!/bin/sh\nprintf "monomark tests\\n"\n' > "$fixture/src/app/monomark/build.sh"
    chmod +x "$fixture/configure.sh" "$fixture/src/app/monomark/build.sh"
    run bash "$fixture/test.sh" monomark
    [ "$status" -eq 0 ]
    [[ "$output" == *"monomark tests"* ]]
}

@test "MonoMark archive rejects unsupported arguments before signing" {
    run "$repository_root/src/app/monomark/tools/archive-app-store" upload
    [ "$status" -eq 2 ]
}

@test "MonoMark archive rejects extra arguments before signing" {
    run "$repository_root/src/app/monomark/tools/archive-app-store" --dry-run extra
    [ "$status" -eq 2 ]
}

@test "MonoMark archive dry run describes local Mac export only" {
    run "$repository_root/src/app/monomark/tools/archive-app-store" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"MonoMark.xcodeproj"* ]]
    [[ "$output" == *"-exportArchive"* ]]
    [[ "$output" != *"CropPrint"* ]]
    [[ "$output" != *"-upload"* ]]
}

@test "MonoMark archive rejects an uncommitted source tree" {
    fixture="$BATS_TEST_TMPDIR/archive-fixture"
    mkdir -p "$fixture/src/app/monomark/tools" "$fixture/config"
    cp "$repository_root/src/app/monomark/tools/archive-app-store" "$fixture/src/app/monomark/tools/"
    cp "$repository_root/config/apple-developer.env" "$fixture/config/"
    git -C "$fixture" init -q
    git -C "$fixture" -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm baseline
    run "$fixture/src/app/monomark/tools/archive-app-store"
    [ "$status" -ne 0 ]
    [[ "$output" == *"clean Git commit"* ]]
}
