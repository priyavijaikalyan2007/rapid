// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d91d065b-69cd-4f83-b3b5-1deec4e23130
// COMPONENT: Artifact clipboard contracts
// PURPOSE: Preserve data across spreadsheet, source, and image-copy boundaries.
import test from 'node:test';
import assert from 'node:assert/strict';
import { serializeRows, artifactSource, imageBounds } from '../src/artifacts.mjs';

test('tapping an equation focuses its copy controls without requiring a hovering pointer', async () =>
{
    const { JSDOM } = await import('jsdom');
    const { installArtifactActions } = await import('../src/artifacts.mjs');
    const dom = new JSDOM('<main><span data-math="x%5E2">x squared</span></main>');
    globalThis.document = dom.window.document;
    installArtifactActions(document.querySelector('main'), { text() {}, png() {} });
    document.querySelector('[data-math]').click();
    assert.equal(document.activeElement, document.querySelector('.monomark-artifact-equation'));
    dom.window.close();
    delete globalThis.document;
});

test('CSV quotes delimiters quotes and multiline cells', () => {
    assert.equal(serializeRows([['A,B', '"quoted"', 'line\nbreak']], ','), '"A,B","""quoted""","line\nbreak"');
});
test('TSV and pipe exports preserve the same cell grid', () => {
    assert.equal(serializeRows([['A', 'B'], ['1', '2']], '\t'), 'A\tB\n1\t2');
    assert.equal(serializeRows([['A|B', 'C']], '|'), '"A|B"|C');
});
test('source copy preserves raw LaTeX and diagram definitions', () => {
    assert.equal(artifactSource('equation', { math: encodeURIComponent('\\frac{1}{2}') }), '\\frac{1}{2}');
    assert.equal(artifactSource('diagram', { mermaid: encodeURIComponent('A --> B') }), 'A --> B');
});
test('PNG copies fit the whole artifact without exceeding the viewport', () => {
    assert.deepEqual(imageBounds(2000, 1000, 1000, 600), { width: 1000, height: 500, scale: 0.5 });
});

test('artifact icons copy structured data and preserve source text', async () => {
    const { JSDOM } = await import('jsdom');
    const { installArtifactActions } = await import('../src/artifacts.mjs');
    const dom = new JSDOM('<main><table><tr><td>A,B</td><td>C</td></tr></table><pre><code>let x = 1;</code></pre><span data-math="x%5E2">rendered</span></main>');
    globalThis.document = dom.window.document;
    const copied = [];
    let image;
    installArtifactActions(document.querySelector('main'), { text: text => copied.push(text), png: element => { image = element; } });
    const buttons = [...document.querySelectorAll('button')];
    buttons.find(button => button.title === 'Copy table as CSV').click();
    assert.equal(copied.at(-1), '"A,B",C');
    buttons.find(button => button.title === 'Copy code as Text').click();
    assert.equal(copied.at(-1), 'let x = 1;');
    buttons.find(button => button.title === 'Copy equation as LaTeX').click();
    assert.equal(copied.at(-1), 'x^2');
    buttons.find(button => button.title === 'Copy equation as PNG').click();
    assert.equal(image.dataset.math, 'x%5E2');
    assert.ok(buttons.every(button => button.getAttribute('aria-label') && button.querySelector('svg')));
    installArtifactActions(document.querySelector('main'), { text() {}, png() {} });
    assert.equal(document.querySelectorAll('button').length, buttons.length);
    dom.window.close();
});

test('image snapshots wait for decoding and stop after errors or a deadline', async () => {
    const { JSDOM } = await import('jsdom');
    const { waitForCopyImages } = await import('../src/artifacts.mjs');
    const dom = new JSDOM('<div><img src="local.png"></div>');
    const img = dom.window.document.querySelector('img');
    let decoded = false;
    img.decode = async () => { await new Promise(resolve => setTimeout(resolve,10)); decoded = true; };
    assert.equal(await waitForCopyImages(img,100),true);
    assert.equal(decoded,true);
    img.decode = async () => { throw new Error('invalid image'); };
    assert.equal(await waitForCopyImages(dom.window.document.querySelector('div'),100),false);
    img.decode = () => new Promise(() => {});
    assert.equal(await waitForCopyImages(img,5),false);
    assert.equal(await waitForCopyImages(dom.window.document.createElement('span'),5),true);
    dom.window.close();
});

test('continuation-table copy requests the whole worker grid instead of visible rows',async()=>{
    const {JSDOM}=await import('jsdom');
    const {installArtifactActions}=await import('../src/artifacts.mjs');
    const dom=new JSDOM('<main><table data-table-key="monomark-table-1"><tr><td>Visible subset</td></tr></table></main>');
    globalThis.document=dom.window.document;
    const requested=[];
    installArtifactActions(document.querySelector('main'),{text(){throw new Error('Partial copy');},png(){},
        table:(key,format)=>requested.push([key,format])});
    const button=document.querySelector('button');
    assert.match(button.title,/entire table/i);button.click();
    assert.deepEqual(requested,[['monomark-table-1','CSV']]);
    dom.window.close();
});
