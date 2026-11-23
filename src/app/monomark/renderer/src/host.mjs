// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: eabec97c-c69a-4d66-810f-2c974f901316
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Host virtualized Markdown, deferred rendering, local previews, and a narrow native bridge.
// RELATES: worker.mjs, ReaderWebView.swift
// FLOW: Validated command -> bounded view update -> native event.

import { printNodeLimit } from './print-budget.mjs';
import { windowRange } from './viewport.mjs';
import { sanitizeDocument } from './sanitizer.mjs';
import { imageBounds, waitForCopyImages } from './artifacts.mjs';
import { renderAnnotations, scrollToAnnotation, resolveAnnotationLocations } from './annotations.mjs';
import { cssFontFamily } from './typography.mjs';
import { paperGeometry, layoutBlocks, pageAt, buildViewport } from './page-layout.mjs';
import { enhanceContent } from './rich-content.mjs';
import { applyPalette } from './palette.mjs';
import { decorateSourceLine } from './source-lines.mjs';
import { createDocumentSelection } from './selection-controller.mjs';

const viewport = document.getElementById('monomark-document');
const status = document.getElementById('monomark-status');
const popover = document.getElementById('monomark-preview');
let worker;
let metadata = [];
let knownBlockIDs = new Set();
let sourceLines = 0;
let indexed = false;
let indexMilliseconds = 0;
let indexSourceBytes = 0;
let offsets = [];
let heights = [];
let outline = [];
let request = 0;
let activeRange = '';
let pendingAnchor;
let readingAnchor;
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
let printSequence = 0;
let printID = 0;
let epoch = '';
let loadSequence = 0;
let paper = paperGeometry();
let paged = false;
let plan = layoutBlocks([], paper, false);
let measureQueued = false;
let renderedEpoch = '';
let copyOverlay;
let pngCopySequence = 0;
let appearance = 'system';
let annotations = [];
let annotationID = 0;
let selectionTimer;
let pendingAnnotation;
let exportSequence = 0;
const pendingExports = new Map();
let mountSequence = 0;
let tableCopySequence = 0;
let tableCopyID = 0;
const documentSelection = createDocumentSelection(window, viewport,
    { blocks: () => metadata, send: message => worker?.postMessage(message), emit });

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
        worker.postMessage({ type: 'export-locations', exportID, annotations: records,
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
    pending.resolve({ annotations: resolveAnnotationLocations(window, root, data.annotations || pending.records), sourceHash: data.sourceHash });
}

function requestAnnotationResolution()
{
    worker?.postMessage({ type: 'resolve-annotations', annotationID, annotations });
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
    // An empty or partially mounted document clamps scrollY before the destination exists in the DOM.
    const destination = pendingAnchor ? destinationIndex(pendingAnchor.id) : -1;
    const top = destination >= 0 ? offsets[destination] : window.scrollY / zoom;
    const range = windowRange(offsets, top, window.innerHeight / zoom);
    const key = `${range.start}:${range.end}`;
    if (!force && key === activeRange) { return; }
    activeRange = key;
    worker.postMessage({ type: 'range', ...range, request: ++request });
}

function mount(message)
{
    if (message.request !== request || printing) { return; }
    if (!pendingAnchor) { pendingAnchor = visibleAnchor(); }
    documentSelection.beginMount();
    const mountedSequence = ++mountSequence;
    viewport.replaceChildren(buildViewport(document, message, plan, paper, makeBlock));
    renderedEpoch = epoch;
    const visible = [...viewport.querySelectorAll('.monomark-block')];
    const mountedEpoch = epoch;
    enhanceMounted(visible, mountedEpoch, mountedSequence);
    rebuildOffsets();
    restoreAnchor(mountedEpoch, mountedSequence);
    decorateAnnotations();
    documentSelection.afterChange();
    emit('visible', { mounted: visible.length });
    savePosition();
}

function enhanceMounted(visible, mountedEpoch, mountedSequence)
{
    // Measure after deferred content finishes, so incomplete math/diagrams cannot shrink a stable page.
    Promise.all(visible.map(enhance)).then(() =>
    {
        if (mountedEpoch === epoch && mountedSequence === mountSequence)
        { decorateAnnotations(); documentSelection.afterMount(); }
    });
}

function restoreAnchor(mountedEpoch, mountedSequence)
{
    const saved = pendingAnchor;
    if (!saved) { return; }
    const align = () =>
    {
        const target = document.getElementById(saved.id);
        if (target) { window.scrollTo(0, target.getBoundingClientRect().top + window.scrollY + saved.offset); }
    };
    align();
    // WebKit can deliver its native scroll update after the DOM range changes.
    requestAnimationFrame(() =>
    {
        if (mountedEpoch !== epoch || mountedSequence !== mountSequence || pendingAnchor !== saved) { return; }
        align();
        requestAnimationFrame(() =>
        {
            if (mountedEpoch !== epoch || mountedSequence !== mountSequence || pendingAnchor !== saved) { return; }
            align(); readingAnchor = saved; pendingAnchor = null; savePosition();
        });
    });
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
        element.dataset.generated = 'true';
        element.textContent = 'This block exceeds the 1 MiB rendered-object limit. Split the source block to view it.';
    }
    else { element.innerHTML = sanitizeDocument(window, block.html); }
    if (preferences.showLineNumbers)
    { decorateSourceLine(document, element, { ...block, line: block.displayLine ?? block.line }, sourceLines); }
    return element;
}

