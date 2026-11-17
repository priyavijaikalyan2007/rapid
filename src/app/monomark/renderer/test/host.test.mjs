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
let systemDark = false;
const appearanceListeners = [];
globalThis.matchMedia = () => ({ matches: systemDark, addEventListener(_, callback) { appearanceListeners.push(callback); } });
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

test('export resolution returns source locations without changing the viewport', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'export-resolution' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [{ id: 'visible', blockID: 'block-0', estimate: 80 }] } });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 0,
        blocks: [{ id: 'visible', html: '<p>Visible document</p>' }] } });
    const before = document.getElementById('monomark-document').innerHTML;
    const records = [{ id: 'saved', anchors: [{ blockID: 'heading', quote: 'Heading', prefix: '', suffix: '' }] }];
    const pending = window.MonoMark.exportLocations(records);
    const request = worker.sent.at(-1);
    assert.equal(request.type, 'export-locations');
    worker.onmessage({ data: { type: 'export-locations', exportID: request.exportID, sourceHash: 'a'.repeat(64), blocks: [
        { id: 'heading', blockID: 'block-4', line: 8, endLine: 9, section: 'Document › Heading', html: '<h2 id="heading">Heading</h2>' }
    ] } });
    const result = await pending;
    assert.deepEqual(result.annotations[0].anchors[0].location, { line: 9, endLine: 9, section: 'Document › Heading' });
    assert.equal(document.getElementById('monomark-document').innerHTML, before);
    assert.equal(result.sourceHash, 'a'.repeat(64));
    await new Promise(resolve => setTimeout(resolve, 300));
});

test('document replacement cancels a pending export instead of returning stale locations', async () => {
    const pending = window.MonoMark.exportLocations([]);
    const rejected = assert.rejects(pending, /document changed/);
    window.MonoMark.command({ type: 'load', epoch: 'cancel-export' });
    await rejected;
    await new Promise(resolve => setTimeout(resolve, 20));
});

test('an empty indexed document can still export its reading notes', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'empty-export' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [] } });
    const pending = window.MonoMark.exportLocations([]);
    const request = worker.sent.at(-1);
    worker.onmessage({ data: { type: 'export-locations', exportID: request.exportID,
        sourceHash: 'b'.repeat(64), blocks: [] } });
    assert.deepEqual(await pending, { annotations: [], sourceHash: 'b'.repeat(64) });
});

test('code remains monospace when the body font is proportional', () => {
    window.MonoMark.command({ type: 'preferences', value: { fontFamily: 'Atkinson Hyperlegible' } });
    assert.equal(document.documentElement.style.getPropertyValue('--code-font'), 'ui-monospace');
});

test('source line settings apply to mounted blocks and stay outside selected quotations', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'source-lines' });
    await new Promise(resolve => setTimeout(resolve, 20));
    window.MonoMark.command({ type: 'preferences', value: { showLineNumbers: true, preserveLineBreaks: true } });
    const worker = workers.at(-1);
    const block = { id: 'b', blockID: 'block-0', line: 1, endLine: 3, estimate: 80,
        html: '<p>Status: Draft<span class="monomark-softbreak">\n</span>Date: Today</p>' };
    worker.onmessage({ data: { type: 'index', outline: [], links: [], sourceLines: 200, blocks: [block] } });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 0, blocks: [block] } });
    assert.equal(document.querySelector('.monomark-line-number')?.textContent, '002');
    assert.equal(document.body.classList.contains('monomark-preserve-breaks'), true);
    const range = document.createRange();
    range.selectNodeContents(document.querySelector('.monomark-block'));
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    document.dispatchEvent(new window.MouseEvent('mouseup', { bubbles: true }));
    assert.equal(messages.at(-1).anchors[0].quote, 'Status: Draft\nDate: Today');
    await new Promise(resolve => setTimeout(resolve, 300));
});

test('heading destinations have one DOM ID and retain their saved annotation alias', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'unique-heading' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    const block = { id: 'three-forms', blockID: 'block-2', estimate: 80,
        html: '<h2 id="three-forms">3. Three forms</h2>\n' };
    worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [block] } });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 0, blocks: [block] } });
    assert.equal(document.querySelectorAll('#three-forms').length, 1);
    assert.equal(document.querySelector('.monomark-block').dataset.anchor, 'three-forms');
    await new Promise(resolve => setTimeout(resolve, 300));
});

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
    assert.equal(document.documentElement.style.getPropertyValue('--code-font'), '"Menlo"');
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
    window.MonoMark.command({ type: 'copyComplete', epoch: 'previous-document' });
    assert.ok(document.querySelector('.monomark-copy-overlay'), 'A stale completion must not clear the current copy');
    window.MonoMark.command({ type: 'copyComplete', epoch: 'rich' });
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

