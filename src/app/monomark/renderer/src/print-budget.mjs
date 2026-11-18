// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 14659903-536c-45ba-95eb-af222022c985
// COMPONENT: Print resource limits
// PURPOSE: Preflight complete documents before creating their print DOM.
export const printNodeLimit = 100000;

/** Limits reject whole jobs. A successful job never silently omits large blocks. */
export function printBudget(blocks)
{
    if (blocks.length > 5000) { return 'Printing is limited to 5,000 blocks. Print a smaller document.'; }
    let bytes = 0;
    let nodes = blocks.length;
    const encoder = new TextEncoder();
    for (const block of blocks)
    {
        if (block.html.length > 1024 * 1024)
        { return 'Printing cannot include a block above the 1 MiB rendered-object limit. Split the source block.'; }
        bytes += encoder.encode(block.html).length;
        nodes += [...block.html.matchAll(/<[a-z][^>]*>/gi)].length;
        if (bytes > 16 * 1024 * 1024) { return 'Printing is limited to 16 MiB of rendered HTML. Print a smaller document.'; }
        if (nodes > printNodeLimit) { return 'Printing is limited to 100,000 rendered elements. Print a smaller document.'; }
    }
    return null;
}
