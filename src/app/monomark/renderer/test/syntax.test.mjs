// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 626d1f75-884f-4473-be9b-6aeaf56f3522
// COMPONENT: Code grammar regressions
// PURPOSE: Verify real C sharp, SQL, and Java tokens and aliases.
import test from 'node:test';
import assert from 'node:assert/strict';
import { highlightSource } from '../src/syntax.mjs';

for (const language of ['c#', 'cs', 'c-sharp', 'CSharp'])
{
    test(`${language} highlights class keywords strings and comments`, () => {
        const result = highlightSource('public class Example { string text = "value"; // comment\n}', language);
        assert.equal(result.language, 'csharp');
        for (const token of ['hljs-keyword', 'hljs-title', 'hljs-string', 'hljs-comment']) { assert.match(result.html, new RegExp(token)); }
    });
}
for (const [language, source] of [['sql', "SELECT id FROM users WHERE name = 'Alice'; -- comment"],
    ['java', 'public class Example { String text = "value"; // comment\n}']])
{
    test(`${language} has grammar-specific rich tokens`, () => {
        const result = highlightSource(source, language);
        for (const token of ['hljs-keyword', 'hljs-string', 'hljs-comment']) { assert.match(result.html, new RegExp(token)); }
    });
}
test('unknown languages remain escaped literal text', () => {
    const result = highlightSource('<script>bad()</script>', 'unknown');
    assert.equal(result.html, '&lt;script&gt;bad()&lt;/script&gt;');
});
