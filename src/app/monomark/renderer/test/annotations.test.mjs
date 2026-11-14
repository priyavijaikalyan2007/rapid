// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d3d40201-048b-4459-b09d-b6ace63ab118
// COMPONENT: Reading annotation DOM contracts
// PURPOSE: Verify quoted selections and conservative attachment across virtualized blocks.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { captureSelection, renderAnnotations } from '../src/annotations.mjs';

function fixture(html = '<section class="monomark-block" id="b"><p>Before a <em>chosen sentence</em> after.</p></section>')
{
    return new JSDOM(`<main>${html}</main>`).window;
}

test('selection captures inline fragments and quote context without changing source', () => {
    const window = fixture();
    const node = window.document.querySelector('em').firstChild;
    const range = window.document.createRange();
    range.selectNodeContents(node);
    window.getSelection().addRange(range);
    const anchors = captureSelection(window, window.document.querySelector('main'));
    assert.deepEqual(anchors, [{ blockID: 'b', quote: 'chosen sentence', prefix: 'Before a ', suffix: ' after.', start: 9 }]);
});

test('highlights survive remounting and removal without damaging inline markup', () => {
    const window = fixture();
    const root = window.document.querySelector('main');
    const mark = { id: 'one', color: 'green', anchors: [{ blockID: 'b', quote: 'chosen sentence', prefix: 'Before a ', suffix: ' after.', start: 9 }] };
    renderAnnotations(window, root, [mark]);
    renderAnnotations(window, root, [mark]);
    assert.equal(root.querySelectorAll('mark').length, 1);
    assert.equal(root.querySelector('mark').textContent, 'chosen sentence');
    assert.equal(root.querySelector('mark').dataset.annotation, 'one');
    renderAnnotations(window, root, []);
    assert.equal(root.querySelector('em').textContent, 'chosen sentence');
    assert.equal(root.querySelector('mark'), null);
});

test('ambiguous or deleted quotations remain unattached', () => {
    const window = fixture('<section class="monomark-block" id="b"><p>Same quote. Same quote.</p></section>');
    const root = window.document.querySelector('main');
    const mark = { id: 'one', color: 'pink', anchors: [{ blockID: 'old', quote: 'Same quote', prefix: '', suffix: '', start: 0 }] };
    const result = renderAnnotations(window, root, [mark]);
    assert.deepEqual(result.unresolved, ['one']);
    assert.equal(root.querySelector('mark'), null);
});

test('multi-block selection excludes artifact controls', () => {
    const window = fixture('<section class="monomark-block" id="a"><p>First</p><div class="monomark-artifact-actions">Copy</div></section><section class="monomark-block" id="b"><p>Second</p></section>');
    const root = window.document.querySelector('main');
    const range = window.document.createRange();
    range.setStart(root.querySelector('p').firstChild, 0);
    range.setEnd(root.querySelectorAll('p')[1].firstChild, 6);
    window.getSelection().addRange(range);
    assert.deepEqual(captureSelection(window, root).map(anchor => anchor.quote), ['First', 'Second']);
});

test('changed block identifiers use unique quote context and deleted text stays unresolved', () => {
    const window = fixture();
    const root = window.document.querySelector('main');
    const mark = { id: 'one', color: 'blue', anchors: [{ blockID: 'old', quote: 'chosen sentence', prefix: 'Before a ', suffix: ' after.', start: 0 }] };
    assert.deepEqual(renderAnnotations(window, root, [mark]).attached, ['one']);
    root.querySelector('em').textContent = 'a different sentence';
    assert.deepEqual(renderAnnotations(window, root, [mark]).unresolved, ['one']);
});

test('a stale preferred offset never resolves two identical quote contexts', () => {
    const window = fixture('<section class="monomark-block" id="b">SameSame</section>');
    const mark = { id: 'one', color: 'pink', anchors: [{ blockID: 'b', quote: 'Same', prefix: '', suffix: '', start: 0 }] };
    assert.deepEqual(renderAnnotations(window, window.document.querySelector('main'), [mark]).unresolved, ['one']);
});
