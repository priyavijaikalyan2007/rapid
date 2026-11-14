// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 1f7e9c31-0cf8-4b88-9f3e-af2ca9d18336
// COMPONENT: Reading annotation anchors
// PURPOSE: Capture quoted text and decorate only unambiguous visible matches.
// FLOW: DOM selection -> quote anchors -> native persistence -> viewport decorations.

const excluded = '.monomark-artifact-actions, .katex, svg, script, style';
const colors = new Set(['yellow', 'green', 'blue', 'pink', 'purple']);

function textNodes(window, block)
{
    const walker = window.document.createTreeWalker(block, window.NodeFilter.SHOW_TEXT);
    const nodes = [];
    for (let node = walker.nextNode(); node; node = walker.nextNode())
    {
        if (!node.parentElement.closest(excluded)) { nodes.push(node); }
    }
    return nodes;
}

/** A selection may span mounted blocks. Equations and diagram internals are separate artifacts. */
export function captureSelection(window, root)
{
    const selection = window.getSelection();
    if (!selection.rangeCount || selection.isCollapsed) { return []; }
    const range = selection.getRangeAt(0);
    if (!root.contains(range.startContainer) || !root.contains(range.endContainer)) { return []; }
    const anchors = [];
    for (const block of root.querySelectorAll('.monomark-block'))
    {
        const nodes = textNodes(window, block);
        const text = nodes.map(node => node.textContent).join('');
        let cursor = 0;
        let start;
        let end;
        for (const node of nodes)
        {
            if (range.intersectsNode(node))
            {
                start ??= cursor + (node === range.startContainer ? range.startOffset : 0);
                end = cursor + (node === range.endContainer ? range.endOffset : node.length);
            }
            cursor += node.length;
        }
        if (start === undefined || end <= start) { continue; }
        anchors.push({ blockID: block.id, quote: text.slice(start, end), start,
            prefix: Array.from(text.slice(0, start)).slice(-32).join(''),
            suffix: Array.from(text.slice(end)).slice(0, 32).join('') });
    }
    if (anchors.length > 128 || anchors.some(anchor => anchor.quote.length > 16000)) { return []; }
    return anchors;
}

function locate(blocks, anchor)
{
    const matches = [];
    for (const block of blocks)
    {
        for (let start = block.text.indexOf(anchor.quote); start >= 0; start = block.text.indexOf(anchor.quote, start + 1))
        {
            if (!block.text.slice(0, start).endsWith(anchor.prefix) ||
                !block.text.slice(start + anchor.quote.length).startsWith(anchor.suffix)) { continue; }
            matches.push({ ...block, start, end: start + anchor.quote.length });
        }
    }
    return matches.length === 1 ? matches[0] : null;
}

function decorate(window, match, annotation)
{
    let cursor = 0;
    for (const node of textNodes(window, match.element))
    {
        const length = node.length;
        const start = Math.max(0, match.start - cursor);
        const end = Math.min(length, match.end - cursor);
        if (end > start && !node.parentElement.closest('mark[data-annotation]'))
        {
            const range = window.document.createRange();
            range.setStart(node, start);
            range.setEnd(node, end);
            const mark = window.document.createElement('mark');
            mark.dataset.annotation = annotation.id;
            mark.tabIndex = 0;
            mark.dataset.color = colors.has(annotation.color) ? annotation.color : 'yellow';
            mark.title = annotation.comment || 'Highlight';
            range.surroundContents(mark);
        }
        cursor += length;
    }
}

/** Missing or ambiguous quotes remain available in the native sidebar without guessing an attachment. */
export function renderAnnotations(window, root, annotations)
{
    for (const mark of root.querySelectorAll('mark[data-annotation]'))
    {
        const parent = mark.parentNode;
        mark.replaceWith(...mark.childNodes);
        parent.normalize();
    }
    const blocks = [...root.querySelectorAll('.monomark-block')].map(element =>
        ({ element, text: textNodes(window, element).map(node => node.textContent).join('') }));
    const result = { attached: [], unresolved: [] };
    for (const annotation of annotations)
    {
        const matches = annotation.anchors.map(anchor => locate(blocks, anchor));
        if (matches.some(match => !match)) { result.unresolved.push(annotation.id); continue; }
        matches.forEach(match => decorate(window, match, annotation));
        result.attached.push(annotation.id);
    }
    return result;
}

/** Use the first marked line rather than the beginning of a potentially long paragraph. */
export function scrollToAnnotation(window, root, id)
{
    const mark = [...root.querySelectorAll('mark[data-annotation]')].find(node => node.dataset.annotation === id);
    if (!mark) { return false; }
    window.scrollTo(0, Math.max(0, mark.getBoundingClientRect().top + window.scrollY - window.innerHeight * 0.25));
    return true;
}
