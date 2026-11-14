// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 101d741c-c4e7-4a3e-a4f5-583181f006d9
// COMPONENT: Renderer bridge lifecycle tests
// PURPOSE: Verify document-generation changes and stale-position protection independently of layout.
import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { JSDOM } from 'jsdom';

const dom = new JSDOM(await readFile(new URL('../index.html', import.meta.url), 'utf8'), { url: 'https://reader.invalid/' });
const messages = [];
const workers = [];
globalThis.window = dom.window;
globalThis.document = dom.window.document;
globalThis.SVGElement = dom.window.SVGElement;
globalThis.CSSStyleSheet = dom.window.CSSStyleSheet;
globalThis.getComputedStyle = dom.window.getComputedStyle.bind(dom.window);
globalThis.matchMedia = () => ({ matches: false, addEventListener() {} });
globalThis.requestAnimationFrame = callback => callback();
dom.window.scrollTo = () => {};
dom.window.SVGElement.prototype.getBBox = () => ({ x: 0, y: 0, width: 120, height: 30 });
dom.window.SVGElement.prototype.getComputedTextLength = () => 80;
dom.window.HTMLElement.prototype.getBoundingClientRect = () => ({ top: 0, left: 0, width: 400, bottom: 80, height: 80 });
Object.defineProperty(document, 'fonts', { value: { ready: Promise.resolve() } });
dom.window.webkit = { messageHandlers: { reader: { postMessage: value => messages.push(value) } } };
globalThis.fetch = async () => ({ text: async () => '' });
globalThis.Worker = class {
    constructor() { workers.push(this); }
    sent = [];
    postMessage(message) { this.sent.push(message); }
    terminate() {}
};
await import('../src/host.mjs');
after(() => dom.window.close());

test('document replacement suppresses stale reading positions', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'first' });
    await new Promise(resolve => setTimeout(resolve, 20));
    workers[0].onmessage({ data: { type: 'index', outline: [], links: [], blocks: [{ id: 'old', blockID: 'old', estimate: 80 }] } });
    workers[0].onmessage({ data: { type: 'range', request: workers[0].sent.at(-1).request, start: 0, blocks: [{ id: 'old', html: '<p>old</p>' }] } });
    window.MonoMark.command({ type: 'load', epoch: 'next' });
    window.dispatchEvent(new window.Event('scroll'));
    await new Promise(resolve => setTimeout(resolve, 320));
    assert.equal(messages.filter(message => message.type === 'position' && message.epoch === 'next').length, 0);
});

test('native commands preserve document context and expose link actions', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'current' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    worker.onmessage({ data: { type: 'index', outline: [{ id: 'heading', blockID: 'a' }], links: [], blocks: [{ id: 'a', blockID: 'a', estimate: 80 }] } });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 0, blocks: [{ id: 'a', html: '<p><a href="next.md">Next</a></p>' }] } });
    const anchor = document.querySelector('a');
    anchor.dispatchEvent(new window.MouseEvent('pointerover', { bubbles: true }));
    assert.equal(messages.at(-1).type, 'preview');
    window.MonoMark.command({ type: 'preview', href: 'next.md', text: 'Opening prose' });
    assert.equal(document.getElementById('monomark-preview-text').textContent, 'Opening prose');
    document.getElementById('monomark-open-tab').click();
    assert.equal(messages.at(-1).newTab, true);
    window.MonoMark.command({ type: 'preferences', value: { bodySize: 18, codeFontFamily: 'Menlo', columnBanding: true } });
    assert.equal(document.documentElement.style.getPropertyValue('--code-font'), 'Menlo');
    assert.equal(document.body.classList.contains('monomark-column-banding'), true);
    window.MonoMark.command({ type: 'find', query: 'Next' });
    assert.equal(worker.sent.at(-1).type, 'find');
    worker.onmessage({ data: { type: 'found', matches: [0] } });
    window.MonoMark.command({ type: 'next', direction: -1 });
    window.MonoMark.command({ type: 'jump', id: 'heading' });
    window.MonoMark.command({ type: 'jump', id: 'missing' });
    assert.match(messages.at(-1).message, /no matching destination/);
    window.MonoMark.command({ type: 'zoom', value: 0 });
    assert.equal(document.body.style.zoom, '1');
    window.MonoMark.command({ type: 'print' });
    worker.onmessage({ data: { type: 'print-page', start: 0, blocks: [{ html: '<p>Printable</p>' }] } });
    await new Promise(resolve => setTimeout(resolve, 10));
    assert.equal(messages.at(-1).type, 'printReady');
    window.MonoMark.command({ type: 'afterPrint' });
    worker.onmessage({ data: { type: 'failure', message: 'bad document' } });
    assert.equal(document.getElementById('monomark-status').textContent, 'bad document');
    await new Promise(resolve => setTimeout(resolve, 300));
});

