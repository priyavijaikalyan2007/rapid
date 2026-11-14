// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c654730f-d94d-4f60-8361-b6fb60296831
// Created: 2026
// COMPONENT: Renderer contract tests
// PURPOSE: Renderer contract tests.
// RELATES: specs/monomark.implementation.md
// FLOW: Input -> validated processing -> result.

import test from 'node:test';
import assert from 'node:assert/strict';
import { parseDocument, excerpt, findBlocks } from '../src/parser.mjs';
import { windowRange } from '../src/viewport.mjs';

test('duplicate headings receive distinct targets', () => {
    const result = parseDocument('# Same\n\n# Same');
    assert.deepEqual(result.outline.map(item => item.id), ['same', 'same-1']);
});
test('figures tables and equations nest under headings', () => {
    const source = '# Results\n\n![Plot](a.png)\n\n| A | B |\n|---|---|\n|1|2|\n\n$$\nx^2\n$$';
    const result = parseDocument(source);
    assert.deepEqual(result.outline.map(item => item.kind), ['heading', 'figure', 'table', 'equation']);
    assert.equal(result.outline[2].parent, 'results');
});
test('reference definitions resolve across distant blocks', () => {
    const result = parseDocument('[Next][ref]\n\n' + 'text\n\n'.repeat(200) + '[ref]: next.md#part');
    assert.equal(result.links[0].href, 'next.md#part');
});
test('mermaid is deferred and carries an outline target', () => {
    const result = parseDocument('```mermaid\ngraph TD; A-->B\n```');
    assert.equal(result.outline[0].kind, 'diagram');
    assert.match(result.blocks[0].html, /data-mermaid/);
});
test('unsafe links and scripts cannot become active markup', () => {
    const result = parseDocument('<script>alert(1)</script>\n\n[x](javascript:alert(1))');
    assert.doesNotMatch(result.blocks.map(block => block.html).join(''), /<script|href="javascript:/);
});
test('fences protect math and emoji from interpretation', () => {
    const result = parseDocument('```text\n$bad$ :smile:\n```');
    assert.doesNotMatch(result.blocks[0].html, /data-math|😄/);
});
test('math and unicode remain readable', () => {
    const result = parseDocument('Hello :smile: $x+1$ 日本語');
    assert.match(result.blocks[0].html, /data-math/);
    assert.match(result.blocks[0].text, /日本語/);
});
test('complete search includes distant unloaded content', () => {
    const result = parseDocument('begin\n\n' + 'body\n\n'.repeat(500) + 'needle');
    assert.equal(findBlocks(result.blocks, 'needle').length, 1);
});
test('previews omit front matter and limit text', () => {
    assert.equal(excerpt('---\nprivate: yes\n---\n# Book\n\nOpening.'), 'Book Opening.');
    assert.ok(excerpt('x'.repeat(10000)).length <= 600);
});
test('viewport stays bounded at distant offsets', () => {
    const range = windowRange([0, 100, 200, 300, 400, 500], 450, 100, 1);
    assert.ok(range.end - range.start <= 4);
});

test('an image outline target is present in rendered HTML', () => {
    const result = parseDocument('# Art\n\n![A figure](figure.png)');
    assert.match(result.blocks[1].html, /id="monomark-figure-1"/);
});
test('code renderers preserve the language label for deferred highlighting', () => {
    assert.match(parseDocument('```swift\nlet x = 1\n```').blocks[0].html, /language-swift/);
});

test('footnote references retain their generated destinations', () => {
    const result = parseDocument('Text[^one].\n\n[^one]: A source note.');
    const html = result.blocks.map(block => block.html).join('');
    assert.match(html, /A source note/);
    assert.match(html, /fn1/);
});

test('document comments stay hidden while fenced comments remain literal', () => {
    const result = parseDocument('<!-- private metadata -->\n\n# Title\n\n```html\n<!-- literal code -->\n```');
    const html = result.blocks.map(block => block.html).join('');
    assert.doesNotMatch(html, /private metadata/);
    assert.match(html, /literal code/);
});

test('inline comments do not hide surrounding text', () => {
    const result = parseDocument('Before <!-- metadata --> after.');
    assert.doesNotMatch(result.blocks[0].html, /metadata/);
    assert.match(result.blocks[0].html, /Before  after/);
});