const enhance = element => enhanceContent(element, { measure, emit, copyPNG, copyTable });

function copyTable(tableKey, format)
{
    tableCopyID = ++tableCopySequence;
    worker?.postMessage({ type: 'table-copy', tableKey, format, copyID: tableCopyID });
}

async function copyPNG(element)
{
    const copyEpoch = epoch;
    const copyID = ++pngCopySequence;
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
        emit('copyPNG', { copyID, x: rect.left, y: rect.top, width: bounds.width, height: bounds.height });
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
    const resolved = destinationIndex(id);
    if (resolved < 0) { emit('status', { message: 'This document has no matching destination.' }); return; }
    pendingAnchor = { id, offset };
    window.scrollTo(0, offsets[resolved] * zoom);
    requestRange(true);
}

function destinationIndex(id)
{
    const index = metadata.findIndex(block => block.id === id || block.blockID === id);
    const object = outline.find(item => item.id === id);
    return index >= 0 ? index : metadata.findIndex(block => block.blockID === object?.blockID);
}

function navigateAnnotation(id)
{
    pendingAnnotation = id;
    if (scrollToAnnotation(window, viewport, id)) { pendingAnnotation = null; return; }
    const annotation = annotations.find(item => item.id === id);
    const anchor = annotation?.anchors[0];
    if (!anchor || anchor.resolution === 'pending') { return; }
    if (anchor.resolvedBlockID === null)
    {
        pendingAnnotation = null;
        emit('status', { message: anchor.resolution === 'ambiguous' ? 'This quotation has more than one matching location. The highlight remains in the sidebar.' :
            'The quotation no longer matches the document. The highlight remains in the sidebar.' });
        return;
    }
    if (anchor.resolvedBlockID) { jump(anchor.resolvedBlockID); return; }
    if (metadata.some(block => block.id === anchor.blockID || block.blockID === anchor.blockID)) { jump(anchor.blockID); }
    else
    {
        emit('status', { message: 'The saved location changed. Searching for the quotation.' });
        worker?.postMessage({ type: 'find', query: anchor.quote, request: ++request });
    }
}

