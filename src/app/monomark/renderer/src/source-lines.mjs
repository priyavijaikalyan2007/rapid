// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d41085dc-221f-4aef-b840-e09cb8537235
// COMPONENT: Source line gutter
// PURPOSE: Label rendered block starts without adding selectable document text.

/** Source maps are zero-based. Labels use the full document's digit width, with a two-digit minimum. */
export function sourceLineLabel(line, total)
{
    return String(line + 1).padStart(Math.max(2, String(total).length), '0');
}

/** A rendered paragraph or artifact can cover several source lines. Its tooltip states the full range. */
export function decorateSourceLine(document, element, block, total)
{
    if (!Number.isInteger(block.line)) { return; }
    const label = document.createElement('span');
    label.className = 'monomark-line-number';
    label.textContent = sourceLineLabel(block.line, total);
    label.setAttribute('aria-hidden', 'true');
    label.setAttribute('contenteditable', 'false');
    label.title = `Source lines ${block.line + 1}–${Math.max(block.line + 1, block.endLine || block.line + 1)}`;
    element.prepend(label);
}
