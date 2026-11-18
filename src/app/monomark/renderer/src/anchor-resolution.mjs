// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7219ace2-9114-4821-bc28-322c05df9c0e
// COMPONENT: Whole-document quote recovery
// PURPOSE: Recover unique source quotes without mounting unloaded blocks or trusting reused block IDs.

function matchesIn(block, anchor)
{
    const matches = [];
    const text = block.text || '';
    for (let start = text.indexOf(anchor.quote); start >= 0; start = text.indexOf(anchor.quote, start + 1))
    {
        if (block.tableContinuation && start < block.tableHeaderLength) { continue; }
        if (!text.slice(0, start).endsWith(anchor.prefix || '') ||
            !text.slice(start + anchor.quote.length).startsWith(anchor.suffix || '')) { continue; }
        matches.push(block.blockID);
        if (matches.length === 2) { break; }
    }
    return matches;
}

function locate(blocks, anchor)
{
    if (!anchor.quote.trim()) { return { resolvedBlockID: null, resolution: 'missing' }; }
    let found;
    for (const block of blocks)
    {
        if (block.generated || block.html?.length > 1024 * 1024) { continue; }
        const matches = matchesIn(block, anchor);
        if (matches.length > 1 || (found && matches.length))
        { return { resolvedBlockID: null, resolution: 'ambiguous' }; }
        if (matches.length) { found = matches[0]; }
    }
    return { resolvedBlockID: found || null, resolution: found ? 'unique' : 'missing' };
}

function resolveAnchor(blocks, anchor, cache)
{
    const key = JSON.stringify([anchor.quote, anchor.prefix, anchor.suffix]);
    if (cache.has(key)) { return { ...anchor, ...cache.get(key) }; }
    let result = locate(blocks, anchor);
    if (result.resolution === 'missing')
    {
        result = locate(blocks, { ...anchor, quote: anchor.quote.replace(/^\n+|\n+$/g, ''),
            prefix: (anchor.prefix || '').replace(/\n+$/g, ''), suffix: (anchor.suffix || '').replace(/^\n+/g, '') });
    }
    // Bound cached quote/context strings. The document's canonical text is reused, never copied into another index.
    if (cache.size >= 256) { cache.clear(); }
    cache.set(key, result);
    return { ...anchor, ...result };
}

/** Yield between small batches so search, copy, and newer annotation revisions can interrupt recovery. */
export async function resolveAnnotations(blocks, annotations, { cache = new Map(), isCancelled = () => false } = {})
{
    const result = [];
    let count = 0;
    for (const annotation of annotations)
    {
        const anchors = [];
        for (const anchor of annotation.anchors)
        {
            if (isCancelled()) { return null; }
            anchors.push(resolveAnchor(blocks, anchor, cache));
            if (++count % 16 === 0) { await new Promise(resolve => setTimeout(resolve, 0)); }
        }
        result.push({ ...annotation, anchors });
    }
    return isCancelled() ? null : result;
}
