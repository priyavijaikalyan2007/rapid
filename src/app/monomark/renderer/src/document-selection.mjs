// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: ed503788-c03d-43d9-a8ca-f0796e9bf3bf
// COMPONENT: Logical document selection
// PURPOSE: Keep UTF-16 endpoints when a bounded viewport replaces their DOM nodes.
import { orderedSelection } from './selection-text.mjs';

const excluded = '.monomark-artifact-actions, .monomark-line-number, .monomark-page-label, [data-math], [data-mermaid], svg, script, style';
const structural = 'section, table, thead, tbody, tfoot, tr, ul, ol, li, blockquote, div';

export function readableNodes(window, root)
{
    const walker = window.document.createTreeWalker(root, window.NodeFilter.SHOW_TEXT);
    const nodes = [];
    for (let node = walker.nextNode(); node; node = walker.nextNode())
    {
        if (node.parentElement.closest(excluded)) { continue; }
        if (node.parentElement.matches(structural) && !node.textContent.trim()) { continue; }
        nodes.push(node);
    }
    return nodes;
}

function endpoint(window, root, node, offset)
{
    const block = (node.nodeType === 1 ? node : node.parentElement)?.closest('.monomark-block');
    if (!block || !root.contains(block)) { return null; }
    const range = window.document.createRange();
    range.selectNodeContents(block);
    range.setEnd(node, offset);
    let length = 0;
    for (const text of readableNodes(window, block))
    {
        if (text === node) { length += offset; break; }
        if (range.intersectsNode(text)) { length += text.length; }
    }
    const index = Number(block.dataset.block);
    return Number.isSafeInteger(index) ? { index, offset: length } : null;
}

function point(window, block, offset)
{
    const nodes = readableNodes(window, block);
    for (const node of nodes)
    {
        if (offset <= node.length) { return [node, offset]; }
        offset -= node.length;
    }
    return nodes.length ? [nodes.at(-1), nodes.at(-1).length] : [block, 0];
}

function signature(selection)
{
    return [selection.anchorNode, selection.anchorOffset, selection.focusNode, selection.focusOffset];
}

/** A DOM selection is a projection of this logical range, not its persistent storage. */
export class DocumentSelection
{
    range = null;
    restored = null;
    extending = false;
    dragging = false;
    pointer = null;

    constructor(window, root) { this.window = window; this.root = root; }

    get isVirtual()
    {
        if (!this.range) { return false; }
        const blocks = [...this.root.querySelectorAll('.monomark-block')];
        return !blocks.some(block => Number(block.dataset.block) === this.range.anchor.index) ||
            !blocks.some(block => Number(block.dataset.block) === this.range.focus.index);
    }

    capture()
    {
        const selection = this.window.getSelection();
        const current = signature(selection);
        if (this.restored?.every((value, index) => value === current[index])) { return; }
        this.restored = null;
        if (!selection.rangeCount || selection.isCollapsed) { this.range = null; return; }
        const anchor = endpoint(this.window, this.root, selection.anchorNode, selection.anchorOffset);
        const focus = endpoint(this.window, this.root, selection.focusNode, selection.focusOffset);
        if (!anchor || !focus) { this.range = null; return; }
        this.range = { anchor: this.range && (this.dragging || this.extending) ? this.range.anchor : anchor, focus };
        this.restored = current;
    }

    restore()
    {
        if (!this.range) { return; }
        if (this.dragging && this.pointer)
        {
            const focus = this.atPointer(this.pointer);
            if (focus) { this.range.focus = focus; }
        }
        const blocks = [...this.root.querySelectorAll('.monomark-block')];
        if (!blocks.length) { return; }
        const [first, last] = orderedSelection(this.range);
        const low = Number(blocks[0].dataset.block);
        const high = Number(blocks.at(-1).dataset.block);
        const selection = this.window.getSelection();
        if (last.index < low || first.index > high)
        { selection.removeAllRanges(); this.restored = signature(selection); return; }
        const start = blocks.find(block => Number(block.dataset.block) === first.index) || blocks[0];
        const end = blocks.find(block => Number(block.dataset.block) === last.index) || blocks.at(-1);
        const a = point(this.window, start, first.index < low ? 0 : first.offset);
        const b = point(this.window, end, last.index > high ? Number.MAX_SAFE_INTEGER : last.offset);
        const forward = first === this.range.anchor;
        selection.setBaseAndExtent(...(forward ? [...a, ...b] : [...b, ...a]));
        this.restored = signature(selection);
    }

    atPointer(event)
    {
        const x = Math.max(1, Math.min(this.window.innerWidth - 2, event.clientX));
        const y = Math.max(1, Math.min(this.window.innerHeight - 2, event.clientY));
        const range = this.window.document.caretRangeFromPoint?.(x, y);
        if (range) { return endpoint(this.window, this.root, range.startContainer, range.startOffset); }
        const position = this.window.document.caretPositionFromPoint?.(x, y);
        return position ? endpoint(this.window, this.root, position.offsetNode, position.offset) : null;
    }

    selectAll(count, lastLength)
    {
        if (!count) { this.reset(); return; }
        this.range = { anchor: { index: 0, offset: 0 }, focus: { index: count - 1, offset: lastLength } };
        this.restore();
    }

    reset()
    {
        this.range = null; this.restored = null; this.extending = false;
        this.dragging = false; this.pointer = null;
    }
}
