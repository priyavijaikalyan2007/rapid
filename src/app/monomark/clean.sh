#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: 7fb0d7d0-c536-4cd3-8563-923409a9f06a
# COMPONENT: MonoMark local cleanup
# PURPOSE: Remove only component-owned build output and preserve user reading state.
set -euo pipefail
if [[ $# -gt 0 ]]; then
    printf '%s\n' 'Usage: clean.sh' >&2
    exit 2
fi
component_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -L "$component_root/build" ]]; then
    printf '%s\n' 'Refusing to remove a symbolic build directory.' >&2
    exit 1
fi
rm -rf -- "$component_root/build"
printf '%s\n' 'MonoMark build output removed. Reading history and settings were preserved.'
