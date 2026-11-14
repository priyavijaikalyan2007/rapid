// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 60a5b5ad-a02a-4f18-ac44-c2bcdaa8cc1b
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Own parsing and complete search in a disposable background worker.
// RELATES: specs/monomark.implementation.md
// FLOW: Source -> indexed blocks -> visible content.

import { parseDocument, findBlocks } from './parser.mjs';
let documentIndex;
self.onmessage = async ({ data }) =>
{
    try
    {
        if (data.type === 'load')
        {
            documentIndex = parseDocument(data.source);
            const { blocks, ...index } = documentIndex;
            self.postMessage({ type: 'index', ...index, blocks: blocks.map(({ html, text, ...block }) => block) });
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
            self.postMessage({ type: 'print-page', blocks: documentIndex.blocks.slice(data.start, data.start + 100), start: data.start });
        }
    }
    catch { self.postMessage({ type: 'failure', message: 'This document could not be indexed. Try a smaller or valid UTF-8 file.' }); }
};
