// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2c1ea7fc-1517-4b56-acdc-3b80864f120b
// COMPONENT: Bounded page layout contracts
// PURPOSE: Verify paper boxes, approximate progress, large blocks, and bounded mounting.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { paperGeometry, layoutBlocks, pageAt, buildViewport } from '../src/page-layout.mjs';
import { windowRange } from '../src/viewport.mjs';

const paper = paperGeometry({ width: 816, height: 1056, margin: 48 }, 1000);
test('pages pack complete blocks and reserve paper margins and gaps', () => {
    const plan = layoutBlocks([400,400,400], paper, true);
    assert.equal(plan.sheets.length, 2);
    assert.equal(plan.totalPages, 2);
    assert.deepEqual(plan.offsets, [48,448,1128]);
    assert.equal(pageAt(plan, 1200), 2);
});
test('large objects remain visible on an expanded sheet with an estimated span', () => {
    const plan = layoutBlocks([2200,100], paper, true);
    assert.equal(plan.sheets[0].pageSpan, 3);
    assert.equal(plan.totalPages, 4);
    assert.ok(plan.sheets[0].height >= 2200 + 96);
    assert.equal(pageAt(plan, plan.sheets[1].top + 50), 4);
});
test('pageless remains continuous and paper sizes still estimate progress', () => {
    const plan = layoutBlocks([400,400,400], paper, false);
    assert.deepEqual(plan.offsets, [0,400,800]);
    assert.equal(plan.totalPages, 2);
    assert.equal(pageAt(plan, 1000), 2);
});
test('paper boxes adapt to a narrow viewport and reject invalid dimensions', () => {
    const narrow = paperGeometry({ width: 816, height: 1056, margin: 48 }, 320);
    assert.equal(narrow.width, 320);
    assert.ok(Math.abs(narrow.height / narrow.width - 1056 / 816) < 0.001);
    assert.ok(paperGeometry({ width: NaN, height: -1, margin: Infinity }, 400).height > 0);
});
test('large documents mount only requested blocks and visible sheets', () => {
    const plan = layoutBlocks(Array(10000).fill(40), paper, true);
    const range = windowRange(plan.offsets, 300000, 800);
    const dom = new JSDOM('<main></main>');
    const blocks = Array.from({length:range.end-range.start}, (_,i) => ({ id:`b-${range.start+i}` }));
    const fragment = buildViewport(dom.window.document, {start:range.start,blocks}, plan, paper, block => {
        const section = dom.window.document.createElement('section');
        section.className = 'monomark-block'; section.id = block.id; return section;
    });
    dom.window.document.querySelector('main').append(fragment);
    assert.ok(dom.window.document.querySelectorAll('.monomark-block').length <= 80);
    assert.ok(dom.window.document.querySelectorAll('.monomark-page').length < 6);
});
test('empty documents still have one estimated page', () => {
    assert.equal(layoutBlocks([], paper, true).totalPages, 1);
});
