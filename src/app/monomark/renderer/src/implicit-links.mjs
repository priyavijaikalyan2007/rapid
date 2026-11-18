// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c745dd51-2d90-4079-9016-c8c43bd544f8
// COMPONENT: Optional implicit navigation
// PURPOSE: Resolve unique workspace paths and numbered headings without changing Markdown source.

import { generatedLine } from './generated-content.mjs';
const key = value => value.normalize('NFC').toLocaleLowerCase();
const numberKey = value => value.split('.').map(part => part.replace(/^0+(?=\d)/, '')).join('.');

export function sectionNumber(title)
{
    return /^(?:section\s+|§\s*)?(\d+(?:\.\d+)*)(?:[.)]?(?:\s|$))/i.exec(title)?.[1];
}

function add(map, name, path)
{
    const folded = key(name);
    const paths = map.get(folded) || [];
    if (!paths.includes(path)) { paths.push(path); }
    map.set(folded, paths);
}

function normalized(path, base = [])
{
    if (!path || path.startsWith('/') || /[:\\\r\n\0]/.test(path) || path.length > 4096) { return null; }
    const parts = [...base];
    for (const part of path.split('/'))
    {
        if (!part || part === '.') { continue; }
        if (part === '..') { if (!parts.length) { return null; } parts.pop(); }
        else { parts.push(part); }
    }
    return parts.join('/');
}

function relativePath(target, base)
{
    const parts = target.split('/');
    let common = 0;
    while (common < base.length && common < parts.length && key(base[common]) === key(parts[common])) { common++; }
    return [...base.slice(common).map(() => '..'), ...parts.slice(common)].join('/');
}

/** Exact relative paths win. Unqualified basenames must be unique when there is no sibling match. */
export function fileResolver(paths = [], documentPath = '')
{
    const byPath = new Map();
    const exactPath = new Map();
    const byName = new Map();
    const base = documentPath.split('/').slice(0, -1);
    for (const path of paths.slice(0, 10000))
    {
        if (typeof path !== 'string' || normalized(path) !== path || !/\.(?:md|markdown)$/i.test(path)) { continue; }
        add(byPath, path, path);
        exactPath.set(path.normalize('NFC'), path);
        add(byName, path.split('/').at(-1), path);
    }
    return value =>
    {
        const [path, ...fragment] = value.split('#');
        const resolved = normalized(path, base);
        if (resolved === null) { return null; }
        let exact = exactPath.get(resolved.normalize('NFC'));
        let matches = exact ? [exact] : byPath.get(key(resolved));
        if (!matches && path.includes('/'))
        {
            const rootPath = normalized(path);
            if (rootPath !== null)
            {
                exact = exactPath.get(rootPath.normalize('NFC'));
                matches = exact ? [exact] : byPath.get(key(rootPath));
            }
        }
        if (!matches && !path.includes('/')) { matches = byName.get(key(path)); }
        if (matches?.length !== 1) { return null; }
        const target = relativePath(matches[0], base);
        return target ? target + (fragment.length ? '#' + fragment.join('#') : '') : null;
    };
}

function link(token, content, href, file)
{
    const open = new token.constructor('link_open', 'a', 1);
    open.attrSet('href', href);
    const label = typeof content === 'string' ? content : content.content;
    open.attrSet('title', file ? `Open ${label} in a new tab` : `Jump to section ${label}`);
    if (file) { open.attrSet('data-new-tab', 'true'); }
    const text = typeof content === 'string' ? new token.constructor('text', '', 0) : content;
    if (typeof content === 'string') { text.content = content; }
    return [open, text, new token.constructor('link_close', 'a', -1)];
}

function textLinks(token, options)
{
    const pattern = /[§#$]\s*\d+(?:\.\d+)*|[^\s<>()[\]{}"']+/gu;
    const result = [];
    let cursor = 0;
    for (const match of token.content.matchAll(pattern))
    {
        const candidate = match[0].replace(/[.,;!?]+$/, '');
        const section = /^[§#$]\s*(\d+(?:\.\d+)*)$/.exec(candidate);
        const targets = section && options.sections?.get(numberKey(section[1]));
        const href = section ? (targets?.length === 1 ? '#' + targets[0] : null) :
            options.implicitFileLinks && /\.(?:md|markdown)(?:#.*)?$/i.test(candidate) ? options.file(candidate) : null;
        if (!href) { continue; }
        if (match.index > cursor)
        {
            const before = new token.constructor('text', '', 0);
            before.content = token.content.slice(cursor, match.index);
            result.push(before);
        }
        result.push(...link(token, candidate, href, !section));
        cursor = match.index + candidate.length;
    }
    if (!cursor) { return [token]; }
    if (cursor < token.content.length)
    {
        const after = new token.constructor('text', '', 0);
        after.content = token.content.slice(cursor);
        result.push(after);
    }
    return result;
}

/** Existing links and math are token boundaries, so their contents never enter the fuzzy matcher. */
export function implicitTokens(tokens, options)
{
    if (!options.implicitFileLinks && !options.implicitSectionLinks) { return tokens; }
    let depth = 0;
    return tokens.flatMap(token =>
    {
        if (token.type === 'link_open') { depth++; return [token]; }
        if (token.type === 'link_close') { depth--; return [token]; }
        if (depth) { return [token]; }
        if (token.type === 'code_inline' && options.implicitFileLinks && /\.(?:md|markdown)(?:#.*)?$/i.test(token.content))
        {
            const href = options.file(token.content);
            if (href) { return link(token, token, href, true); }
        }
        return token.type === 'text' ? textLinks(token, options) : [token];
    });
}

export function headingTargets(tokens, context, options, uniqueID)
{
    const sections = new Map();
    if (!options.implicitSectionLinks) { return sections; }
    for (let index = 0; index < tokens.length; index++)
    {
        if (tokens[index].type !== 'heading_open') { continue; }
        const title = tokens[index + 1]?.content || 'Heading';
        const id = uniqueID(title, context);
        tokens[index].attrSet('id', id);
        if (generatedLine(tokens[index].map?.[0] || 0, context.generatedRanges)) { continue; }
        const number = sectionNumber(title);
        if (number) { add(sections, numberKey(number), id); }
    }
    return sections;
}
