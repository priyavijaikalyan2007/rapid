// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: eabec97c-c69a-4d66-810f-2c974f901316
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Host virtualized Markdown, deferred rendering, local previews, and a narrow native bridge.
// RELATES: worker.mjs, ReaderWebView.swift
// FLOW: Validated command -> bounded view update -> native event.

import { windowRange } from './viewport.mjs';
import { sanitizeDocument } from './sanitizer.mjs';
import { imageBounds, waitForCopyImages } from './artifacts.mjs';
import { captureSelection, renderAnnotations, scrollToAnnotation, resolveAnnotationLocations } from './annotations.mjs';
import { cssFontFamily } from './typography.mjs';
import { paperGeometry, layoutBlocks, pageAt, buildViewport } from './page-layout.mjs';
import { enhanceContent } from './rich-content.mjs';
import { applyPalette } from './palette.mjs';
import { decorateSourceLine } from './source-lines.mjs';

const viewport = document.getElementById('monomark-document');
const status = document.getElementById('monomark-status');
const popover = document.getElementById('monomark-preview');
let worker;
let metadata = [];
let knownBlockIDs = new Set();
let sourceLines = 0;
let indexed = false;
let offsets = [];
let heights = [];
let outline = [];
let request = 0;
let activeRange = '';
let pendingAnchor;
let zoom = 1;
let matches = [];
let matchIndex = -1;
let currentLink = '';
let currentLinkNewTab = false;
let scrollFrame = false;
let positionTimer;
let preferences = {};
let printing = false;
let printAnchor;
let printBlocks = [];
let epoch = '';
let loadSequence = 0;
let paper = paperGeometry();
let paged = false;
let plan = layoutBlocks([], paper, false);
let measureQueued = false;
let renderedEpoch = '';
let copyOverlay;
let appearance = 'system';
let annotations = [];
let selectionTimer;
let pendingAnnotation;
let exportSequence = 0;
const pendingExports = new Map();

function cancelExports()
{
    for (const entry of pendingExports.values())
    {
        clearTimeout(entry.timer);
        entry.reject(new Error('The document changed during export. Try again.'));
    }
    pendingExports.clear();
}

function exportLocations(records)
{
    if (!worker || !indexed) { return Promise.reject(new Error('Refresh the document before exporting.')); }
    return new Promise((resolve, reject) =>
    {
        const exportID = ++exportSequence;
        const timer = setTimeout(() =>
        {
            pendingExports.delete(exportID);
            reject(new Error('The source locations could not be resolved in time. Refresh and try again.'));
        }, 10000);
        pendingExports.set(exportID, { resolve, reject, timer, records });
        worker.postMessage({ type: 'export-locations', exportID,
            ids: [...new Set(records.flatMap(annotation => annotation.anchors.map(anchor => anchor.blockID)))] });
    });
}

function finishExport(data)
{
    const pending = pendingExports.get(data.exportID);
    if (!pending) { return; }
    pendingExports.delete(data.exportID);
    clearTimeout(pending.timer);
    if (data.error) { pending.reject(new Error(data.error)); return; }
    const root = document.createElement('div');
    root.replaceChildren(...data.blocks.map((block, index) => makeBlock(block, index)));
    pending.resolve({ annotations: resolveAnnotationLocations(window, root, pending.records), sourceHash: data.sourceHash });
}

function decorateAnnotations()
{
    emit('annotationStatus', renderAnnotations(window, viewport, annotations, knownBlockIDs));
    if (pendingAnnotation && scrollToAnnotation(window, viewport, pendingAnnotation)) { pendingAnnotation = null; }
}

function emit(type, payload = {})
{
    window.webkit?.messageHandlers?.reader?.postMessage({ type, epoch, ...payload });
}

function rebuildOffsets()
{
    plan = layoutBlocks(heights, paper, paged);
    offsets = plan.offsets;
    return plan.totalHeight;
}

function requestRange(force = false)
{
    if (!metadata.length || printing) { return; }
    const range = windowRange(offsets, window.scrollY / zoom, window.innerHeight / zoom);
    const key = `${range.start}:${range.end}`;
    if (!force && key === activeRange) { return; }
    activeRange = key;
    worker.postMessage({ type: 'range', ...range, request: ++request });
}

