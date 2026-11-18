// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 4f67fc54-b392-4ec7-941b-50341a046ed9
// COMPONENT: Whole-table clipboard payloads
// PURPOSE: Check encoded size before serializing a complete, unmounted table.
import { serializeRows } from './artifacts.mjs';

const delimiters = new Map([['CSV', ','], ['TSV', '\t'], ['PSV', '|']]);

function cellBytes(text, delimiter)
{
    let bytes = new TextEncoder().encode(text).length;
    if (text.includes(delimiter) || /["\r\n]/.test(text))
    {
        bytes += 2;
        for (const character of text) { if (character === '"') { bytes++; } }
    }
    return bytes;
}

export function tableClipboard(rows, format, byteLimit = 128 * 1024 * 1024)
{
    const delimiter = delimiters.get(format);
    if (!rows || !delimiter) { return { error: 'The original table is unavailable. Refresh and try again.' }; }
    let bytes = Math.max(0, rows.length - 1);
    for (const row of rows)
    {
        bytes += Math.max(0, row.length - 1);
        for (const cell of row)
        {
            bytes += cellBytes(String(cell), delimiter);
            if (bytes > byteLimit) { return { error: 'The complete table exceeds the clipboard limit. Copy a smaller selection.' }; }
        }
    }
    return { text: serializeRows(rows, delimiter) };
}
