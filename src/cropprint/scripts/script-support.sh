#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 135c8cf2-1ca5-4e47-a9b3-8caa464e735f
# Created: 2026
# COMPONENT: CropPrint script argument policy
# PURPOSE: Validate command arguments before builds, cleanup, or release operations.
# RELATES: ../build.sh, archive-app-store.sh, upload-app-store.sh
# FLOW: Argument count and mode -> validation -> component operation.

# Accept one optional mode, or print help and stop the calling command.
validate_mode()
{
    local selected_mode="$1"
    local argument_count="$2"
    local usage_text="$3"
    shift 3
    if ((argument_count > 1)); then
        printf '%s\n' "$usage_text" >&2
        return 2
    fi
    if [[ "$selected_mode" == --help || "$selected_mode" == -h ]]; then
        printf '%s\n' "$usage_text"
        exit 0
    fi
    local allowed_mode
    for allowed_mode in "$@"; do
        if [[ "$selected_mode" == "$allowed_mode" ]]; then
            return 0
        fi
    done
    printf '%s\n' "$usage_text" >&2
    return 2
}

# Commands without a mode must reject positional arguments before touching files.
validate_no_arguments()
{
    local argument_count="$1"
    local first_argument="$2"
    local usage_text="$3"
    if ((argument_count == 0)); then
        return 0
    fi
    if ((argument_count == 1)) && [[ "$first_argument" == --help || "$first_argument" == -h ]]; then
        printf '%s\n' "$usage_text"
        exit 0
    fi
    printf '%s\n' "$usage_text" >&2
    return 2
}

# Require archive provenance to match this exact clean source, version, and build.
validate_archive_identity()
{
    local archive_path="$1" expected_sha="$2" expected_version="$3" expected_build="$4"
    local application_plists=("$archive_path"/Products/Applications/*.app/Info.plist)
    if [[ ${#application_plists[@]} -ne 1 || ! -f "${application_plists[0]}" ]]; then
        printf '%s\n' 'The archive does not contain one identifiable application. Create a new archive.' >&2
        return 1
    fi
    local archived_sha archived_version archived_build
    archived_sha="$(plutil -extract CropPrintGitSHA raw "${application_plists[0]}" 2>/dev/null)" || return 1
    archived_version="$(plutil -extract CFBundleShortVersionString raw "${application_plists[0]}" 2>/dev/null)" || return 1
    archived_build="$(plutil -extract CFBundleVersion raw "${application_plists[0]}" 2>/dev/null)" || return 1
    if [[ "$archived_sha" != "$expected_sha" || "$archived_version" != "$expected_version" || "$archived_build" != "$expected_build" ]]; then
        printf '%s\n' 'The archive does not match this source, version, and build. Create a new archive before upload.' >&2
        return 1
    fi
}