test('rich artifacts retain visible diagram labels and copy rendered images', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'rich' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const diagram = encodeURIComponent('graph LR\nA[Read] --> B[Understand]');
    workers.at(-1).onmessage({ data: { type: 'index', outline: [], links: [], blocks: [{ id: 'a', blockID: 'a', estimate: 80 }] } });
    workers.at(-1).onmessage({ data: { type: 'range', request: workers.at(-1).sent.at(-1).request, start: 0, blocks: [{ id: 'a', html:
        `<div data-mermaid="${diagram}"></div><span data-math="x%5E2"></span><pre><code class="language-swift">let x = 1</code></pre><img data-src="photo.png"><img data-src="https://remote.invalid/x.png">` }] } });
    for (let attempt = 0; attempt < 100 && !document.querySelector('[data-mermaid] svg'); attempt++)
    {
        await new Promise(resolve => setTimeout(resolve, 20));
    }
    assert.match(document.querySelector('[data-mermaid]').textContent, /Understand/);
    assert.ok(document.querySelector('.katex'));
    assert.ok(document.querySelector('.hljs-keyword'));
    assert.match(document.querySelector('img').src, /monomark:\/\/document\/image/);
    window.MonoMark.command({ type: 'appearance', mode: 'dark' });
    await new Promise(resolve => setTimeout(resolve, 100));
    assert.equal(document.documentElement.style.colorScheme, 'dark');
    document.querySelector('[title*="PNG"]').click();
    await new Promise(resolve => setTimeout(resolve, 100));
    assert.equal(messages.at(-1).type, 'copyPNG');
    window.MonoMark.command({ type: 'copyComplete' });
    assert.equal(document.querySelector('.monomark-copy-overlay'), null);
    await new Promise(resolve => setTimeout(resolve, 300));
});

test('native annotations decorate remounted prose and selection reaches the inspector', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'notes' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [{ id: 'a', blockID: 'a', estimate: 80 }] } });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 0,
        blocks: [{ id: 'a', html: '<p>Remember this sentence.</p>' }] } });
    const range = document.createRange();
    range.selectNodeContents(document.querySelector('.monomark-block p'));
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    document.dispatchEvent(new window.MouseEvent('mouseup', { bubbles: true }));
    const selection = messages.at(-1);
    assert.equal(selection.type, 'selection');
    assert.equal(selection.anchors[0].quote, 'Remember this sentence.');
    window.MonoMark.command({ type: 'annotations', value: [{ id: 'note-one', color: 'yellow', anchors: selection.anchors }] });
    const mark = document.querySelector('mark');
    assert.equal(mark.textContent, 'Remember this sentence.');
    assert.deepEqual(messages.at(-1).attached, ['note-one']);
    mark.click();
    assert.equal(messages.at(-1).type, 'annotationSelected');
    assert.equal(messages.at(-1).id, 'note-one');
    await new Promise(resolve => setTimeout(resolve, 300));
});