function mount(message)
{
    if (message.request !== request || printing) { return; }
    viewport.replaceChildren(buildViewport(document, message, plan, paper, makeBlock));
    renderedEpoch = epoch;
    const visible = [...viewport.querySelectorAll('.monomark-block')];
    const enhancements = [];
    for (const element of visible)
    {
        // Measure after deferred content finishes, so incomplete math/diagrams cannot shrink a stable page.
        enhancements.push(enhance(element));
    }
    const mountedEpoch = epoch;
    Promise.all(enhancements).then(() =>
    {
        if (mountedEpoch === epoch) { decorateAnnotations(); }
    });
    rebuildOffsets();
    if (pendingAnchor)
    {
        const saved = pendingAnchor;
        pendingAnchor = null;
        const target = document.getElementById(saved.id);
        if (target) { window.scrollTo(0, target.getBoundingClientRect().top + window.scrollY + saved.offset); }
    }
    decorateAnnotations();
    emit('visible', { mounted: visible.length });
    savePosition();
}

function makeBlock(block, index)
{
    const element = document.createElement('section');
    element.className = 'monomark-block';
    element.id = block.blockID || block.id;
    element.dataset.anchor = block.id;
    element.dataset.block = String(index);
    if (block.generated) { element.dataset.generated = 'true'; }
    if (Number.isInteger(block.line))
    {
        element.dataset.sourceLine = String(block.line + 1);
        element.dataset.sourceEndLine = String(block.endLine || block.line + 1);
        element.dataset.section = block.section || '';
    }
    if (block.html.length > 1024 * 1024)
    {
        element.textContent = 'This block exceeds the 1 MiB rendered-object limit. Split the source block to view it.';
    }
    else { element.innerHTML = sanitizeDocument(window, block.html); }
    if (preferences.showLineNumbers) { decorateSourceLine(document, element, block, sourceLines); }
    return element;
}

const enhance = element => enhanceContent(element, { measure, emit, copyPNG });

async function copyPNG(element)
{
    const copyEpoch = epoch;
    copyOverlay?.remove();
    const clone = element.cloneNode(true);
    clone.querySelectorAll('.monomark-artifact-actions').forEach(node => node.remove());
    copyOverlay = document.createElement('div');
    copyOverlay.className = 'monomark-copy-overlay';
    const width = Math.max(1, element.scrollWidth, element.getBoundingClientRect().width);
    clone.style.width = `${width}px`;
    clone.style.maxWidth = 'none';
    clone.style.overflow = 'visible';
    copyOverlay.append(clone);
    document.body.append(copyOverlay);
    const imagesReady = await waitForCopyImages(clone);
    await Promise.race([document.fonts.ready, new Promise(resolve => setTimeout(resolve, 500))]);
    if (copyEpoch !== epoch || !clone.isConnected) { return; }
    if (!imagesReady)
    {
        copyOverlay.remove();
        emit('status', { message: 'The image is not ready to copy. Wait for it to load, then try again.' });
        return;
    }
    const natural = clone.getBoundingClientRect();
    const bounds = imageBounds(natural.width, natural.height, window.innerWidth - 16, window.innerHeight - 16);
    clone.style.transformOrigin = '0 0';
    clone.style.transform = `scale(${bounds.scale})`;
    // Occluded WebKit windows may suspend animation frames. Native snapshotting supplies the final paint synchronization.
    setTimeout(() =>
    {
        if (copyEpoch !== epoch || !clone.isConnected) { return; }
        const rect = clone.getBoundingClientRect();
        emit('copyPNG', { x: rect.left, y: rect.top, width: bounds.width, height: bounds.height });
    }, 50);
}

function measure(element)
{
    if (!element.isConnected || printing) { return; }
    const index = Number(element.dataset.block);
    const height = Math.max(32, element.getBoundingClientRect().height / zoom);
    if (Math.abs(heights[index] - height) < 1) { return; }
    heights[index] = height;
    if (measureQueued) { return; }
    measureQueued = true;
    queueMicrotask(() =>
    {
        measureQueued = false; rebuildOffsets();
        if (paged) { requestRange(true); }
    });
}

function jump(id, offset = 0)
{
    const index = metadata.findIndex(block => block.id === id || block.blockID === id);
    const object = outline.find(item => item.id === id);
    const resolved = index >= 0 ? index : metadata.findIndex(block => block.blockID === object?.blockID);
    if (resolved < 0) { emit('status', { message: 'This document has no matching destination.' }); return; }
    pendingAnchor = { id, offset };
    window.scrollTo(0, offsets[resolved] * zoom);
    requestRange(true);
}

