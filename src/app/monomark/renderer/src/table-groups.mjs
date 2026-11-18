// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c300fc8c-c78c-43db-9b91-44110a3020c4
// COMPONENT: Bounded large-table groups
// PURPOSE: Divide Markdown tables at complete rows and keep consistent column geometry.
import { inlineText } from './selection-text.mjs';

const rowLimit = 64;
const cellLimit = 2048;
const characterLimit = 128 * 1024;

function rowsBetween(tokens, start, end)
{
    const rows = [];
    for (let index = start; index < end;)
    {
        const first = index++;
        while (index < end && tokens[index - 1].type !== 'tr_close') { index++; }
        rows.push(tokens.slice(first, index));
    }
    return rows;
}

function columnWidths(tokens, count)
{
    const widths = Array.from({ length: count }, () => 4);
    let column = 0;
    for (const token of tokens)
    {
        if (token.type === 'tr_open') { column = 0; }
        if (token.type === 'inline') { widths[column] = Math.max(widths[column], Math.min(64, token.content.length + 2)); }
        if (['th_close', 'td_close'].includes(token.type)) { column++; }
    }
    const total = widths.reduce((sum, width) => sum + width, 0);
    return widths.map(width => (100 * width / total).toFixed(4));
}

function rowGroups(rows, columns, headerCharacters)
{
    const groups = [];
    let current = [];
    let characters = headerCharacters;
    let cells = columns;
    for (const row of rows)
    {
        const length = row.reduce((sum, token) => sum + (token.content?.length || 0), 0);
        if (current.length && (current.length >= rowLimit || cells + columns > cellLimit ||
            characters + length > characterLimit))
        { groups.push(current); current = []; characters = headerCharacters; cells = columns; }
        current.push(row); characters += length; cells += columns;
    }
    if (current.length) { groups.push(current); }
    return groups;
}

function clone(token)
{
    return Object.assign(Object.create(Object.getPrototypeOf(token)), token,
        { attrs: token.attrs?.map(pair => [...pair]) || null, children: null, meta: { ...token.meta } });
}

function groupTokens(prefix, rows, suffix, part, rowStart)
{
    const header = prefix.map(clone);
    if (part) { for (const token of header) { if (token.type === 'inline') { token.meta.repeatedTableHeader = true; } } }
    const body = rows.flatMap((row, index) => row.map(token =>
    {
        const copy = clone(token);
        if (copy.type === 'tr_open') { copy.attrSet('data-row-alternate', String((rowStart + index) % 2 === 1)); }
        return copy;
    }));
    return [...header, ...body, ...suffix.map(clone)];
}

/** Independent groups retain the original table map, so inline exports follow the complete table. */
export function tableGroups(tokens)
{
    if (tokens[0]?.type !== 'table_open' || tokens.at(-1)?.type !== 'table_close') { return null; }
    const columns = tokens.filter(token => token.type === 'th_open').length;
    if (columns > 1024) { return { unsupported: true }; }
    const start = tokens.findIndex(token => token.type === 'tbody_open');
    const end = tokens.findIndex(token => token.type === 'tbody_close');
    if (start < 0 || end < 0) { return null; }
    const prefix = tokens.slice(0, start + 1);
    const rows = rowsBetween(tokens, start + 1, end);
    const headerCharacters = prefix.reduce((sum, token) => sum + (token.content?.length || 0), 0);
    const groups = rowGroups(rows, columns, headerCharacters);
    if (groups.length <= 1) { return null; }
    let rowStart = 0;
    return { widths: columnWidths(tokens, columns), rows: rows.length, groups: groups.map((rows, part) =>
    {
        const group = { rowStart, tokens: groupTokens(prefix, rows, tokens.slice(end), part, rowStart), rows: rows.length };
        rowStart += rows.length;
        return group;
    }) };
}

/** Math copies as its LaTeX source, matching the existing visible-table export behavior. */
export function tableCopyRows(tokens)
{
    const rows = [];
    let current;
    for (const token of tokens)
    {
        if (token.type === 'tr_open') { current = []; rows.push(current); }
        if (token.type === 'inline' && current) { current.push(inlineText(token, true).trim()); }
    }
    return rows;
}

export function tableColumns(widths)
{
    return '<colgroup>' + widths.map(width => `<col style="width:${width}%">`).join('') + '</colgroup>';
}
