// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0431d396-c844-46e9-a366-2fbd6845182d
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Parse Markdown once and derive source-aligned rendering and navigation indexes.
// RELATES: specs/monomark.implementation.md
// FLOW: Source -> indexed blocks -> visible content.

import MarkdownIt from 'markdown-it';
import footnote from 'markdown-it-footnote';
import { full as emoji } from 'markdown-it-emoji';

const escape = new MarkdownIt().utils.escapeHtml;

/** Math is recognized by the Markdown parser, so literal code never enters the math renderer. */
function mathPlugin(md)
{
    md.inline.ruler.after('escape', 'math_inline', (state, silent) =>
    {
        const start = state.pos;
        if (state.src[start] !== '$' || state.src[start + 1] === '$') { return false; }
        const end = state.src.indexOf('$', start + 1);
        if (end < 0 || state.src.slice(start + 1, end).includes('\n')) { return false; }
        if (!silent)
        {
            const token = state.push('math_inline', 'span', 0);
            token.content = state.src.slice(start + 1, end);
        }
        state.pos = end + 1;
        return true;
    });
    md.block.ruler.before('fence', 'math_block', (state, startLine, endLine, silent) =>
    {
        const start = state.bMarks[startLine] + state.tShift[startLine];
        if (state.src.slice(start, start + 2) !== '$$') { return false; }
        if (silent) { return true; }
        const first = state.src.slice(start + 2, state.eMarks[startLine]);
        let line = startLine;
        let content = first;
        if (first.endsWith('$$')) { content = first.slice(0, -2); }
        else
        {
            while (++line < endLine)
            {
                const value = state.src.slice(state.bMarks[line], state.eMarks[line]);
                if (value.trim() === '$$') { break; }
                content += '\n' + value;
            }
        }
        const token = state.push('math_block', 'div', 0);
        token.content = content;
        token.map = [startLine, Math.min(line + 1, endLine)];
        state.line = token.map[1];
        return true;
    });
    for (const name of ['math_inline', 'math_block'])
    {
        md.renderer.rules[name] = (tokens, index) =>
            `<${name === 'math_block' ? 'div' : 'span'} data-math="${escape(encodeURIComponent(tokens[index].content))}" data-display="${name === 'math_block'}"></${name === 'math_block' ? 'div' : 'span'}>`;
    }
}

/** One authoritative parse resolves whole-document references before extracting independently renderable blocks. */
export function parseDocument(source)
{
    const started = performance.now();
    const md = new MarkdownIt({ html: false, linkify: true, maxNesting: 64 }).use(footnote).use(mathPlugin);
    // The emoji plugin still uses the helper removed in Markdown-it 15. Keep the adapter local to this parser.
    md.utils.assign = Object.assign;
    md.utils.has = (object, key) => Object.hasOwn(object, key);
    md.use(emoji);
    md.renderer.rules.softbreak = () => '<span class="monomark-softbreak">\n</span>';
    md.inline.ruler.before('html_inline', 'document_comment_inline', state =>
    {
        if (state.src.slice(state.pos, state.pos + 4) !== '<!--') { return false; }
        const end = state.src.indexOf('-->', state.pos + 4);
        if (end < 0) { return false; }
        state.pos = end + 3;
        return true;
    });
    md.block.ruler.before('paragraph', 'document_comment', (state, startLine, endLine) =>
    {
        const start = state.bMarks[startLine] + state.tShift[startLine];
        if (state.src.slice(start, start + 4) !== '<!--') { return false; }
        let line = startLine;
        while (line < endLine && !state.src.slice(state.bMarks[line], state.eMarks[line]).includes('-->')) { line++; }
        if (line >= endLine) { return false; }
        state.line = line + 1;
        return true;
    });
    const fence = md.renderer.rules.fence.bind(md.renderer.rules);
    md.renderer.rules.fence = (tokens, index, ...rest) =>
    {
        const token = tokens[index];
        if (token.info.trim() === 'mermaid')
        {
            return `<div class="monomark-diagram" data-mermaid="${escape(encodeURIComponent(token.content))}"></div>`;
        }
        return fence(tokens, index, ...rest);
    };
    md.renderer.rules.image = (tokens, index) =>
    {
        const token = tokens[index];
        return `<img id="${escape(token.attrGet('id') || '')}" loading="lazy" data-src="${escape(token.attrGet('src') || '')}" alt="${escape(token.content)}">`;
    };
    const text = source.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').replace(/\0/g, '\uFFFD')
        .replace(/^---\n[\s\S]*?\n---(?:\n|$)/, match => match.replace(/[^\n]/g, ''));
    const environment = {};
    // Keep block structure and global references, but release each block's expensive inline token graph after rendering.
    const tokens = [];
    const footnoteTail = md.core.ruler.getRules('').find(rule => rule.name === 'footnote_tail');
    md.core.ruler.disable('footnote_tail');
    md.block.parse(text, md, environment, tokens);
    const context = { outline: [], links: [], used: new Map(), headings: [], counts: {}, blocks: [] };
    for (let start = 0; start < tokens.length;)
    {
        let end = start + 1;
        if (tokens[start].nesting === 1)
        {
            let depth = 1;
            while (end < tokens.length && depth > 0) { depth += tokens[end++].nesting; }
        }
        if (tokens[start].type !== 'footnote_reference_open')
        {
            addBlock(tokens.slice(start, end), md, environment, context);
        }
        start = end;
    }
    if (footnoteTail && environment.footnotes?.list?.length)
    {
        const state = new md.core.State(text, md, environment);
        state.tokens = tokens;
        footnoteTail(state);
        const tail = state.tokens.findIndex(token => token.type === 'footnote_block_open');
        if (tail >= 0) { addBlock(state.tokens.slice(tail), md, environment, context); }
    }
    return { ...context, headings: undefined, used: undefined, counts: undefined,
        duration: performance.now() - started, sourceBytes: new TextEncoder().encode(source).length,
        sourceLines: text.split('\n').length };
}

