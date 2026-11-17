// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: f2072555-af71-4db9-910e-fd75f28a12c4
// COMPONENT: Command-line launch contracts
// PURPOSE: Verify relative paths, symlinks, quoting, and validation before a native launch.
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, copyFileSync, symlinkSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

function fixture(run)
{
    const folder = mkdtempSync(path.join(tmpdir(), 'monomark-cli-'));
    try
    {
        const bundle = path.join(folder, 'Test App.app');
        const resources = path.join(bundle, 'Contents/Resources/Renderer');
        mkdirSync(resources, { recursive: true });
        mkdirSync(path.join(bundle, 'Contents/MacOS'));
        writeFileSync(path.join(bundle, 'Contents/MacOS/MonoMark'), '');
        const tool = path.join(resources, 'monomark');
        copyFileSync(fileURLToPath(new URL('../../tools/monomark', import.meta.url)), tool);
        mkdirSync(path.join(folder, 'Docs'));
        writeFileSync(path.join(folder, 'Docs/One.md'), '# One');
        writeFileSync(path.join(folder, 'Docs/Two with spaces.md'), '# Two');
        const link = path.join(folder, 'monomark');
        symlinkSync(tool, link);
        run({ folder, bundle, link });
    }
    finally { rmSync(folder, { recursive: true, force: true }); }
}

test('a symlinked launcher resolves dot and parent workspace paths', () => fixture(({ folder, link }) => {
    for (const target of ['.', '..'])
    {
        const result = spawnSync('/bin/bash', [link, '--dry-run', target], { cwd: path.join(folder, 'Docs'), encoding: 'utf8' });
        assert.equal(result.status, 0, result.stderr);
        assert.match(result.stdout, /\/usr\/bin\/open -a .*Test\\ App.app/);
        assert.ok(result.stdout.includes(target === '.' ? '/Docs' : folder));
    }
}));

test('multiple Markdown files preserve spaces and remain separate arguments', () => fixture(({ folder, link }) => {
    const result = spawnSync('/bin/bash', [link, '--dry-run', 'One.md', 'Two with spaces.md'],
        { cwd: path.join(folder, 'Docs'), encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /One.md .*Two\\ with\\ spaces.md/);
}));

test('invalid paths fail before opening any file', () => fixture(({ folder, link }) => {
    const result = spawnSync('/bin/bash', [link, '--dry-run', 'One.md', 'Missing.md'],
        { cwd: path.join(folder, 'Docs'), encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.equal(result.stdout, '');
    assert.match(result.stderr, /Missing.md/);
}));

test('usage and non-Markdown input do not launch the app', () => fixture(({ folder, link }) => {
    const help = spawnSync('/bin/bash', [link, '--help'], { encoding: 'utf8' });
    assert.equal(help.status, 0);
    assert.match(help.stdout, /monomark/);
    writeFileSync(path.join(folder, 'Not-markdown.txt'), 'Text');
    const invalid = spawnSync('/bin/bash', [link, '--dry-run', path.join(folder, 'Not-markdown.txt')], { encoding: 'utf8' });
    assert.notEqual(invalid.status, 0);
}));
