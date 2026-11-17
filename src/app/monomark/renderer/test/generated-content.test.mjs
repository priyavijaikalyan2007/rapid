// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: fc81430a-8a74-440b-ab87-816af0507e6a
// COMPONENT: Inline export reading contracts
// PURPOSE: Keep original block identities stable and generated text outside annotation targets.
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseDocument } from '../src/parser.mjs';
import { JSDOM } from 'jsdom';
import { renderAnnotations, captureSelection } from '../src/annotations.mjs';

test('generated inline blocks do not change original block IDs', () => {
    const original = parseDocument('# Title\n\nBefore.\n\nAfter.');
    const inline = parseDocument('# Title\n\nBefore.\n<!-- monomark:inline:notes:start -->\n\nGenerated reading notes.\n\n<!-- monomark:inline:notes:end -->\n\nAfter.');
    assert.equal(inline.blocks.filter(block => block.generated).length, 1);
    assert.deepEqual(inline.blocks.filter(block => !block.generated).map(block => [block.text, block.blockID]),
        original.blocks.map(block => [block.text, block.blockID]));
});

test('literal markers in code and quoted user notes never define generated ownership', () => {
    const result = parseDocument('```html\n<!-- monomark:inline:notes:start -->\n```\n\n' +
        '> <!-- monomark:inline:notes:start -->\n> A quote.\n> <!-- monomark:inline:notes:end -->');
    assert.equal(result.blocks.some(block => block.generated), false);
});

test('exported excerpts cannot receive or steal original annotations', () => {
    const window = new JSDOM('<main><section class="monomark-block" id="b"><p>Original</p></section>' +
        '<section class="monomark-block" data-generated="true" id="g"><p>Original</p></section></main>').window;
    const root = window.document.querySelector('main');
    const records = [{id:'one',anchors:[{blockID:'b',quote:'Original',prefix:'',suffix:''}]}];
    renderAnnotations(window, root, records);
    assert.equal(root.querySelector('#g mark'), null);
    const range = window.document.createRange();
    range.selectNodeContents(root.querySelector('#g p'));
    window.getSelection().addRange(range);
    assert.deepEqual(captureSelection(window, root), []);
});
