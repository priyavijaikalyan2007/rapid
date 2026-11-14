// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 0f81a1f3-f740-4bcc-b9a3-408c8dc62197
// Created: 2026
// COMPONENT: MonoMark renderer
// PURPOSE: Bundle local renderer modules and preserve third-party licenses.
// RELATES: worker.mjs, ReaderWebView.swift
// FLOW: Validated command -> bounded view update -> native event.

import { build } from 'esbuild';
import { mkdir, cp, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const output = path.resolve('../build/Renderer');
await mkdir(output, { recursive: true });
await build({ entryPoints: ['src/host.mjs'], bundle: true, splitting: true, format: 'esm', outdir: output,
    entryNames: 'host', chunkNames: 'chunks/[name]-[hash]', target: 'safari18', minify: true });
await build({ entryPoints: ['src/worker.mjs'], bundle: true, format: 'iife', outfile: output + '/worker.js', target: 'safari18', minify: true });
await cp('index.html', output + '/index.html');
await cp('reader.css', output + '/reader.css');
await cp('node_modules/katex/dist/katex.min.css', output + '/katex.css');
await cp('node_modules/katex/dist/fonts', output + '/fonts', { recursive: true });
await cp('node_modules/highlight.js/styles/github-dark.css', output + '/highlight-dark.css');
await cp('node_modules/highlight.js/styles/github.css', output + '/highlight-light.css');
// Ship all transitive license files alongside the offline bundle.
const lock = JSON.parse(await readFile('package-lock.json', 'utf8'));
const notices = [];
for (const name of Object.keys(lock.packages).filter(name => name.startsWith('node_modules/')))
{
    for (const file of ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'license'])
    {
        try { notices.push(`\n--- ${name} ---\n` + await readFile(path.join(name, file), 'utf8')); break; }
        catch { /* Some packages carry license metadata rather than a root license file. */ }
    }
}
await writeFile(output + '/THIRD_PARTY_LICENSES.txt', notices.join('\n'));
console.log('Offline renderer built at ' + output);
