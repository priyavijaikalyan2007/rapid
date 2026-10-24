#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: ebceeb1a-1079-49bc-8666-c399c2195ebf
# Created: 2026
# COMPONENT: Source style command tests
# PURPOSE: Keep style validation read-only, scoped, and reliable from paths containing spaces.
# RELATES: scripts/check-source-style.sh
# FLOW: Isolated tool fixture -> style command -> exit and routing checks.

setup()
{
    repository_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    fixture="$BATS_TEST_TMPDIR/style repository"
    mkdir -p "$fixture/scripts" "$fixture/bin" "$fixture/src/cropprint/scripts" "$fixture/src/web"
    cp "$repository_root/scripts/check-source-style.sh" "$fixture/scripts/"
    touch "$fixture/src/cropprint/build.sh" "$fixture/src/cropprint/scripts/tool.sh" "$fixture/src/web/build.sh"
    export STYLE_CALL_LOG="$fixture/calls"
    for tool in swiftformat shellcheck shfmt; do
        cat > "$fixture/bin/$tool" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "${0##*/}:$*" >> "$STYLE_CALL_LOG"
if [[ "${0##*/}" == swiftformat ]]; then exit "${STYLE_FAILURE_STATUS:-0}"; fi
STUB
        chmod +x "$fixture/bin/$tool"
    done
}

@test "source style check rejects arguments before starting a formatter" {
    run env PATH="$fixture/bin:$PATH" bash "$fixture/scripts/check-source-style.sh" unexpected
    [[ "$status" -eq 2 ]]
    [[ ! -e "$STYLE_CALL_LOG" ]]
}

@test "source style check runs read-only tools from a repository path containing spaces" {
    cd "$BATS_TEST_TMPDIR"
    run env PATH="$fixture/bin:$PATH" bash "$fixture/scripts/check-source-style.sh"
    [[ "$status" -eq 0 ]]
    [[ "$(wc -l < "$STYLE_CALL_LOG" | tr -d ' ')" -eq 3 ]]
    run cat "$STYLE_CALL_LOG"
    [[ "$output" == *'--lint'* ]]
    [[ "$output" == *'shfmt:-d '* ]]
    [[ "$output" != *'--fix'* ]]
}

@test "source style check preserves a formatter failure and stops later tools" {
    run env PATH="$fixture/bin:$PATH" STYLE_FAILURE_STATUS=7 bash "$fixture/scripts/check-source-style.sh"
    [[ "$status" -eq 7 ]]
    [[ "$(wc -l < "$STYLE_CALL_LOG" | tr -d ' ')" -eq 1 ]]
}
