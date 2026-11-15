// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b46c789a-cbf9-44aa-822b-de8bff11f899
// COMPONENT: Reader color boundary
// PURPOSE: Apply validated native palette values only to supported reader elements.
const ROLES = ['heading1', 'heading2', 'heading3', 'heading4', 'heading5', 'heading6', 'caption', 'equation',
    'calloutText', 'calloutBackground', 'calloutBorder', 'tableText', 'tableBackground', 'tableHeaderBackground',
    'rowAlternate', 'columnAlternate'];

/** Authored diagram SVG and syntax token colors stay under their existing rendering rules. */
export function applyPalette(document, palettes, dark)
{
    const values = palettes?.[dark ? 'dark' : 'light'] || {};
    for (const role of ROLES)
    {
        const key = `--palette-${role}`;
        const value = values[role];
        if (typeof value === 'string' && /^#[0-9a-f]{6}$/i.test(value))
        {
            document.documentElement.style.setProperty(key, value);
        }
        else { document.documentElement.style.removeProperty(key); }
    }
}