function uniqueID(title, context)
{
    const base = title.toLowerCase().trim().replace(/[^\p{L}\p{N}\s_-]/gu, '').replace(/\s+/g, '-') || 'section';
    const count = context.used.get(base) || 0;
    context.used.set(base, count + 1);
    return count ? `${base}-${count}` : base;
}

function addObject(kind, title, token, context, blockID)
{
    const count = (context.counts[kind] || 0) + 1;
    context.counts[kind] = count;
    const id = `monomark-${kind}-${count}`;
    token.attrSet('id', id);
    const parent = context.headings.at(-1);
    context.outline.push({ id, title: title || `${kind[0].toUpperCase() + kind.slice(1)} ${count}`,
        kind, parent: parent?.id || null, level: (parent?.level || 0) + 1, blockID });
    return id;
}

function indexInline(token, context, blockID)
{
    const children = token.children || [];
    for (let index = 0; index < children.length; index++)
    {
        const child = children[index];
        if (child.type === 'image')
        {
            const id = addObject('figure', child.content, child, context, blockID);
            context.links.push({ href: child.attrGet('src'), title: child.content || 'Image', kind: 'image', blockID, id });
        }
        if (child.type === 'link_open')
        {
            const title = children.slice(index + 1).find(item => item.type === 'text')?.content || child.attrGet('href');
            context.links.push({ href: child.attrGet('href'), title, kind: 'link', blockID });
        }
    }
}

function addBlock(tokens, md, environment, context)
{
    for (const token of tokens)
    {
        if (token.type === 'inline') { token.children = md.parseInline(token.content, environment)[0].children; }
    }
    const blockID = `block-${context.blocks.length}`;
    let id = blockID;
    for (let index = 0; index < tokens.length; index++)
    {
        const token = tokens[index];
        if (token.type === 'heading_open')
        {
            const title = tokens[index + 1]?.content || 'Heading';
            id = uniqueID(title, context);
            const level = Number(token.tag.slice(1));
            while (context.headings.at(-1)?.level >= level) { context.headings.pop(); }
            const parent = context.headings.at(-1)?.id || null;
            context.outline.push({ id, title, level, kind: 'heading', parent, blockID });
            context.headings.push({ id, level });
            token.attrSet('id', id);
        }
        if (token.type === 'table_open') { id = addObject('table', '', token, context, blockID); }
        if (token.type === 'math_block') { id = addObject('equation', '', token, context, blockID); }
        if (token.type === 'fence' && token.info.trim() === 'mermaid')
        {
            id = addObject('diagram', '', token, context, blockID);
        }
        if (token.type === 'inline') { indexInline(token, context, blockID); }
    }
    const text = tokens.map(token => token.type === 'inline' || token.type === 'fence' ? token.content : '').join(' ');
    const html = md.renderer.render(tokens, md.options, environment);
    for (const token of tokens) { if (token.type === 'inline') { token.children = null; } }
    context.blocks.push({ id, blockID, html, text, line: tokens.find(token => token.map)?.map?.[0] || 0,
        endLine: tokens.reduce((end, token) => Math.max(end, token.map?.[1] || 0), 0),
        estimate: Math.min(12000, Math.max(48, Math.ceil(text.length / 90) * 26 + (html.includes('<table') ? 100 : 0))) });
}

/** Preview text has a fixed output bound and omits front matter and code fences. */
export function excerpt(source)
{
    return source.slice(0, 16384).replace(/^---\r?\n[\s\S]*?\r?\n---(?:\r?\n|$)/, '')
        .replace(/```[\s\S]*?```|~~~[\s\S]*?~~~/g, '').replace(/!\[[^\]]*\]\([^)]*\)/g, '')
        .replace(/(^|\n)[#>* -]+/g, '$1').replace(/\s+/g, ' ').trim().slice(0, 600);
}

/** Search covers the full indexed document independently of mounted blocks. */
export function findBlocks(blocks, query)
{
    const needle = query.toLocaleLowerCase();
    if (!needle) { return []; }
    return blocks.flatMap((block, index) => block.text.toLocaleLowerCase().includes(needle) ? [index] : []);
}
