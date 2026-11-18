// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 8d2c26c5-5fea-4dad-98eb-68eb8588072d
// COMPONENT: Artifact clipboard actions
// PURPOSE: Export exact source and structured table data without editing Markdown.
// FLOW: Artifact -> requested representation -> native clipboard.

/** RFC-style quoting also preserves delimiters and newlines in TSV and pipe-separated exports. */
export function serializeRows(rows, delimiter = ',')
{
    return rows.map(row => row.map(value =>
    {
        const text = String(value);
        return text.includes(delimiter) || /["\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
    }).join(delimiter)).join('\n');
}

export function artifactSource(kind, data, text = '')
{
    if (kind === 'equation') { return decodeURIComponent(data.math || ''); }
    if (kind === 'diagram') { return decodeURIComponent(data.mermaid || ''); }
    return text;
}

/** Fit the complete artifact for a bounded native snapshot instead of copying a clipped viewport. */
export function imageBounds(width, height, availableWidth, availableHeight)
{
    const scale = Math.min(1, availableWidth / Math.max(1, width), availableHeight / Math.max(1, height));
    return { width: Math.ceil(width * scale), height: Math.ceil(height * scale), scale };
}

function tableRows(table)
{
    return [...table.rows].map(row => [...row.cells].map(cell =>
    {
        const copy = cell.cloneNode(true);
        copy.querySelectorAll('.monomark-artifact-actions, .katex-mathml').forEach(node => node.remove());
        copy.querySelectorAll('[data-math]').forEach(node => { node.textContent = decodeURIComponent(node.dataset.math); });
        return copy.textContent.trim();
    }));
}

function icon(format)
{
    const path = format === 'PNG' ? '<path d="M3 3h18v18H3z M4 17l5-6 4 4 3-3 5 6"/>'
        : '<path d="M8 7V3h13v14h-4 M3 7h14v14H3z"/>';
    const label = ['CSV', 'TSV', 'PSV'].includes(format) ? `<text x="12" y="16" text-anchor="middle" stroke="none" fill="currentColor" font-size="6">${format}</text>` : '';
    return `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">${path}${label}</svg>`;
}

/** Static icons carry native tooltips and accessible labels. Copy actions never enter the document navigation path. */
export function installArtifactActions(root, handlers)
{
    const candidates = root.querySelectorAll('table, pre, [data-mermaid], [data-math], img');
    for (const element of candidates)
    {
        if (element.dataset.copyActions) { continue; }
        element.dataset.copyActions = 'true';
        const kind = element.tagName === 'TABLE' ? 'table' : element.dataset.mermaid !== undefined ? 'diagram'
            : element.dataset.math !== undefined ? 'equation' : element.tagName === 'IMG' ? 'image' : 'code';
        const wrapper = document.createElement(element.tagName === 'SPAN' ? 'span' : 'div');
        wrapper.className = `monomark-artifact monomark-artifact-${kind}`;
        element.replaceWith(wrapper);
        wrapper.append(element);
        const actions = document.createElement('span');
        actions.className = 'monomark-artifact-actions';
        actions.setAttribute('role', 'group');
        actions.setAttribute('aria-label', `${kind} copy actions`);
        const formats = kind === 'table' ? ['CSV', 'TSV', 'PSV'] : kind === 'code' ? ['Text'] : kind === 'image' ? ['PNG'] : ['Source', 'PNG'];
        for (const format of formats)
        {
            const button = document.createElement('button');
            button.type = 'button';
            button.title = element.dataset.tableKey ? `Copy entire table as ${format}` :
                kind === 'equation' && format === 'Source' ? 'Copy equation as LaTeX' : `Copy ${kind} as ${format}`;
            button.setAttribute('aria-label', button.title);
            button.innerHTML = icon(format);
            button.onclick = event =>
            {
                event.stopPropagation();
                if (format === 'PNG') { handlers.png(element); return; }
                if (kind === 'table' && element.dataset.tableKey)
                { handlers.table(element.dataset.tableKey, format); return; }
                const text = kind === 'table' ? serializeRows(tableRows(element), { CSV: ',', TSV: '\t', PSV: '|' }[format])
                    : artifactSource(kind, element.dataset, element.textContent);
                handlers.text(text);
            };
            actions.append(button);
        }
        wrapper.append(actions);
    }
}

/** A cloned image has a separate decode lifecycle, even when its source is already visible. */
export async function waitForCopyImages(root, timeout = 2000)
{
    const images = [...root.querySelectorAll('img')];
    if (root.tagName === 'IMG') { images.push(root); }
    if (!images.length) { return true; }
    let timer;
    const decode = async () =>
    {
        try
        {
            await Promise.all(images.map(async image =>
            {
                if (typeof image.decode === 'function') { await image.decode(); }
                else if (!image.complete || !image.naturalWidth) { throw new Error('Image not ready'); }
            }));
            return true;
        }
        catch { return false; }
    };
    try
    {
        return await Promise.race([decode(), new Promise(resolve => { timer = setTimeout(() => resolve(false), timeout); })]);
    }
    finally { clearTimeout(timer); }
}
