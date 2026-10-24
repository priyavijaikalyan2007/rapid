#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 6e94cd72-7dfd-47ce-9ed4-96f017e02475
# Created: 2026
# AGENT: Exercises root command contracts against isolated component stubs.
# Bats requires each @test opening brace on the declaration line.

setup()
{
    repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    fixture="$BATS_TEST_TMPDIR/repository with spaces"
    mkdir -p "$fixture/src/cropprint/scripts" "$fixture/src/web" "$fixture/src/composure" "$fixture/bin"
    export CALL_LOG="$fixture/calls"
    export BATS_BIN="$fixture/bin/bats"
    export PATH="$fixture/bin:$PATH"
    for operation in test run package smoke deploy; do
        if [[ -f "$repository_root/$operation.sh" ]]; then
            cp "$repository_root/$operation.sh" "$fixture/$operation.sh"
        fi
    done
    for target in configure.sh src/cropprint/build.sh src/cropprint/scripts/package-unsigned.sh \
        src/web/build.sh src/web/preview.sh src/web/deploy.sh src/composure/build.sh bin/python3 bin/bats; do
        cat > "$fixture/$target" <<'STUB'
#!/usr/bin/env bash
printf '%s' "${0##*/}" >> "$CALL_LOG"
printf ' <%s>' "$@" >> "$CALL_LOG"
printf '\n' >> "$CALL_LOG"
exit "${STUB_STATUS:-0}"
STUB
        chmod +x "$fixture/$target"
    done
}

@test "website tests run the component test mode from another directory" {
    run bash "$fixture/test.sh" web
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == $'configure.sh <--check>\nbuild.sh <test>' ]]
}

@test "default tests validate repository contracts and all components" {
    run bash "$fixture/test.sh"
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == *$'build.sh <test>\nbuild.sh <test>\nbuild.sh <test>' ]]
    [[ "$(cat "$CALL_LOG")" == *'python3 <-m> <unittest>'* ]]
    [[ "$(cat "$CALL_LOG")" == *'bats <'* ]]
}

@test "Composure tests route to the owning component" {
    run bash "$fixture/test.sh" composure
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == $'configure.sh <--check>\nbuild.sh <test>' ]]
}

@test "unknown test mode cannot run a component" {
    run bash "$fixture/test.sh" unknown
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "test failures preserve their exit status" {
    run env STUB_STATUS=7 bash "$fixture/test.sh" web
    [[ "$status" -eq 7 ]]
}

@test "run website delegates to the local preview" {
    run bash "$fixture/run.sh" web
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == 'preview.sh <>' ]]
}

@test "run without a component does not launch anything" {
    run bash "$fixture/run.sh"
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "unsigned packaging uses only the macOS development packager" {
    run bash "$fixture/package.sh" macos
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == 'package-unsigned.sh <>' ]]
}

@test "package cannot select App Store publishing" {
    run bash "$fixture/package.sh" app-store
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "deployment requires an explicit mode" {
    run bash "$fixture/deploy.sh"
    [[ "$status" -eq 2 ]]
    [[ ! -e "$CALL_LOG" ]]
}

@test "deployment dry run delegates the exact flag" {
    run bash "$fixture/deploy.sh" --dry-run
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == 'deploy.sh <--dry-run>' ]]
}

@test "website smoke check runs local generated-site validation" {
    run bash "$fixture/smoke.sh" web
    [[ "$status" -eq 0 ]]
    [[ "$(cat "$CALL_LOG")" == 'build.sh <test>' ]]
}

@test "help for each command has no component side effects" {
    for operation in test run package smoke deploy; do
        run bash "$fixture/$operation.sh" --help
        [[ "$status" -eq 0 ]]
    done
    [[ ! -e "$CALL_LOG" ]]
}

@test "extra arguments cannot reach a component" {
    for operation in test run package smoke deploy; do
        run bash "$fixture/$operation.sh" web unexpected
        [[ "$status" -eq 2 ]]
    done
    [[ ! -e "$CALL_LOG" ]]
}