function savePosition()
{
    if (renderedEpoch === epoch && !pendingAnchor) { readingAnchor = visibleAnchor() || readingAnchor; }
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
    documentSelection.reset();
    tableCopyID = 0;
    cancelExports();
    const sequence = ++loadSequence;
    popover.hidden = true; currentLink = ''; printAnchor = null; printing = false; printID = 0; printBlocks = [];
    copyOverlay?.remove();
    epoch = command.epoch;
    pendingAnchor = null; readingAnchor = null;
    viewport.replaceChildren();
    emit('selection', { anchors: [] });
    zoom = Math.min(3, Math.max(0.5, Number(command.zoom) || 1));
    document.body.style.zoom = String(zoom);
    renderedEpoch = '';
    annotations = [];
    pendingAnnotation = null;
    clearTimeout(positionTimer);
    worker?.terminate();
    metadata = []; knownBlockIDs = new Set(); sourceLines = 0;
    indexed = false; indexMilliseconds = 0; indexSourceBytes = 0;
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
    if (data.type === 'table-copy' && data.copyID === tableCopyID)
    {
        tableCopyID = 0;
        if (data.error) { emit('status', { message: data.error }); }
        else { emit('copyText', { text: data.text }); }
    }
    if (data.type === 'annotations-resolved' && data.annotationID === annotationID)
    {
        documentSelection.beforeChange();
        annotations = data.annotations;
        decorateAnnotations(); documentSelection.afterChange();
        if (pendingAnnotation) { navigateAnnotation(pendingAnnotation); }
    }
    if (data.type === 'selection-result') { documentSelection.receive(data); }
    if (data.type === 'export-locations') { finishExport(data); }
    if (data.type === 'index')
    {
        metadata = data.blocks;
        indexed = true;
        indexMilliseconds = data.duration || 0;
        indexSourceBytes = data.sourceBytes || 0;
        if (annotations.length) { requestAnnotationResolution(); }
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
    if (renderedEpoch === epoch && !pendingAnchor) { pendingAnchor = readingAnchor || visibleAnchor(); }
    paper = paperGeometry({ width: preferences.paperWidth, height: preferences.paperHeight, margin: preferences.paperMargin }, window.innerWidth / zoom - 64);
    paged = preferences.layoutMode === 'pages';
    document.body.classList.toggle('monomark-paged', paged);
    let printStyle = document.getElementById('monomark-paper-style');
    if (!printStyle) { printStyle = document.createElement('style'); printStyle.id = 'monomark-paper-style'; document.head.append(printStyle); }
    printStyle.textContent = `@page { size: ${paper.physicalWidth * 0.75}pt ${paper.physicalHeight * 0.75}pt; margin: ${paper.physicalMargin * 0.75}pt; }`;
    rebuildOffsets(); activeRange = ''; requestRange(true);
}

/** Keep measured blocks stable when a bounded range or viewport geometry changes. */
function visibleAnchor()
{
    const visible = [...viewport.querySelectorAll('.monomark-block')].find(item =>
    {
        const rect = item.getBoundingClientRect();
        return rect.bottom > 0 && rect.top < window.innerHeight;
    });
    return visible ? { id: visible.id, offset: -visible.getBoundingClientRect().top } : null;
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

function finishPrint()
{
    printing = false; printID = 0; printBlocks = [];
    pendingAnchor = printAnchor; printAnchor = null; activeRange = '';
    requestRange(true);
}

function preparePrint(data)
{
    if (!printing || data.printID !== printID) { return; }
    if (data.error) { finishPrint(); emit('status', { message: data.error }); return; }
    printBlocks.push(...data.blocks);
    const next = data.start + data.blocks.length;
    if (next < metadata.length && data.blocks.length)
    {
        worker.postMessage({ type: 'print', printID, start: next });
        return;
    }
    mountPrint(printID).catch(() =>
    {
        if (printID !== data.printID) { return; }
        finishPrint(); emit('status', { message: 'The print view could not be prepared. Refresh and try again.' });
    });
}

async function mountPrint(generation)
{
    ++mountSequence;
    documentSelection.beforeChange();
    viewport.replaceChildren();
    let nodes = 0;
    for (let index = 0; index < printBlocks.length; index++)
    {
        if (!printing || generation !== printID) { return; }
        const element = makeBlock(printBlocks[index], index);
        viewport.append(element);
        await enhance(element);
        if (!printing || generation !== printID) { return; }
        nodes += 1 + element.querySelectorAll('*').length;
        if (nodes > printNodeLimit)
        {
            finishPrint();
            emit('status', { message: 'Printing is limited to 100,000 rendered elements after diagrams and equations expand. Print a smaller document.' });
            return;
        }
    }
    decorateAnnotations();
    emit('printReady');
}

function clearDocument(command)
{
    documentSelection.reset();
    tableCopyID = 0;
    cancelExports();
    loadSequence++; request++;
    worker?.terminate(); worker = null;
    epoch = command.epoch; renderedEpoch = epoch;
    metadata = []; knownBlockIDs = new Set(); sourceLines = 0; heights = []; outline = []; annotations = []; matches = [];
    indexed = false; indexMilliseconds = 0; indexSourceBytes = 0;
    pendingAnchor = null; readingAnchor = null; pendingAnnotation = null; activeRange = '';
    printing = false; printID = 0; printBlocks = []; printAnchor = null;
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
            documentSelection.beforeChange();
            annotations = (command.value || []).map(note => ({ ...note, anchors: note.anchors.map(anchor =>
                ({ ...anchor, resolvedBlockID: null, resolution: 'pending' })) }));
            annotationID++;
            if (indexed) { requestAnnotationResolution(); }
            decorateAnnotations(); documentSelection.afterChange();
        }
        if (command.type === 'copyComplete' && (!command.epoch || command.epoch === epoch) &&
            (command.copyID === undefined || command.copyID === pngCopySequence))
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
            if (!worker || !indexed || printing) { return; }
            if (metadata.length > 5000) { emit('status', { message: 'Printing is limited to 5,000 blocks in this build.' }); return; }
            const reading = [...viewport.querySelectorAll('.monomark-block')].find(item => item.getBoundingClientRect().bottom > 0);
            printAnchor = reading ? { id: reading.id, offset: -reading.getBoundingClientRect().top } : null;
            printing = true;
            printID = ++printSequence;
            printBlocks = [];
            worker.postMessage({ type: 'print', printID, start: 0 });
        }
        if (command.type === 'afterPrint') { finishPrint(); }
    },
    metrics() { return { indexed, indexMilliseconds, sourceBytes: indexSourceBytes, layout: paged ? 'pages' : 'pageless', pages: plan.totalPages, blocks: metadata.length, mounted: viewport.querySelectorAll('.monomark-block').length, outline: outline.length }; }
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
document.addEventListener('selectionchange', () =>
{
    clearTimeout(selectionTimer);
    selectionTimer = setTimeout(() => documentSelection.selectionChanged(), 120);
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