function navigateAnnotation(id)
{
    pendingAnnotation = id;
    if (scrollToAnnotation(window, viewport, id)) { pendingAnnotation = null; return; }
    const annotation = annotations.find(item => item.id === id);
    const anchor = annotation?.anchors[0];
    if (!anchor) { return; }
    if (metadata.some(block => block.id === anchor.blockID || block.blockID === anchor.blockID)) { jump(anchor.blockID); }
    else
    {
        emit('status', { message: 'The saved location changed. Searching for the quotation.' });
        worker?.postMessage({ type: 'find', query: anchor.quote, request: ++request });
    }
}

function savePosition()
{
    clearTimeout(positionTimer);
    positionTimer = setTimeout(() =>
    {
        if (renderedEpoch !== epoch) { return; }
        const element = [...viewport.querySelectorAll('.monomark-block')].find(item => item.getBoundingClientRect().bottom > 0);
        if (!element) { emit('pages', { current: 1, total: plan.totalPages }); return; }
        emit('pages', { current: pageAt(plan, window.scrollY / zoom), total: plan.totalPages });
        emit('position', { anchor: element.id, offset: -element.getBoundingClientRect().top,
            progress: window.scrollY / Math.max(1, document.documentElement.scrollHeight - window.innerHeight), zoom });
    }, 250);
}

async function load(command)
{
    cancelExports();
    const sequence = ++loadSequence;
    popover.hidden = true; currentLink = ''; printAnchor = null; printing = false;
    copyOverlay?.remove();
    epoch = command.epoch;
    zoom = Math.min(3, Math.max(0.5, Number(command.zoom) || 1));
    document.body.style.zoom = String(zoom);
    renderedEpoch = '';
    annotations = [];
    pendingAnnotation = null;
    clearTimeout(positionTimer);
    worker?.terminate();
    metadata = []; knownBlockIDs = new Set(); sourceLines = 0;
    indexed = false;
    activeRange = '';
    status.textContent = 'Indexing document…';
    const code = await (await fetch('worker.js')).text();
    if (sequence !== loadSequence) { return; }
    const workerURL = URL.createObjectURL(new Blob([code], { type: 'text/javascript' }));
    worker = new Worker(workerURL);
    URL.revokeObjectURL(workerURL);
    worker.onmessage = ({ data }) => { if (sequence === loadSequence) { onWorker(data, command); } };
    const response = await fetch(`monomark://document/source?epoch=${encodeURIComponent(epoch)}`);
    const source = await response.text();
    if (sequence !== loadSequence) { return; }
    worker.postMessage({ type: 'load', source, sourceHash: response.headers?.get('X-MonoMark-Source-Hash') || undefined,
        references: command.references || {} });
}

function onWorker(data, initial)
{
    if (data.type === 'export-locations') { finishExport(data); }
    if (data.type === 'index')
    {
        metadata = data.blocks;
        indexed = true;
        knownBlockIDs = new Set(metadata.filter(block => !block.generated).flatMap(block => [block.id, block.blockID]));
        sourceLines = data.sourceLines || 0;
        document.documentElement.style.setProperty('--line-digits', String(Math.max(2, String(sourceLines).length)));
        outline = data.outline;
        heights = metadata.map(block => block.estimate);
        rebuildOffsets();
        emit('index', { outline, links: data.links, duration: data.duration, sourceBytes: data.sourceBytes, blocks: metadata.length });
        status.textContent = '';
        if (!metadata.length) { viewport.replaceChildren(); renderedEpoch = epoch; emit('visible', { mounted: 0 }); savePosition(); }
        if (initial.anchor) { jump(initial.anchor, initial.offset || 0); }
        else
        {
            window.scrollTo(0, (initial.progress || 0) * rebuildOffsets());
            requestRange(true);
        }
    }
    if (data.type === 'range') { mount(data); }
    if (data.type === 'found')
    {
        matches = data.matches;
        matchIndex = -1;
        nextMatch(1);
        emit('status', { message: `${matches.length} matching blocks` });
    }
    if (data.type === 'failure') { status.textContent = data.message; emit('status', { message: data.message }); }
    if (data.type === 'print-page') { preparePrint(data); }
}

function nextMatch(direction)
{
    if (!matches.length) { return; }
    matchIndex = (matchIndex + direction + matches.length) % matches.length;
    jump(metadata[matches[matchIndex]].id);
}

