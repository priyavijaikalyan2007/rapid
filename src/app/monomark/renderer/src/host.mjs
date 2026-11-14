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
import { sanitizeDocument, sanitizeDiagram, localImageURL } from './sanitizer.mjs';
import { installArtifactActions, imageBounds } from './artifacts.mjs';
import { captureSelection, renderAnnotations } from './annotations.mjs';

const viewport = document.getElementById('monomark-document');
const status = document.getElementById('monomark-status');
const popover = document.getElementById('monomark-preview');
let worker;
let metadata = [];
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
let scrollFrame = false;
let positionTimer;
let preferences = {};
let printing = false;
let printBlocks = [];
let epoch = '';
let loadSequence = 0;
let diagramSequence = 0;
let renderedEpoch = '';
let copyOverlay;
let appearance = 'system';
let annotations = [];
let selectionTimer;

function decorateAnnotations()
{
    emit('annotationStatus', renderAnnotations(window, viewport, annotations));
}

function emit(type, payload = {})
{
    window.webkit?.messageHandlers?.reader?.postMessage({ type, epoch, ...payload });
}

function rebuildOffsets()
{
    let sum = 0;
    offsets = heights.map(height => { const value = sum; sum += height; return value; });
    return sum;
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
    const top = document.createElement('div');
    top.style.height = `${offsets[message.start] || 0}px`;
    const fragment = document.createDocumentFragment();
    fragment.append(top);
    for (const [index, block] of message.blocks.entries())
    {
        const element = document.createElement('section');
        element.className = 'monomark-block';
        element.id = block.id;
        element.dataset.block = String(message.start + index);
        if (block.html.length > 1024 * 1024)
        {
            element.textContent = 'This block exceeds the 1 MiB rendered-object limit. Split the source block to view it.';
        }
        else { element.innerHTML = sanitizeDocument(window, block.html); }
        fragment.append(element);
    }
    const bottom = document.createElement('div');
    const end = message.start + message.blocks.length;
    bottom.style.height = `${Math.max(0, rebuildOffsets() - (offsets[end] ?? rebuildOffsets()))}px`;
    fragment.append(bottom);
    viewport.replaceChildren(fragment);
    renderedEpoch = epoch;
    const visible = [...viewport.querySelectorAll('.monomark-block')];
    const enhancements = [];
    for (const element of visible)
    {
        heights[Number(element.dataset.block)] = Math.max(32, element.getBoundingClientRect().height / zoom);
        enhancements.push(enhance(element));
    }
    const mountedEpoch = epoch;
    decorateAnnotations();
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
    emit('visible', { mounted: visible.length });
    savePosition();
}

async function enhance(element)
{
    for (const image of element.querySelectorAll('img[data-src]'))
    {
        const url = localImageURL(image.dataset.src);
        if (url) { image.src = url; }
        else { image.title = 'Remote or unsupported image blocked. Use the Links sidebar to open its source.'; }
        image.addEventListener('load', () => measure(element), { once: true });
        image.addEventListener('error', () => { image.alt = `${image.alt} (image unavailable)`; }, { once: true });
    }
    for (const math of element.querySelectorAll('[data-math]'))
    {
        try
        {
            const { default: katex } = await import('katex');
            const source = decodeURIComponent(math.dataset.math);
            if (source.length > 16384) { throw new Error('limit'); }
            math.innerHTML = sanitizeDocument(window, katex.renderToString(source, {
                displayMode: math.dataset.display === 'true', throwOnError: false, trust: false,
                maxExpand: 500, maxSize: 20, output: 'htmlAndMathml'
            }));
        }
        catch { math.textContent = 'Math could not be rendered.'; }
    }
    for (const code of element.querySelectorAll('pre code[class*="language-"]'))
    {
        if (code.textContent.length > 100000) { continue; }
        const { default: highlight } = await import('highlight.js/lib/common');
        const language = [...code.classList].find(name => name.startsWith('language-'))?.slice(9);
        if (highlight.getLanguage(language))
        {
            code.innerHTML = sanitizeDocument(window, highlight.highlight(code.textContent, { language }).value);
        }
    }
    for (const diagram of element.querySelectorAll('[data-mermaid]'))
    {
        try
        {
            const source = decodeURIComponent(diagram.dataset.mermaid);
            if (source.length > 16384) { throw new Error('limit'); }
            const { default: mermaid } = await import('mermaid');
            mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', maxTextSize: 16384, maxEdges: 500,
                htmlLabels: false, theme: document.documentElement.style.colorScheme === 'dark' ? 'dark' : 'default' });
            const output = await mermaid.render(`diagram-${++diagramSequence}`, source);
            diagram.innerHTML = sanitizeDiagram(window, output.svg);
        }
        catch { diagram.textContent = 'Diagram could not be rendered. Its syntax or complexity exceeds this viewer’s limits.'; }
    }
    installArtifactActions(element, { text: text => emit('copyText', { text }), png: copyPNG });
    measure(element);
}

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
    await Promise.race([document.fonts.ready, new Promise(resolve => setTimeout(resolve, 500))]);
    if (copyEpoch !== epoch || !clone.isConnected) { return; }
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
    heights[Number(element.dataset.block)] = Math.max(32, element.getBoundingClientRect().height / zoom);
    rebuildOffsets();
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

