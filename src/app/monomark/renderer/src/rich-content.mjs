// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b63084e0-d9c9-4691-a2ac-748247cfcaf0
// COMPONENT: Deferred rich content
// PURPOSE: Render only mounted math, diagrams, code, and local images.
import { sanitizeDocument, sanitizeDiagram, localImageURL } from './sanitizer.mjs';
import { installArtifactActions } from './artifacts.mjs';
let diagramSequence = 0;
export async function enhanceContent(element, { measure, emit, copyPNG })
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
        const { highlightSource } = await import('./syntax.mjs');
        const language = [...code.classList].find(name => name.startsWith('language-'))?.slice(9);
        const highlighted = highlightSource(code.textContent, language);
        code.classList.add('hljs');
        code.parentElement.dataset.language = highlighted.language;
        code.innerHTML = sanitizeDocument(window, highlighted.html);
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