function applyPreferences(value)
{
    preferences = value || {};
    const style = document.documentElement.style;
    style.setProperty('--reader-font', cssFontFamily(preferences.fontFamily));
    for (const kind of ['heading', 'code', 'table', 'caption'])
    {
        style.setProperty(`--${kind}-font`, cssFontFamily(preferences[`${kind}FontFamily`] || (kind === 'code' ? 'ui-monospace' : preferences.fontFamily)));
    }
    for (const [key, property, fallback] of [['bodySize', '--body-size', 15], ['codeSize', '--code-size', 14],
        ['tableSize', '--table-size', 14], ['captionSize', '--caption-size', 13], ['pageWidth', '--page-width', 960]])
    {
        style.setProperty(property, `${Number(preferences[key]) || fallback}px`);
    }
    (preferences.headingSizes || [30, 25, 21, 18, 16, 15]).forEach((size, index) => style.setProperty(`--h${index + 1}`, `${Number(size)}px`));
    style.setProperty('--line-height', String(preferences.lineHeight || 1.65));
    document.body.classList.toggle('monomark-column-banding', !!preferences.columnBanding);
    document.body.classList.toggle('monomark-preserve-breaks', !!preferences.preserveLineBreaks);
    document.body.classList.toggle('monomark-line-numbers', !!preferences.showLineNumbers);
    applyPalette(document, preferences.palettes, document.documentElement.style.colorScheme === 'dark');
    configureLayout();
}

function configureLayout()
{
    const visible = [...viewport.querySelectorAll('.monomark-block')].find(item => item.getBoundingClientRect().bottom > 0);
    if (visible && renderedEpoch === epoch && !pendingAnchor)
    {
        pendingAnchor = { id: visible.id, offset: -visible.getBoundingClientRect().top };
    }
    paper = paperGeometry({ width: preferences.paperWidth, height: preferences.paperHeight, margin: preferences.paperMargin }, window.innerWidth / zoom - 64);
    paged = preferences.layoutMode === 'pages';
    document.body.classList.toggle('monomark-paged', paged);
    let printStyle = document.getElementById('monomark-paper-style');
    if (!printStyle) { printStyle = document.createElement('style'); printStyle.id = 'monomark-paper-style'; document.head.append(printStyle); }
    printStyle.textContent = `@page { size: ${paper.physicalWidth * 0.75}pt ${paper.physicalHeight * 0.75}pt; margin: ${paper.physicalMargin * 0.75}pt; }`;
    rebuildOffsets(); activeRange = ''; requestRange(true);
}

