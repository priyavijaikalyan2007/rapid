// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c5adf0eb-15c5-4577-9e07-9fc786bf05ad
// COMPONENT: Source location contracts
// PURPOSE: Keep rendered locations aligned with the original Markdown.
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseDocument } from '../src/parser.mjs';

test('source locations include front matter and hidden comment lines', () => {
    const result = parseDocument('---\r\nstatus: draft\r\n---\r\n<!-- hidden -->\r\n# Title\r\n\r\nText.');
    assert.equal(result.blocks[0].line, 4);
    assert.equal(result.blocks[0].endLine, 5);
    assert.equal(result.sourceLines, 7);
});

test('block locations include the current heading hierarchy', () => {
    const result = parseDocument('# Document\n\n## 3. Queries\n\n### Operators\n\nA paragraph.');
    assert.equal(result.blocks.at(-1).section, 'Document › 3. Queries › Operators');
});

test('source section labels retain whole Unicode characters at the length boundary', () => {
    const title = 'a'.repeat(511) + '😀' + 'tail';
    const result = parseDocument('# ' + title + '\n\nText.');
    assert.equal(Array.from(result.blocks.at(-1).section).length, 512);
    assert.equal(result.blocks.at(-1).section.endsWith('😀'), true);
});

test('source stamps use canonical UTF-8 text', async () => {
    const { documentStamp } = await import('../src/document-stamp.mjs');
    assert.equal(await documentStamp('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    assert.equal(await documentStamp('\uFEFFa\r\nb\r'), await documentStamp('a\nb\n'));
});

test('soft breaks are identifiable without converting intentional hard breaks or code', () => {
    const result = parseDocument('**Status:** Draft\n**Date:** Today  \nDone\n\n`and`, `or`, `not`\n\n```text\na\nb\n```');
    assert.match(result.blocks[0].html, /Draft<span class="monomark-softbreak">\n<\/span>/);
    assert.match(result.blocks[0].html, /Today<br>/);
    assert.match(result.blocks[1].html, /<code>and<\/code>/);
    assert.match(result.blocks[2].html, /a\nb\n/);
});

test('line labels pad by total source length and have at least two digits', async () => {
    const { sourceLineLabel } = await import('../src/source-lines.mjs');
    assert.deepEqual([sourceLineLabel(0, 8), sourceLineLabel(1, 99), sourceLineLabel(1, 100),
        sourceLineLabel(998, 999), sourceLineLabel(1, 1000)], ['01', '02', '002', '999', '0002']);
});