function savePosition()
{
    clearTimeout(positionTimer);
    positionTimer = setTimeout(() =>
    {
        if (renderedEpoch !== epoch) { return; }
        const element = [...viewport.querySelectorAll('.monomark-block')].find(item => item.getBoundingClientRect().bottom > 0);
        if (!element) { return; }
        emit('position', { anchor: element.id, offset: -element.getBoundingClientRect().top,
            progress: window.scrollY / Math.max(1, document.documentElement.scrollHeight - window.innerHeight), zoom });
    }, 250);
}

async function load(command)
{
    const sequence = ++loadSequence;
    copyOverlay?.remove();
    epoch = command.epoch;
    zoom = Math.min(3, Math.max(0.5, Number(command.zoom) || 1));
    document.body.style.zoom = String(zoom);
    renderedEpoch = '';
    annotations = [];
    clearTimeout(positionTimer);
    worker?.terminate();
    metadata = [];
    activeRange = '';
    status.textContent = 'Indexing document…';
    const code = await (await fetch('worker.js')).text();
    if (sequence !== loadSequence) { return; }
    const workerURL = URL.createObjectURL(new Blob([code], { type: 'text/javascript' }));
    worker = new Worker(workerURL);
    URL.revokeObjectURL(workerURL);
    worker.onmessage = ({ data }) => onWorker(data, command);
    const source = await (await fetch(`monomark://document/source?epoch=${encodeURIComponent(epoch)}`)).text();
    if (sequence !== loadSequence) { return; }
    worker.postMessage({ type: 'load', source });
}

