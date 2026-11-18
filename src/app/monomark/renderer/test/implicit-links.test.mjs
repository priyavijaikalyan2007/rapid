// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: a4a45967-75fe-438b-907f-dd887f731e94
// COMPONENT: Optional implicit navigation contracts
// PURPOSE: Link unique file/section references while preserving code, math, and ambiguous prose.
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseDocument } from '../src/parser.mjs';
import { JSDOM } from 'jsdom';

function root(source, referenceOptions = {})
{
    const result = parseDocument(source, referenceOptions);
    return { result, document: new JSDOM(result.blocks.map(block => block.html).join('')).window.document };
}

test('optional file references resolve sibling, relative, and unique basename paths', () => {
    const options = { implicitFileLinks: true, documentPath: 'specs/Reader.md',
        linkPaths: ['specs/Other.md', 'docs/Guide.md', 'docs/My File.md'] };
    const { document, result } = root('See Other.md, ../docs/Guide.md and `My File.md`.', options);
    assert.deepEqual([...document.querySelectorAll('a')].map(a => a.getAttribute('href')),
        ['Other.md', '../docs/Guide.md', '../docs/My File.md']);
    assert.equal(document.querySelectorAll('a[data-new-tab="true"]').length, 3);
    assert.equal(result.links.length, 3);
    assert.equal(document.querySelector('a code')?.textContent, 'My File.md');
    assert.match(document.querySelector('a code').parentElement.title, /My File.md/);
    assert.equal(result.links[2].title, 'My File.md');
});

test('ambiguous, missing, external, escaping, and ordinary code references stay unchanged', () => {
    const options = { implicitFileLinks: true, documentPath: 'specs/Reader.md',
        linkPaths: ['a/Duplicate.md', 'b/Duplicate.md', 'and.md', 'Other.md'] };
    const { document } = root('Duplicate.md Missing.md ../../Other.md https://example.org/Other.md\n\n' +
        '`and`\n\n```text\nOther.md\n```\n\n[Other.md](manual.md)', options);
    assert.equal(document.querySelectorAll('a[data-new-tab]').length, 0);
    assert.equal(document.querySelector('pre a'), null);
    assert.equal(document.querySelector('a[href="manual.md"]').textContent, 'Other.md');
});

test('section symbols resolve unique forward headings and leave duplicates alone', () => {
    const { document, result } = root('See §9, #9.1 and $9.\n\n## 9. Rendering\n\n### 9.1 Tables\n\n' +
        '## 2. First\n\n## 2. Repeated\n\n§2\n\n`#9` and $x_9$\n', { implicitSectionLinks: true });
    assert.deepEqual([...document.querySelectorAll('a')].map(a => a.getAttribute('href')),
        ['#9-rendering', '#91-tables', '#9-rendering']);
    assert.equal(document.querySelector('code a'), null);
    assert.equal(result.links.length, 3);
});

test('implicit navigation is off by default and never rewrites authored links', () => {
    const { document } = root('Other.md §9\n\n## 9. Rendering\n\n[§9](#authored)');
    assert.equal(document.querySelectorAll('a').length, 1);
    assert.equal(document.querySelector('a').getAttribute('href'), '#authored');
});

test('generated reading data remains outside implicit linking', () => {
    const { document } = root('<!-- monomark:inline:notes:start -->\n\nOther.md §9\n\n' +
        '<!-- monomark:inline:notes:end -->\n\n## 9. Rendering',
    { implicitFileLinks: true, implicitSectionLinks: true, linkPaths: ['Other.md'], documentPath: 'Reader.md' });
    assert.equal(document.querySelectorAll('a').length, 0);
});

test('generated numbered headings cannot make an original section reference ambiguous', () => {
    const { document } = root('See §9.\n\n## 9. Original\n\n<!-- monomark:inline:notes:start -->\n\n' +
        '## 9. A reading note\n\n<!-- monomark:inline:notes:end -->', { implicitSectionLinks: true });
    assert.equal(document.querySelector('a')?.getAttribute('href'), '#9-original');
});

test('exact filename case wins before case-insensitive fallback', () => {
    const { document } = root('A.md and a.md', { implicitFileLinks: true,
        documentPath: 'Reader.md', linkPaths: ['A.md', 'a.md'] });
    assert.deepEqual([...document.querySelectorAll('a')].map(a => a.getAttribute('href')), ['A.md', 'a.md']);
});
