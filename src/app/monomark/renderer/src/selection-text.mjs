// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c7303155-66a7-4721-a49b-c6d22a0fdcae
// COMPONENT: Indexed selection text
// PURPOSE: Resolve logical selections without mounting the selected document span.
import { boundedLabel } from './navigation-label.mjs';

const separators = { paragraph_close: '\n\n', heading_close: '\n\n', list_item_close: '\n',
    tr_close: '\n', th_close: '\t', td_close: '\t' };

export function inlineText(token, includeMath = false)
{
    if (token.type === 'image') { return ''; }
    if (token.type.startsWith('math_')) { return includeMath ? token.content : ''; }
    if (token.children) { return token.children.map(child => inlineText(child, includeMath)).join(''); }
    if (['text', 'code_inline', 'emoji'].includes(token.type)) { return token.content; }
    if (['softbreak', 'hardbreak'].includes(token.type)) { return '\n'; }
    if (token.type === 'footnote_ref')
    { return `[${token.meta.id + 1}${token.meta.subId > 0 ? `:${token.meta.subId}` : ''}]`; }
    if (token.type === 'footnote_anchor') { return '↩︎'; }
    return '';
}

/** Flat text matches annotation offsets. Separate break positions restore readable clipboard structure. */
export function blockSelectionText(tokens)
{
    const parts = [];
    const breaks = new Map();
    let length = 0;
    let artifactText;
    for (const token of tokens)
    {
        let text = token.type === 'inline' ? inlineText(token) : token.type === 'footnote_anchor' ? ' ↩︎' : '';
        if (['fence', 'code_block'].includes(token.type))
        {
            if (token.info?.trim() === 'mermaid') { artifactText = token.content; }
            else { text = token.content; }
        }
        if (token.type === 'math_block') { artifactText = token.content; }
        parts.push(text); length += text.length;
        const separator = token.hidden ? null : separators[token.type];
        if (separator && (breaks.get(length) || '').length <= separator.length) { breaks.set(length, separator); }
    }
    return { text: parts.join(''), copyBreaks: [...breaks].filter(([at]) => at > 0 && at < length), artifactText };
}

export function orderedSelection(range)
{
    const { anchor, focus } = range;
    const forward = anchor.index < focus.index || (anchor.index === focus.index && anchor.offset <= focus.offset);
    return forward ? [anchor, focus] : [focus, anchor];
}

function copyPart(block, start, end)
{
    if (!block.text && block.artifactText) { return block.artifactText; }
    const parts = [];
    let cursor = start;
    for (const [at, separator] of block.copyBreaks || [])
    {
        if (at <= start || at >= end) { continue; }
        parts.push(block.text.slice(cursor, at), separator); cursor = at;
    }
    parts.push(block.text.slice(cursor, end));
    return parts.join('');
}

function quoteAnchor(block, start, end)
{
    return { blockID: block.id, start, quote: block.text.slice(start, end),
        prefix: Array.from(block.text.slice(Math.max(0, start - 65), start)).slice(-32).join(''),
        suffix: Array.from(block.text.slice(end, end + 65)).slice(0, 32).join(''),
        ...(Number.isInteger(block.line) && block.endLine > block.line ? { location:
            { line: block.line + 1, endLine: block.endLine, section: boundedLabel(block.section || '') } } : {}) };
}

/** Fail atomically at the explicit clipboard/annotation budgets. Never copy a truncated selection. */
export function selectionResult(blocks, range, mode, byteLimit = 128 * 1024 * 1024)
{
    if (!range?.anchor || !range?.focus) { return { error: 'Select document text first.' }; }
    const [first, last] = orderedSelection(range);
    if (![first.index, first.offset, last.index, last.offset].every(Number.isSafeInteger) ||
        first.index < 0 || last.index >= blocks.length || first.offset < 0 || last.offset < 0)
    { return { error: 'The selected location changed. Select the text again.' }; }
    const parts = [];
    const anchors = [];
    let bytes = 0;
    let previousTable;
    for (let index = first.index; index <= last.index; index++)
    {
        const block = blocks[index];
        const start = index === first.index ? Math.min(first.offset, block.text.length) : 0;
        const end = index === last.index ? Math.min(last.offset, block.text.length) : block.text.length;
        if (mode === 'copy')
        {
            const from = block.tableContinuation && index > first.index ? Math.max(start, block.tableHeaderLength) : start;
            const text = copyPart(block, from, end);
            const separator = parts.length ? block.tableKey && block.tableKey === previousTable ? '\n' : '\n\n' : '';
            bytes += new TextEncoder().encode(text).length + separator.length;
            if (bytes > byteLimit) { return { error: 'The selection is too large to copy. Select a smaller section.' }; }
            if (text) { parts.push(separator, text); previousTable = block.tableKey; }
        }
        else if (!block.generated && block.text.slice(start, end).trim())
        {
            const anchor = quoteAnchor(block, start, end);
            bytes += new TextEncoder().encode(JSON.stringify(anchor)).length;
            if (anchors.length >= 128 || anchor.quote.length > 16000 || bytes > 900000)
            { return { error: 'This selection is too large for a highlight. Copy still supports longer selections.', anchors: [] }; }
            anchors.push(anchor);
        }
    }
    return mode === 'copy' ? { text: parts.join('') } : { anchors };
}
