// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 122f66f2-83ae-4a56-a22c-fa115adfa726
// COMPONENT: Bounded paper layout
// PURPOSE: Pack whole blocks into estimated sheets without mounting the entire document.
import { lowerBound } from './viewport.mjs';

const dimension = (value, fallback) => Number.isFinite(value) && value >= 144 && value <= 14000 ? value : fallback;
export function paperGeometry(value = {}, available = 1000)
{
    const width = dimension(value.width, 793.701);
    const height = dimension(value.height, 1122.52);
    const margin = Number.isFinite(value.margin) ? Math.max(0, Math.min(value.margin, width / 4, height / 4)) : 48;
    const scale = Math.min(1, Math.max(144, Number(available) || width) / width);
    return { width: width * scale, height: height * scale, margin: margin * scale, gap: 24,
        physicalWidth: width, physicalHeight: height, physicalMargin: margin };
}

/** Oversized blocks get expanded sheets instead of clipping or duplicating their DOM. */
export function layoutBlocks(values, paper, paged)
{
    const heights = values.map(value => Number.isFinite(value) ? Math.max(1, value) : 32);
    const contentHeight = paper.height - 2 * paper.margin;
    const plan = { paged, contentHeight, offsets: [], sheets: [], sheetForBlock: [], sheetOffsets: [], totalHeight: 0, totalPages: 1 };
    if (!paged)
    {
        for (const height of heights) { plan.offsets.push(plan.totalHeight); plan.totalHeight += height; }
        plan.totalPages = Math.max(1, Math.ceil(plan.totalHeight / contentHeight));
        return plan;
    }
    let sheet;
    let used = 0;
    for (const [index, height] of heights.entries())
    {
        if (!sheet || used + height > contentHeight)
        {
            const top = sheet ? sheet.top + sheet.height + paper.gap : 0;
            const firstPage = sheet ? sheet.firstPage + sheet.pageSpan : 1;
            sheet = { top, firstPage, start: index, end: index, pageSpan: Math.max(1, Math.ceil(height / contentHeight)),
                height: Math.max(paper.height, height + 2 * paper.margin) };
            plan.sheets.push(sheet); plan.sheetOffsets.push(top); used = 0;
        }
        plan.offsets.push(sheet.top + paper.margin + used);
        plan.sheetForBlock.push(plan.sheets.length - 1);
        used += height; sheet.end = index + 1;
    }
    plan.totalHeight = sheet ? sheet.top + sheet.height : paper.height;
    plan.totalPages = sheet ? sheet.firstPage + sheet.pageSpan - 1 : 1;
    return plan;
}

export function pageAt(plan, top)
{
    if (!plan.paged) { return Math.min(plan.totalPages, Math.max(1, Math.floor(top / plan.contentHeight) + 1)); }
    const index = Math.max(0, lowerBound(plan.sheetOffsets, top + 0.01) - 1);
    const sheet = plan.sheets[index];
    return sheet ? sheet.firstPage + Math.min(sheet.pageSpan - 1, Math.max(0, Math.floor((top - sheet.top) / plan.contentHeight))) : 1;
}

function spacer(document, height)
{
    const node = document.createElement('div');
    node.style.height = `${Math.max(0, height)}px`;
    node.setAttribute('aria-hidden', 'true');
    return node;
}

function paperBox(document, sheet, paper, padding)
{
    const node = document.createElement('div');
    node.className = 'monomark-page';
    Object.assign(node.style, { width: `${paper.width}px`, height: `${sheet.height}px`,
        padding: `${padding}px ${paper.margin}px 0`, marginBottom: `${paper.gap}px` });
    const label = document.createElement('div');
    label.className = 'monomark-page-label';
    label.textContent = sheet.pageSpan > 1 ? `Pages ${sheet.firstPage}–${sheet.firstPage + sheet.pageSpan - 1} · large object` : `Page ${sheet.firstPage}`;
    label.setAttribute('aria-hidden', 'true');
    node.append(label);
    return node;
}

/** Only blocks supplied by the bounded worker range become DOM nodes. */
export function buildViewport(document, message, plan, paper, makeBlock)
{
    const fragment = document.createDocumentFragment();
    const first = message.start;
    const end = first + message.blocks.length;
    if (!message.blocks.length) { return fragment; }
    const firstSheet = plan.sheets[plan.sheetForBlock[first]];
    fragment.append(spacer(document, plan.paged ? firstSheet.top : plan.offsets[first]));
    let sheetIndex = -1;
    let target = fragment;
    for (const [index, block] of message.blocks.entries())
    {
        const position = first + index;
        if (plan.paged && plan.sheetForBlock[position] !== sheetIndex)
        {
            sheetIndex = plan.sheetForBlock[position];
            const sheet = plan.sheets[sheetIndex];
            target = paperBox(document, sheet, paper, plan.offsets[position] - sheet.top);
            fragment.append(target);
        }
        target.append(makeBlock(block, position));
    }
    const last = plan.sheets[sheetIndex];
    const bottom = plan.paged ? last.top + last.height + paper.gap : (plan.offsets[end] ?? plan.totalHeight);
    fragment.append(spacer(document, plan.totalHeight - bottom));
    return fragment;
}