test('an offscreen annotation finishes at the quote rather than the block start', async () => {
    const original = window.HTMLElement.prototype.getBoundingClientRect;
    const scrolls = [];
    const originalScroll = window.scrollTo;
    window.scrollTo = (x, y) => scrolls.push(y);
    window.HTMLElement.prototype.getBoundingClientRect = function() {
        return { top: this.tagName === 'MARK' ? 900 : 100, left: 0, width: 400, bottom: 980, height: 80 };
    };
    try
    {
        window.MonoMark.command({ type: 'load', epoch: 'quote-jump' });
        await new Promise(resolve => setTimeout(resolve, 20));
        const worker = workers.at(-1);
        worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [
            { id: 'a', blockID: 'a', estimate: 80 }, { id: 'b', blockID: 'b', estimate: 160 }] } });
        window.MonoMark.command({ type: 'annotations', value: [{ id: 'offscreen', color: 'yellow', anchors: [
            { blockID: 'b', quote: 'Target', prefix: 'Intro. ', suffix: ' text.', start: 7 }] }] });
        window.MonoMark.command({ type: 'annotation', id: 'offscreen' });
        worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start: 1,
            blocks: [{ id: 'b', html: '<p>Intro. Target text.</p>' }] } });
        await new Promise(resolve => setTimeout(resolve, 20));
        assert.ok(scrolls.at(-1) > 600, `Final scroll was ${scrolls.at(-1)}`);
    }
    finally
    {
        window.HTMLElement.prototype.getBoundingClientRect = original;
        window.scrollTo = originalScroll;
    }
});

test('Pages and Pageless modes keep a bounded document and expose estimated progress', async () => {
    window.MonoMark.command({ type: 'load', epoch: 'page-view' });
    await new Promise(resolve => setTimeout(resolve, 20));
    const worker = workers.at(-1);
    worker.onmessage({ data: { type: 'index', outline: [], links: [], blocks: [{id:'paper-a',blockID:'paper-a',estimate:80}] } });
    window.MonoMark.command({ type:'preferences', value:{layoutMode:'pages',paperWidth:816,paperHeight:1056,paperMargin:48} });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start:0,
        blocks:[{id:'paper-a',html:'<p>Paper content.</p>'}] } });
    await new Promise(resolve => setTimeout(resolve, 20));
    assert.ok(document.querySelector('.monomark-page'));
    assert.equal(window.MonoMark.metrics().layout, 'pages');
    assert.ok(messages.some(message => message.type === 'pages' && message.total >= 1));
    window.MonoMark.command({ type:'preferences', value:{layoutMode:'pageless'} });
    worker.onmessage({ data: { type: 'range', request: worker.sent.at(-1).request, start:0,
        blocks:[{id:'paper-a',html:'<p>Paper content.</p>'}] } });
    assert.equal(document.querySelector('.monomark-page'), null);
    assert.match(document.body.textContent, /Paper content/);
    await new Promise(resolve => setTimeout(resolve, 300));
});

test('deferred math does not oscillate between unfinished and measured page heights', async () => {
    window.MonoMark.command({type:'load',epoch:'stable-paper'});
    await new Promise(resolve => setTimeout(resolve,20));
    const worker = workers.at(-1);
    const original = window.HTMLElement.prototype.getBoundingClientRect;
    let ranges = 0;
    window.HTMLElement.prototype.getBoundingClientRect = function() {
        return {top:0,left:0,width:400,bottom:200,height:this.querySelector('.katex') ? 200 : 80};
    };
    worker.postMessage = message => {
        worker.sent.push(message);
        if (message.type !== 'range') { return; }
        ranges++;
        if (ranges > 6) { return; }
        queueMicrotask(() => worker.onmessage({data:{type:'range',request:message.request,start:0,
            blocks:[{id:'stable',html:'<p><span data-math="x" data-display="false"></span></p>'}]}}));
    };
    try {
        window.MonoMark.command({type:'preferences',value:{layoutMode:'pages'}});
        worker.onmessage({data:{type:'index',outline:[],links:[],blocks:[{id:'stable',blockID:'stable',estimate:200}]}});
        await new Promise(resolve => setTimeout(resolve,150));
        assert.ok(ranges <= 2, `Requested ${ranges} mounts for a stable block`);
    } finally { window.HTMLElement.prototype.getBoundingClientRect = original; }
    await new Promise(resolve => setTimeout(resolve,300));
});

