// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d3d40201-048b-4459-b09d-b6ace63ab118
// COMPONENT: Reading annotation DOM contracts
// PURPOSE: Verify quoted selections and conservative attachment across virtualized blocks.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { captureSelection, renderAnnotations } from '../src/annotations.mjs';

test('export locations resolve legacy heading quotations without mounting a visible document', async () => {
    const { resolveAnnotationLocations } = await import('../src/annotations.mjs');
    const window = fixture('<section class="monomark-block" id="block-0" data-anchor="heading" ' +
        'data-source-line="8" data-source-end-line="8" data-section="3. Queries"><h2>Heading</h2></section>');
    const notes = [{ id: 'legacy', anchors: [{ blockID: 'heading', quote: 'Heading\n', prefix: '', suffix: '' }] }];
    const result = resolveAnnotationLocations(window, window.document.querySelector('main'), notes);
    assert.deepEqual(result[0].anchors[0].location, { line: 8, endLine: 8, section: '3. Queries' });
    assert.equal(window.document.querySelector('mark'), null);
});

function fixture(html = '<section class="monomark-block" id="b"><p>Before a <em>chosen sentence</em> after.</p></section>')
{
    return new JSDOM(`<main>${html}</main>`).window;
}

test('heading selections omit formatting whitespace from the following table', () => {
    const window = fixture('<section class="monomark-block" id="heading"><h2>Three forms</h2>\n</section>' +
        '<section class="monomark-block" id="table"><table>\n<thead>\n<tr><th>Form</th></tr>\n</thead></table></section>');
    const range = window.document.createRange();
    range.setStart(window.document.querySelector('h2').firstChild, 0);
    range.setEnd(window.document.querySelector('thead'), 1);
    window.getSelection().addRange(range);
    const anchors = captureSelection(window, window.document.querySelector('main'));
    assert.deepEqual(anchors.map(anchor => anchor.quote), ['Three forms']);
});

test('legacy whitespace anchors never create marks inside table structure', () => {
    const window = fixture('<section class="monomark-block" id="h"><h2>Heading</h2>\n</section>' +
        '<section class="monomark-block" id="t"><table>\n<thead>\n<tr><th>Form</th></tr>\n</thead></table></section>');
    const root = window.document.querySelector('main');
    const result = renderAnnotations(window, root, [{ id: 'legacy', anchors: [
        { blockID: 'h', quote: 'Heading\n', prefix: '', suffix: '' },
        { blockID: 't', quote: '\n\n', prefix: '', suffix: 'Form' }
    ] }]);
    assert.deepEqual(result.attached, ['legacy']);
    assert.equal(root.querySelector('h2 mark')?.textContent, 'Heading');
    assert.equal(root.querySelector('table > mark, thead > mark'), null);
});

test('a known block identity disambiguates matching text in an exported excerpt', () => {
    const window = fixture('<section class="monomark-block" id="original"><h2>Heading</h2></section>' +
        '<section class="monomark-block" id="export"><blockquote>Heading</blockquote></section>');
    const root = window.document.querySelector('main');
    renderAnnotations(window, root, [{ id: 'one', anchors: [
        { blockID: 'original', quote: 'Heading', prefix: '', suffix: '' }
    ] }]);
    assert.equal(root.querySelector('#original mark')?.textContent, 'Heading');
    assert.equal(root.querySelector('#export mark'), null);
});

test('an exported excerpt cannot steal an annotation from a known offscreen block', () => {
    const window = fixture('<section class="monomark-block" id="export"><blockquote>Heading</blockquote></section>');
    const result = renderAnnotations(window, window.document.querySelector('main'), [{ id: 'one', anchors: [
        { blockID: 'original', quote: 'Heading', prefix: '', suffix: '' }
    ] }], new Set(['original', 'export']));
    assert.deepEqual(result.unresolved, ['one']);
    assert.equal(window.document.querySelector('mark'), null);
});

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

test('annotation navigation scrolls to the marked line within a block', async () => {
    const { scrollToAnnotation } = await import('../src/annotations.mjs');
    const window = fixture();
    let position;
    window.scrollTo = (x, y) => { position = y; };
    window.HTMLElement.prototype.getBoundingClientRect = () => ({ top: 600 });
    const root = window.document.querySelector('main');
    const mark = { id: 'one', color: 'blue', anchors: [{ blockID: 'b', quote: 'chosen sentence', prefix: 'Before a ', suffix: ' after.', start: 9 }] };
    renderAnnotations(window, root, [mark]);
    assert.equal(scrollToAnnotation(window, root, 'one'), true);
    assert.ok(position > 0 && position < 600);
    assert.equal(scrollToAnnotation(window, root, 'missing'), false);
});


test('global ambiguity cannot fall back to a unique visible duplicate',()=>{
    const window=fixture('<section class="monomark-block" id="b">Before chosen phrase after.</section>');
    const note={id:'ambiguous',anchors:[{blockID:'old',resolvedBlockID:null,quote:'chosen phrase',prefix:'Before ',suffix:' after.'}]};
    assert.deepEqual(renderAnnotations(window,window.document.querySelector('main'),[note]).unresolved,['ambiguous']);
    assert.equal(window.document.querySelector('mark'),null);
});

test('globally resolved multi-block annotations decorate their visible subset',()=>{
    const window=fixture('<section class="monomark-block" id="visible">Visible quote.</section>');
    const note={id:'spanning',anchors:[
        {blockID:'old-a',resolvedBlockID:'visible',quote:'Visible quote.',prefix:'',suffix:''},
        {blockID:'old-b',resolvedBlockID:'unloaded',quote:'Unloaded quote.',prefix:'',suffix:''}]};
    assert.deepEqual(renderAnnotations(window,window.document.querySelector('main'),[note],new Set(['visible','unloaded'])).attached,['spanning']);
});
