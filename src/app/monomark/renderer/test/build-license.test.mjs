// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2ce85dc1-8ea5-4e08-94de-272c66121008
// COMPONENT: Packaged license contract
// PURPOSE: Verify the portable offline app bundle includes the complete project license.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

test('the offline app resources include the complete project license', async () => {
    const project = await readFile(new URL('../../../../../LICENSE', import.meta.url), 'utf8');
    const bundled = await readFile(new URL('../../build/Renderer/MonoMark-LICENSE.txt', import.meta.url), 'utf8');
    assert.equal(bundled, project);
    assert.match(bundled,/GNU GENERAL PUBLIC LICENSE/);
});

test('rebuilding removes obsolete generated renderer assets', async () => {
    const { writeFile, access } = await import('node:fs/promises');
    const { execFileSync } = await import('node:child_process');
    const { fileURLToPath } = await import('node:url');
    const stale = new URL('../../build/Renderer/obsolete-fixture.txt', import.meta.url);
    await writeFile(stale,'This asset belongs to a previous build.');
    execFileSync(process.execPath,['build.mjs'],{cwd:fileURLToPath(new URL('../',import.meta.url)),stdio:'pipe'});
    await assert.rejects(access(stale),{code:'ENOENT'});
});
