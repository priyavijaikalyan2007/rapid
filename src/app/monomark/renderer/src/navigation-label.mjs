// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 450ed120-6e23-48e2-9816-306ab5a244fe
// COMPONENT: Bounded navigation metadata
// PURPOSE: Avoid large labels and preserve whole Unicode characters at the native boundary.
export function boundedLabel(value, limit = 512)
{
    return Array.from(String(value).slice(0, limit * 2)).slice(0, limit).join('');
}
