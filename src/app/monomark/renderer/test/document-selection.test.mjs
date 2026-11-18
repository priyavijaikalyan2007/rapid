// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 19ae0e38-b64b-4473-b0cd-912ecb0f59ac
// COMPONENT: Virtualized document selection contracts
// PURPOSE: Preserve logical ranges, copy text, and annotations across unloaded blocks.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { parseDocument } from '../src/parser.mjs';
import { selectionResult } from '../src/selection-text.mjs';
import { DocumentSelection, readableNodes } from '../src/document-selection.mjs';

test('search and selection text match rendered inline, list, and table text', () => {
    const parsed = parseDocument('# A `title`\n\nRead **bold** and :smile:.\n\n- First\n- Second\n\n| A | B |\n|---|---|\n| C | D |');
    const window = new JSDOM('<main></main>').window;
    for (const block of parsed.blocks)
    {
        const root = window.document.createElement('section');
        root.innerHTML = block.html;
        assert.equal(block.text, readableNodes(window, root).map(node => node.textContent).join(''));
    }
    window.close();
});

test('logical copy includes unloaded blocks and preserves inline text and table separators', () => {
    const parsed = parseDocument('First **sentence**.\n\n- One\n- Two\n\n| A | B |\n|---|---|\n| C | D |\n\nLast sentence.');
    const result = selectionResult(parsed.blocks, { anchor: { index: 0, offset: 6 },
        focus: { index: 3, offset: 4 } }, 'copy');
    assert.equal(result.text, 'sentence.\n\nOne\nTwo\n\nA\tB\nC\tD\n\nLast');
});

test('reverse selections resolve stable quote anchors with whole source locations', () => {
    const blocks = parseDocument('# Heading\n\nFirst chosen sentence.\n\nLast selected sentence.').blocks;
    const result = selectionResult(blocks, { anchor: { index: 2, offset: 4 }, focus: { index: 1, offset: 6 } }, 'anchors');
    assert.deepEqual(result.anchors.map(anchor => [anchor.blockID, anchor.quote, anchor.start]),
        [['block-1', 'chosen sentence.', 6], ['block-2', 'Last', 0]]);
    assert.equal(result.anchors[0].location.line, 3);
});

test('selection never silently truncates a clipboard result at its byte budget', () => {
    const blocks = parseDocument('Unicode 日本語 text.').blocks;
    const result = selectionResult(blocks, { anchor: { index: 0, offset: 0 },
        focus: { index: 0, offset: blocks[0].text.length } }, 'copy', 8);
    assert.match(result.error, /copy|selection/i);
    assert.equal(result.text, undefined);
});

test('a logical range survives removal of its original anchor and stays bounded', () => {
    const window = new JSDOM('<main></main>').window;
    const root = window.document.querySelector('main');
    const mount = indexes => { root.innerHTML = indexes.map(index =>
        `<section class="monomark-block" data-block="${index}"><p>Block ${index} text</p></section>`).join(''); };
    mount([0, 1, 2]);
    const selection = new DocumentSelection(window, root);
    const nodes = root.querySelectorAll('p');
    window.getSelection().setBaseAndExtent(nodes[0].firstChild, 2, nodes[2].firstChild, 5);
    selection.capture();
    mount([1, 2, 3]);
    selection.restore();
    assert.deepEqual(selection.range, { anchor: { index: 0, offset: 2 }, focus: { index: 2, offset: 5 } });
    assert.equal(selection.isVirtual, true);
    assert.equal(window.getSelection().toString(), 'Block 1 textBlock');
    selection.capture();
    assert.equal(selection.range.anchor.index, 0);
    assert.equal(root.querySelectorAll('section').length, 3);
    selection.reset();
    assert.equal(selection.range, null);
    window.close();
});

test('Select All covers the full index without mounting it', () => {
    const window = new JSDOM('<main><section class="monomark-block" data-block="8"><p>Visible</p></section></main>').window;
    const root = window.document.querySelector('main');
    const selection = new DocumentSelection(window, root);
    selection.selectAll(10000, 17);
    assert.deepEqual(selection.range, { anchor: { index: 0, offset: 0 }, focus: { index: 9999, offset: 17 } });
    assert.equal(root.children.length, 1);
    assert.equal(window.getSelection().toString(), 'Visible');
    window.close();
});
