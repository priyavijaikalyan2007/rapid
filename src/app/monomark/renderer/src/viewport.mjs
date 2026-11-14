// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ef22ebae-8a64-4a2b-a6ef-1e726ce455bd
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Select a bounded viewport by binary search.
// RELATES: specs/monomark.implementation.md
// FLOW: Source -> indexed blocks -> visible content.

/** Binary search keeps distant jumps independent of document length. */
export function lowerBound(values, value)
{
    let low = 0;
    let high = values.length;
    while (low < high)
    {
        const middle = (low + high) >>> 1;
        if (values[middle] < value) { low = middle + 1; }
        else { high = middle; }
    }
    return low;
}

/** A bounded overscan range prevents a hidden full-document DOM. */
export function windowRange(offsets, top, height, overscan = 4)
{
    const start = Math.max(0, lowerBound(offsets, top) - 1 - overscan);
    const end = Math.min(offsets.length, lowerBound(offsets, top + height) + overscan + 1, start + 80);
    return { start, end };
}