function applyAppearance(mode)
{
    appearance = ['light', 'dark'].includes(mode) ? mode : 'system';
    const dark = appearance === 'dark' || (appearance === 'system' && matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
    applyPalette(document, preferences.palettes, dark);
    document.getElementById('monomark-syntax')?.setAttribute('href', dark ? 'highlight-dark.css' : 'highlight-light.css');
    for (const diagram of viewport.querySelectorAll('[data-mermaid]'))
    {
        diagram.replaceChildren();
        enhance(diagram.parentElement);
    }
}

function showLink(link, rect, newTab = false)
{
    currentLink = link;
    currentLinkNewTab = newTab;
    popover.hidden = false;
    popover.style.left = `${Math.min(rect.left, window.innerWidth - 350)}px`;
    popover.style.top = `${Math.min(rect.bottom + 6, window.innerHeight - 230)}px`;
    document.getElementById('monomark-preview-address').textContent = link;
    document.getElementById('monomark-preview-text').textContent = 'Loading local preview…';
    emit('preview', { href: link });
}

function preparePrint(data)
{
    printBlocks.push(...data.blocks);
    if (data.blocks.length === 100 && data.start + 100 < metadata.length)
    {
        worker.postMessage({ type: 'print', start: data.start + 100 });
        return;
    }
    // A bounded print limit prevents a huge print DOM. The UI reports this limit before starting a job.
    viewport.innerHTML = sanitizeDocument(window, printBlocks.map(block => block.html).join(''));
    Promise.all([...viewport.children].map(element => enhance(element))).then(() => emit('printReady'));
}

function clearDocument(command)
{
    cancelExports();
    loadSequence++; request++;
    worker?.terminate(); worker = null;
    epoch = command.epoch; renderedEpoch = epoch;
    metadata = []; knownBlockIDs = new Set(); sourceLines = 0; heights = []; outline = []; annotations = []; matches = [];
    indexed = false;
    pendingAnchor = null; pendingAnnotation = null; activeRange = '';
    printing = false; printBlocks = []; printAnchor = null;
    clearTimeout(positionTimer); clearTimeout(selectionTimer);
    copyOverlay?.remove(); popover.hidden = true;
    viewport.replaceChildren(); status.textContent = '';
    rebuildOffsets(); emit('visible', { mounted: 0 });
}

window.MonoMark = {
    exportLocations,
    command(command)
    {
        if (command.type === 'clear') { clearDocument(command); }
        if (command.type === 'load') { load(command).catch(() => emit('status', { message: 'The document could not be loaded.' })); }
        if (command.type === 'preferences') { applyPreferences(command.value); }
        if (command.type === 'appearance') { applyAppearance(command.mode); }
        if (command.type === 'annotations')
        {
            annotations = command.value || [];
            decorateAnnotations();
        }
        if (command.type === 'copyComplete' && (!command.epoch || command.epoch === epoch))
        { copyOverlay?.remove(); copyOverlay = null; }
        if (command.type === 'jump') { jump(command.id); }
        if (command.type === 'annotation') { navigateAnnotation(command.id); }
        if (command.type === 'find') { worker?.postMessage({ type: 'find', query: command.query, request: ++request }); }
        if (command.type === 'next') { nextMatch(command.direction || 1); }
        if (command.type === 'zoom')
        {
            zoom = Math.min(3, Math.max(0.5, command.value === 0 ? 1 : zoom + command.value));
            document.body.style.zoom = String(zoom);
            configureLayout();
        }
        if (command.type === 'preview' && command.href === currentLink)
        {
            document.getElementById('monomark-preview-text').textContent = command.text;
        }
        if (command.type === 'print')
        {
            if (metadata.length > 5000) { emit('status', { message: 'Printing is limited to 5,000 blocks in this build.' }); return; }
            const reading = [...viewport.querySelectorAll('.monomark-block')].find(item => item.getBoundingClientRect().bottom > 0);
            printAnchor = reading ? { id: reading.id, offset: -reading.getBoundingClientRect().top } : null;
            printing = true;
            printBlocks = [];
            worker.postMessage({ type: 'print', start: 0 });
        }
        if (command.type === 'afterPrint') { printing = false; pendingAnchor = printAnchor; printAnchor = null; activeRange = ''; requestRange(true); }
    },
    metrics() { return { layout: paged ? 'pages' : 'pageless', pages: plan.totalPages, blocks: metadata.length, mounted: viewport.querySelectorAll('.monomark-block').length, outline: outline.length }; }
};

window.addEventListener('scroll', () =>
{
    if (!scrollFrame)
    {
        scrollFrame = true;
        requestAnimationFrame(() => { scrollFrame = false; requestRange(); savePosition(); });
    }
}, { passive: true });
window.addEventListener('resize', configureLayout);
document.addEventListener('click', event =>
{
    const annotation = event.target.closest('mark[data-annotation]');
    if (annotation)
    {
        event.preventDefault();
        emit('annotationSelected', { id: annotation.dataset.annotation });
        navigateAnnotation(annotation.dataset.annotation);
        return;
    }
    const anchor = event.target.closest('a');
    if (!anchor) { return; }
    event.preventDefault();
    emit('navigate', { href: anchor.getAttribute('href'), newTab: event.metaKey || anchor.dataset.newTab === 'true' });
});
function reportSelection()
{
    emit('selection', { anchors: captureSelection(window, viewport) });
}
document.addEventListener('mouseup', reportSelection);
document.addEventListener('keyup', reportSelection);
document.addEventListener('selectionchange', () =>
{
    clearTimeout(selectionTimer);
    selectionTimer = setTimeout(reportSelection, 120);
});
document.addEventListener('pointerover', event =>
{
    const anchor = event.target.closest('a');
    if (anchor) { showLink(anchor.getAttribute('href'), anchor.getBoundingClientRect(), anchor.dataset.newTab === 'true'); }
});
document.addEventListener('focusin', event =>
{
    const anchor = event.target.closest('a');
    if (anchor) { showLink(anchor.getAttribute('href'), anchor.getBoundingClientRect(), anchor.dataset.newTab === 'true'); }
});
document.addEventListener('keydown', event =>
{
    const mark = event.target.closest('mark[data-annotation]');
    if (mark && ['Enter', ' '].includes(event.key))
    {
        event.preventDefault();
        mark.click();
    }
    if (event.key === 'Escape' && !popover.hidden) { popover.hidden = true; event.stopPropagation(); event.preventDefault(); }
});
for (const [id, type] of [['monomark-open', 'navigate'], ['monomark-open-tab', 'navigate'], ['monomark-copy', 'copy']])
{
    document.getElementById(id).onclick = () =>
    {
        emit(type, { href: currentLink, newTab: id === 'monomark-open-tab' || (type === 'navigate' && currentLinkNewTab) });
        popover.hidden = true;
    };
}
emit('ready');
if (typeof matchMedia === 'function')
{
    matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () =>
    {
        if (appearance === 'system') { applyAppearance('system'); }
    });
    applyAppearance('system');
}
