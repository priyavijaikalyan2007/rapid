// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 60a5b5ad-a02a-4f18-ac44-c2bcdaa8cc1b
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Own parsing and complete search in a disposable background worker.
// RELATES: specs/monomark.implementation.md
// FLOW: Source -> indexed blocks -> visible content.

import { resolveAnnotations } from './anchor-resolution.mjs';
import { parseDocument, findBlocks } from './parser.mjs';
import { documentStamp } from './document-stamp.mjs';
import { selectionResult } from './selection-text.mjs';
import { printBudget } from './print-budget.mjs';
import { tableClipboard } from './table-clipboard.mjs';
let documentIndex;
let annotationGeneration = 0;
const anchorCache = new Map();
self.onmessage = async ({ data }) =>
{
    try
    {
        if (data.type === 'load')
        {
            const sourceHash = data.sourceHash || await documentStamp(data.source);
            documentIndex = parseDocument(data.source, data.references);
            documentIndex.sourceHash = sourceHash;
            annotationGeneration++; anchorCache.clear();
            const { blocks, tables, ...index } = documentIndex;
            self.postMessage({ type: 'index', ...index, blocks: blocks.map(({ html, text, copyBreaks, artifactText, ...block }) => block) });
        }
        if (data.type === 'range')
        {
            self.postMessage({ type: 'range', request: data.request, start: data.start,
                blocks: documentIndex.blocks.slice(data.start, data.end) });
        }
        if (data.type === 'find')
        {
            self.postMessage({ type: 'found', matches: findBlocks(documentIndex.blocks, data.query), request: data.request });
        }
        if (data.type === 'print')
        {
            const error = data.start === 0 ? printBudget(documentIndex.blocks) : null;
            self.postMessage({ type: 'print-page', printID: data.printID, start: data.start,
                ...(error ? { error } : { blocks: documentIndex.blocks.slice(data.start, data.start + 100) }) });
        }
        if (data.type === 'selection')
        {
            self.postMessage({ type: 'selection-result', selectionID: data.selectionID, purpose: data.purpose,
                ...selectionResult(documentIndex.blocks, data.range, data.purpose) });
        }
        if (data.type === 'table-copy')
        {
            const rows = documentIndex.tables.get(data.tableKey);
            self.postMessage({ type: 'table-copy', copyID: data.copyID,
                ...tableClipboard(rows, data.format) });
        }
        if (data.type === 'resolve-annotations')
        {
            const generation = ++annotationGeneration;
            const annotations = await resolveAnnotations(documentIndex.blocks, data.annotations,
                { cache: anchorCache, isCancelled: () => generation !== annotationGeneration });
            if (annotations) { self.postMessage({ type: 'annotations-resolved', annotationID: data.annotationID, annotations }); }
        }
        if (data.type === 'export-locations') { await exportLocations(data); }
    }
    catch { self.postMessage({ type: 'failure', message: 'This document could not be indexed. Try a smaller or valid UTF-8 file.' }); }
};


async function exportLocations(data)
{
    const index = documentIndex;
    const annotations = data.annotations ? await resolveAnnotations(index.blocks, data.annotations, { cache: anchorCache }) : undefined;
    if (index !== documentIndex) { return; }
    const requested = annotations ? annotations.flatMap(note => note.anchors.map(anchor => anchor.resolvedBlockID).filter(Boolean)) : data.ids;
    const ids = new Set(requested.slice(0, 20000));
    const blocks = index.blocks.filter(block => !block.generated && (ids.has(block.id) || ids.has(block.blockID)));
    const tooLarge = requested.length > 20000 || blocks.reduce((sum, block) => sum + block.html.length, 0) > 16 * 1024 * 1024;
    self.postMessage({ type: 'export-locations', exportID: data.exportID,
        ...(tooLarge ? { error: 'The export exceeds the 16 MiB location-resolution limit. Export fewer annotations.' } :
            { blocks, annotations, sourceHash: index.sourceHash }) });
}