function onWorker(data, initial)
{
    if (data.type === 'index')
    {
        metadata = data.blocks;
        outline = data.outline;
        heights = metadata.map(block => block.estimate);
        rebuildOffsets();
        emit('index', { outline, links: data.links, duration: data.duration, sourceBytes: data.sourceBytes, blocks: metadata.length });
        status.textContent = '';
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
    style.setProperty('--reader-font', preferences.fontFamily || 'ui-monospace');
    for (const kind of ['heading', 'code', 'table', 'caption'])
    {
        style.setProperty(`--${kind}-font`, preferences[`${kind}FontFamily`] || preferences.fontFamily || 'ui-monospace');
    }
    for (const [key, property, fallback] of [['bodySize', '--body-size', 15], ['codeSize', '--code-size', 14],
        ['tableSize', '--table-size', 14], ['captionSize', '--caption-size', 13], ['pageWidth', '--page-width', 960]])
    {
        style.setProperty(property, `${Number(preferences[key]) || fallback}px`);
    }
    (preferences.headingSizes || [30, 25, 21, 18, 16, 15]).forEach((size, index) => style.setProperty(`--h${index + 1}`, `${Number(size)}px`));
    style.setProperty('--line-height', String(preferences.lineHeight || 1.65));
    document.body.classList.toggle('monomark-column-banding', !!preferences.columnBanding);
}

function applyAppearance(mode)
{
    appearance = ['light', 'dark'].includes(mode) ? mode : 'system';
    const dark = appearance === 'dark' || (appearance === 'system' && matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
    document.getElementById('monomark-syntax')?.setAttribute('href', dark ? 'highlight-dark.css' : 'highlight-light.css');
    for (const diagram of viewport.querySelectorAll('[data-mermaid]'))
    {
        diagram.replaceChildren();
        enhance(diagram.parentElement);
    }
}

function showLink(link, rect)
{
    currentLink = link;
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

window.MonoMark = {
    command(command)
    {
        if (command.type === 'load') { load(command).catch(() => emit('status', { message: 'The document could not be loaded.' })); }
        if (command.type === 'preferences') { applyPreferences(command.value); }
        if (command.type === 'appearance') { applyAppearance(command.mode); }
        if (command.type === 'annotations')
        {
            annotations = command.value || [];
            decorateAnnotations();
        }
        if (command.type === 'copyComplete') { copyOverlay?.remove(); copyOverlay = null; }
        if (command.type === 'jump') { jump(command.id); }
        if (command.type === 'find') { worker?.postMessage({ type: 'find', query: command.query, request: ++request }); }
        if (command.type === 'next') { nextMatch(command.direction || 1); }
        if (command.type === 'zoom')
        {
            zoom = Math.min(3, Math.max(0.5, command.value === 0 ? 1 : zoom + command.value));
            document.body.style.zoom = String(zoom);
            requestRange(true);
        }
        if (command.type === 'preview' && command.href === currentLink)
        {
            document.getElementById('monomark-preview-text').textContent = command.text;
        }
        if (command.type === 'print')
        {
            if (metadata.length > 5000) { emit('status', { message: 'Printing is limited to 5,000 blocks in this build.' }); return; }
            printing = true;
            printBlocks = [];
            worker.postMessage({ type: 'print', start: 0 });
        }
        if (command.type === 'afterPrint') { printing = false; activeRange = ''; requestRange(true); }
    },
    metrics() { return { blocks: metadata.length, mounted: viewport.querySelectorAll('.monomark-block').length, outline: outline.length }; }
};

window.addEventListener('scroll', () =>
{
    if (!scrollFrame)
    {
        scrollFrame = true;
        requestAnimationFrame(() => { scrollFrame = false; requestRange(); savePosition(); });
    }
}, { passive: true });
window.addEventListener('resize', () => requestRange(true));
document.addEventListener('click', event =>
{
    const annotation = event.target.closest('mark[data-annotation]');
    if (annotation)
    {
        event.preventDefault();
        emit('annotationSelected', { id: annotation.dataset.annotation });
        return;
    }
    const anchor = event.target.closest('a');
    if (!anchor) { return; }
    event.preventDefault();
    emit('navigate', { href: anchor.getAttribute('href'), newTab: event.metaKey });
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
    if (anchor) { showLink(anchor.getAttribute('href'), anchor.getBoundingClientRect()); }
});
document.addEventListener('focusin', event =>
{
    const anchor = event.target.closest('a');
    if (anchor) { showLink(anchor.getAttribute('href'), anchor.getBoundingClientRect()); }
});
document.addEventListener('keydown', event =>
{
    if (event.key === 'Escape' && !popover.hidden) { popover.hidden = true; event.stopPropagation(); event.preventDefault(); }
});
for (const [id, type] of [['monomark-open', 'navigate'], ['monomark-open-tab', 'navigate'], ['monomark-copy', 'copy']])
{
    document.getElementById(id).onclick = () => { emit(type, { href: currentLink, newTab: id === 'monomark-open-tab' }); popover.hidden = true; };
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
