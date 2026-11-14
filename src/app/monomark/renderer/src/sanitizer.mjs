// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 14c417f2-7cb2-4b41-a99d-de1a8e398104
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Sanitize rich output and separate resource resolution from permission checks.
// RELATES: worker.mjs, ReaderWebView.swift
// FLOW: Validated command -> bounded view update -> native event.

import createDOMPurify from 'dompurify';

const diagramProperties = new Set([
    'fill', 'fill-opacity', 'fill-rule', 'stroke', 'stroke-width', 'stroke-opacity', 'stroke-dasharray',
    'stroke-dashoffset', 'stroke-linecap', 'stroke-linejoin', 'stroke-miterlimit', 'opacity', 'color',
    'font-family', 'font-size', 'font-weight', 'font-style', 'text-anchor', 'dominant-baseline',
    'alignment-baseline', 'white-space', 'visibility', 'display', 'marker-start', 'marker-mid', 'marker-end',
    'paint-order', 'shape-rendering', 'text-decoration', 'max-width', 'width', 'height'
]);

/** Flatten generated SVG styles before removing style elements that could change the reader page. */
export function sanitizeDiagram(window, source)
{
    const container = window.document.createElement('div');
    container.innerHTML = sanitizeDocument(window, source.replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, ''));
    const svg = container.querySelector('svg');
    if (!svg) { return ''; }
    const original = new Map([...svg.querySelectorAll('[style]'), svg].map(node => [node, node.getAttribute('style')]));
    for (const node of original.keys()) { node.removeAttribute('style'); }
    for (const match of source.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi))
    {
        const sheet = new window.CSSStyleSheet();
        sheet.replaceSync(match[1]);
        applyDiagramRules(svg, sheet.cssRules);
    }
    for (const [node, value] of original)
    {
        const holder = window.document.createElement('span');
        holder.setAttribute('style', value || '');
        copyDiagramStyle(holder.style, node.style);
    }
    return sanitizeDocument(window, svg.outerHTML);
}

function applyDiagramRules(svg, rules)
{
    for (const rule of rules)
    {
        if (!rule.selectorText || !rule.style) { continue; }
        try
        {
            const matches = [...svg.querySelectorAll(rule.selectorText)];
            if (svg.matches(rule.selectorText)) { matches.push(svg); }
            for (const node of matches) { copyDiagramStyle(rule.style, node.style); }
        }
        catch { /* Unsupported diagram selectors do not prevent the remaining SVG from rendering. */ }
    }
}

function copyDiagramStyle(source, target)
{
    for (let index = 0; index < source.length; index++)
    {
        const property = source[index];
        const value = source.getPropertyValue(property);
        if (!diagramProperties.has(property) || /[<>\\]|(?:expression|var)\s*\(/i.test(value)) { continue; }
        if (/url\s*\(/i.test(value) && !/^url\(["']?#[\w:.-]+["']?\)$/i.test(value)) { continue; }
        target.setProperty(property, value, source.getPropertyPriority(property));
    }
}

/** Application-owned generated HTML is still sanitized before insertion. */
export function sanitizeDocument(window, html)
{
    return createDOMPurify(window).sanitize(html, {
        FORBID_TAGS: ['script', 'iframe', 'object', 'embed', 'form', 'input', 'style', 'link', 'meta', 'foreignObject'],
        FORBID_ATTR: ['srcdoc', 'formaction'],
        ADD_ATTR: ['data-src', 'data-mermaid', 'data-math', 'data-display'],
        ALLOW_UNKNOWN_PROTOCOLS: false
    });
}

/** Remote resources require an explicit native grant. The scheme handler rechecks resolved filesystem scope. */
export function localImageURL(source)
{
    if (!source || /^\s*(?:[a-z][a-z0-9+.-]*:|\/\/)/i.test(source)) { return null; }
    return `monomark://document/image?path=${encodeURIComponent(source)}`;
}