test('document replacement dismisses the previous local link preview', async () => {
    document.getElementById('monomark-preview').hidden = false;
    window.MonoMark.command({type:'load',epoch:'preview-reset'});
    assert.equal(document.getElementById('monomark-preview').hidden,true);
    await new Promise(resolve => setTimeout(resolve,20));
});

test('print cancellation restores the previous block position', async () => {
    window.MonoMark.command({type:'load',epoch:'print-position'});
    await new Promise(resolve => setTimeout(resolve,20));
    const worker = workers.at(-1);
    worker.onmessage({data:{type:'index',outline:[],links:[],blocks:[{id:'reading',blockID:'reading',estimate:200}]}});
    const mount = () => worker.onmessage({data:{type:'range',request:worker.sent.at(-1).request,start:0,
        blocks:[{id:'reading',html:'<p>Reading location.</p>'}]}});
    mount();
    const original = window.HTMLElement.prototype.getBoundingClientRect;
    const originalScroll = window.scrollTo;
    const scrolls = [];
    window.HTMLElement.prototype.getBoundingClientRect = () => ({top:-120,left:0,width:400,height:200,bottom:80});
    window.scrollTo = (_,top) => scrolls.push(top);
    try {
        window.MonoMark.command({type:'print'});
        worker.onmessage({data:{type:'print-page',start:0,blocks:[{html:'<p>Print view.</p>'}]}});
        await new Promise(resolve => setTimeout(resolve,20));
        window.HTMLElement.prototype.getBoundingClientRect = () => ({top:50,left:0,width:400,height:200,bottom:250});
        window.MonoMark.command({type:'afterPrint'});
        mount();
        assert.equal(scrolls.at(-1),170);
    } finally { window.HTMLElement.prototype.getBoundingClientRect = original; window.scrollTo = originalScroll; }
    await new Promise(resolve => setTimeout(resolve,300));
});


test('native palettes follow explicit appearance and system changes', () => {
    window.MonoMark.command({type:'preferences',value:{palettes:{light:{heading1:'#123456'},dark:{heading1:'#abcdef'}}}});
    window.MonoMark.command({type:'appearance',mode:'light'});
    assert.equal(document.documentElement.style.getPropertyValue('--palette-heading1'),'#123456');
    assert.equal(document.getElementById('monomark-syntax').getAttribute('href'),'highlight-light.css');
    window.MonoMark.command({type:'appearance',mode:'dark'});
    assert.equal(document.documentElement.style.getPropertyValue('--palette-heading1'),'#abcdef');
    assert.equal(document.getElementById('monomark-syntax').getAttribute('href'),'highlight-dark.css');
    systemDark = false;
    window.MonoMark.command({type:'appearance',mode:'system'});
    systemDark = true;
    for (const listener of appearanceListeners) { listener(); }
    assert.equal(document.documentElement.style.colorScheme,'dark');
    assert.equal(document.documentElement.style.getPropertyValue('--palette-heading1'),'#abcdef');
    systemDark = false;
    for (const listener of appearanceListeners) { listener(); }
    assert.equal(document.documentElement.style.colorScheme,'light');
});

test('an empty workspace clears stale document content and navigation', async () => {
    window.MonoMark.command({type:'load',epoch:'before-workspace'});
    await new Promise(resolve => setTimeout(resolve,20));
    const worker = workers.at(-1);
    let terminated = false;
    worker.terminate = () => { terminated = true; };
    worker.onmessage({data:{type:'index',outline:[],links:[],blocks:[{id:'old',blockID:'old',estimate:80}]}});
    worker.onmessage({data:{type:'range',request:worker.sent.at(-1).request,start:0,blocks:[{id:'old',html:'<p>Old folder text</p>'}]}});
    window.MonoMark.command({type:'clear',epoch:'empty-workspace'});
    assert.equal(document.querySelectorAll('.monomark-block').length,0);
    assert.equal(window.MonoMark.metrics().blocks,0);
    assert.equal(terminated,true);
    worker.onmessage({data:{type:'index',outline:[],links:[],blocks:[{id:'late',blockID:'late',estimate:80}]}});
    assert.equal(window.MonoMark.metrics().blocks,0);
    await new Promise(resolve => setTimeout(resolve,300));
});
