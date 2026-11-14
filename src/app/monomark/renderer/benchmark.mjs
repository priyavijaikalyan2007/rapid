// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 86abe09d-605c-41e0-9fa0-90e86575ff06
// COMPONENT: MonoMark synthetic indexing benchmark
// PURPOSE: Record parser and search costs separately from native paint and target-device acceptance.
import { createHash } from 'node:crypto';
import { writeFile } from 'node:fs/promises';
import os from 'node:os';
import { parseDocument, findBlocks } from './src/parser.mjs';
import { windowRange } from './src/viewport.mjs';
const results = [];
for (const bytes of [1024 * 1024, 10 * 1024 * 1024])
{
    const paragraph = '# Section\n\n' + 'A local reading benchmark with Unicode 日本語, a [link](next.md), and **text**. '.repeat(8) + '\n\n';
    const source = paragraph.repeat(Math.ceil(bytes / Buffer.byteLength(paragraph))) + 'UNIQUE_END_TARGET';
    const before = process.memoryUsage();
    const result = parseDocument(source);
    const searchStart = performance.now();
    const matches = findBlocks(result.blocks, 'UNIQUE_END_TARGET');
    const searchMs = performance.now() - searchStart;
    const offsets = result.blocks.map((_, index) => index * 100);
    const range = windowRange(offsets, Math.max(0, offsets.at(-1) - 100), 800);
    results.push({ sourceBytes: Buffer.byteLength(source), sha256: createHash('sha256').update(source).digest('hex'),
        parseMs: Math.round(result.duration), blocks: result.blocks.length, searchMs: Math.round(searchMs),
        lastTargetFound: matches.length === 1, maximumRequestedBlocks: range.end - range.start,
        rssBeforeBytes: before.rss, rssAfterBytes: process.memoryUsage().rss });
}
const report = { measuredAt: new Date().toISOString(), platform: process.platform, arch: process.arch, release: os.release(),
    node: process.version, hostMemoryBytes: os.totalmem(), scope: 'Synthetic Node indexing only. Not native paint, idle CPU, or reference-device acceptance.', results };
const json = JSON.stringify(report, null, 2);
if (process.argv[2]) { await writeFile(process.argv[2], json + '\n'); }
console.log(json);
