#!/bin/bash
# SPDX-FileCopyrightText: 2026 Vijai Kalyan
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: cfa3e47e-1a9d-4904-a756-2d2503b94b75
# Created: 2026
# COMPONENT: build-metadata
# PURPOSE: Resolve source version and Git provenance for native build arguments.
# RELATES: PROJECT.md, instructions/WORKFLOW.md
# FLOW: Authored source -> component validation -> local result.

metadata_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
metadata_app_root="$(cd "$metadata_script_root/.." && pwd)"

if [[ ! -f "$metadata_app_root/VERSION" ]]; then
    echo "Missing version file: $metadata_app_root/VERSION" >&2
    # This file runs both as a sourced library and as a direct command.
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

APP_VERSION="${APP_VERSION:-$(tr -d '[:space:]' <"$metadata_app_root/VERSION")}"
if [[ ! "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
    echo "VERSION must contain a semantic version such as 1.2.3." >&2
    # This file runs both as a sourced library and as a direct command.
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

if git -C "$metadata_app_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
    git -C "$metadata_app_root" rev-parse --verify HEAD >/dev/null 2>&1; then
    GIT_FULL_SHA="${GIT_FULL_SHA:-$(git -C "$metadata_app_root" rev-parse HEAD)}"
    GIT_SHA="${GIT_SHA:-$(git -C "$metadata_app_root" rev-parse --short=12 HEAD)}"
    BUILD_NUMBER="${BUILD_NUMBER:-$(git -C "$metadata_app_root" rev-list --count HEAD)}"
    if [[ -n "$(git -C "$metadata_app_root" status --porcelain --untracked-files=normal)" && "$GIT_SHA" != *-dirty ]]; then
        GIT_SHA="$GIT_SHA-dirty"
    fi
else
    GIT_FULL_SHA="${GIT_FULL_SHA:-nogit}"
    GIT_SHA="${GIT_SHA:-nogit}"
    BUILD_NUMBER="${BUILD_NUMBER:-1}"
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "BUILD_NUMBER must contain only digits." >&2
    # This file runs both as a sourced library and as a direct command.
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

export APP_VERSION GIT_FULL_SHA GIT_SHA BUILD_NUMBER
echo "Build info: CropPrint $APP_VERSION+$GIT_SHA (build $BUILD_NUMBER)"
