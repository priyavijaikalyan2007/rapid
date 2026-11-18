// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d5791228-52fc-4650-989a-d571f4fb944c
// COMPONENT: Native selection command adapter
// PURPOSE: Connect standard selection gestures to bounded worker-backed copy and highlights.
import { DocumentSelection } from './document-selection.mjs';
import { captureSelection } from './annotations.mjs';

class DocumentSelectionController
{
    sequence = 0;
    copyID = 0;
    anchorID = 0;
    anchorKey = '';
    all = false;
    changing = false;
    frame;

    constructor(window, root, { blocks, send, emit })
    {
        Object.assign(this, { window, root, blocks, send, emit });
        this.selection = new DocumentSelection(window, root);
        this.registerPointer();
        this.registerKeyboard();
        window.document.addEventListener('copy', event => this.copy(event));
        window.addEventListener('blur', () => this.stopDrag());
    }

    key() { return JSON.stringify(this.selection.range); }

    capture()
    {
        const native = this.window.getSelection();
        if (this.changing && native.isCollapsed && this.selection.range) { return; }
        if (!this.changing && native.rangeCount && !native.isCollapsed)
        {
            const range = native.getRangeAt(0);
            const metadata = this.blocks();
            if (metadata.length && range.intersectsNode(this.root) && range.comparePoint(this.root, 0) === 0 &&
                range.comparePoint(this.root, this.root.childNodes.length) === 0)
            { this.all = true; this.selection.selectAll(metadata.length, metadata.at(-1).textLength || 0); }
        }
        this.selection.capture();
        if (!this.selection.range) { this.all = false; }
    }

    report()
    {
        this.capture();
        if (this.selection.range && (this.selection.isVirtual || this.all))
        {
            const value = this.key();
            if (value === this.anchorKey) { return; }
            this.anchorKey = value; this.anchorID = ++this.sequence;
            this.send({ type: 'selection', purpose: 'anchors', selectionID: this.anchorID, range: this.selection.range });
        }
        else
        {
            this.anchorID = 0; this.anchorKey = '';
            this.emit('selection', { anchors: captureSelection(this.window, this.root) });
        }
    }

    receive(data)
    {
        if (data.purpose === 'copy' && data.selectionID === this.copyID)
        {
            this.copyID = 0;
            if (data.error) { this.emit('status', { message: data.error }); }
            else { this.emit('copyText', { text: data.text }); }
        }
        if (data.purpose === 'anchors' && data.selectionID === this.anchorID && this.key() === this.anchorKey)
        {
            this.emit('selection', { anchors: data.anchors || [] });
            if (data.error) { this.emit('status', { message: data.error }); }
        }
    }

    selectAll()
    {
        const metadata = this.blocks();
        this.all = true;
        this.selection.selectAll(metadata.length, metadata.at(-1)?.textLength || 0);
        this.report();
    }

    copy(event)
    {
        this.capture();
        if (!this.selection.range || (!this.selection.isVirtual && !this.all)) { return; }
        event.preventDefault(); this.copyID = ++this.sequence;
        this.send({ type: 'selection', purpose: 'copy', selectionID: this.copyID, range: this.selection.range });
    }

    stopDrag()
    {
        this.selection.dragging = false; this.selection.pointer = null;
        if (this.frame !== undefined) { this.window.cancelAnimationFrame(this.frame); this.frame = undefined; }
    }

    dragScroll()
    {
        this.frame = undefined;
        if (!this.selection.dragging || !this.selection.range || !this.selection.isVirtual || !this.selection.pointer) { return; }
        const y = this.selection.pointer.clientY;
        const delta = y < 32 ? -Math.min(32, 32 - y) : y > this.window.innerHeight - 32 ?
            Math.min(32, y - this.window.innerHeight + 32) : 0;
        if (!delta) { return; }
        this.window.scrollBy(0, delta);
        this.moveFocus(this.selection.pointer);
        this.frame = this.window.requestAnimationFrame(() => this.dragScroll());
    }

    moveFocus(event)
    {
        const focus = this.selection.atPointer(event);
        if (focus) { this.selection.range.focus = focus; this.selection.restore(); this.report(); }
    }

    movePointer(event)
    {
        if (!this.selection.dragging) { return; }
        if (event.buttons !== 1) { this.stopDrag(); return; }
        this.selection.pointer = { clientX: event.clientX, clientY: event.clientY };
        if (!this.selection.isVirtual) { return; }
        this.moveFocus(event);
        if (this.frame === undefined) { this.frame = this.window.requestAnimationFrame(() => this.dragScroll()); }
    }

    registerPointer()
    {
        this.root.addEventListener('mousedown', event =>
        {
            if (event.button !== 0) { return; }
            if (!event.shiftKey) { this.selection.reset(); this.all = false; this.anchorKey = ''; }
            this.selection.dragging = true; this.selection.extending = event.shiftKey;
        });
        this.window.document.addEventListener('mousemove', event => this.movePointer(event));
        this.window.document.addEventListener('mouseup', () =>
        { this.report(); this.stopDrag(); this.selection.extending = false; });
    }

    registerKeyboard()
    {
        this.window.document.addEventListener('keydown', event =>
        {
            this.selection.extending = event.shiftKey;
            if (event.metaKey && !event.ctrlKey && event.key.toLowerCase() === 'a' &&
                !event.target.closest?.('input, textarea, [contenteditable="true"]'))
            { event.preventDefault(); this.selectAll(); }
        });
        this.window.document.addEventListener('keyup', () => { this.report(); this.selection.extending = false; });
    }

    beforeChange() { if (!this.changing) { this.capture(); } }
    beginMount() { this.beforeChange(); this.changing = true; }
    afterChange() { this.selection.restore(); }
    afterMount() { this.selection.restore(); this.changing = false; }
    selectionChanged() { if (!this.changing) { this.report(); } }

    reset()
    {
        this.stopDrag(); this.selection.reset(); this.all = false; this.changing = false;
        this.anchorKey = ''; this.copyID = 0; this.anchorID = 0;
    }
}

export function createDocumentSelection(window, root, options)
{
    return new DocumentSelectionController(window, root, options);
}
