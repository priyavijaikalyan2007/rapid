// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d24a7075-883e-4935-a768-2e5a9a527b77
// COMPONENT: Generated reading-section metadata
// PURPOSE: Keep app exports outside annotation targets without removing their visible content.

export function recordGeneratedMarker(line, number, state)
{
    const footer = /^<!-- monomark:reading-data:(start|end) -->$/.exec(line);
    const inline = /^<!-- monomark:inline:(notes|[a-f\d-]{36}):(start(?::join)?|end) -->$/i.exec(line);
    if (!footer && !inline) { return; }
    const id = footer ? 'footer' : inline[1];
    const starts = (footer ? footer[1] : inline[2]).startsWith('start');
    if (starts) { state.active = { id, start: number }; return; }
    if (state.active?.id === id)
    {
        state.ranges.push({ start: state.active.start, end: number + 1 });
        state.active = null;
    }
}

export function generatedLine(line, ranges)
{
    let low = 0;
    let high = ranges.length;
    while (low < high)
    {
        const middle = Math.floor((low + high) / 2);
        if (ranges[middle].end <= line) { low = middle + 1; }
        else { high = middle; }
    }
    return low < ranges.length && ranges[low].start <= line;
}
