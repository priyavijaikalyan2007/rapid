// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 160c6f74-c655-4d26-923c-23b868bde908
// COMPONENT: Installed font application
// PURPOSE: Treat a family name as one quoted CSS string.
export function cssFontFamily(value)
{
    if (!value || value === 'ui-monospace') { return 'ui-monospace'; }
    return '"' + String(value).replaceAll('\\', '\\\\').replaceAll('"', '\\"').replace(/[\r\n\0]/g, '') + '"';
}
