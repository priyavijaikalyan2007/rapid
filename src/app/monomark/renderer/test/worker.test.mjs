// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 09c07559-eaa2-4620-a1af-3bb11294dc53
// COMPONENT: Offline worker contracts
// PURPOSE: Resolve export source locations without retaining or mounting the complete source DOM.
import test from 'node:test';
import assert from 'node:assert/strict';
const messages = [];
globalThis.self = { postMessage: message => messages.push(message) };
await import('../src/worker.mjs');

test('export requests return source-stamped blocks for the referenced anchors only', async () => {
    await self.onmessage({ data: { type: 'load', source: '# Title\n\nText.\n\n## Other\n\nMore.', sourceHash: 'a'.repeat(64) } });
    await self.onmessage({ data: { type: 'export-locations', exportID: 1, ids: ['title', 'block-1'] } });
    const result = messages.at(-1);
    assert.equal(result.type, 'export-locations');
    assert.equal(result.exportID, 1);
    assert.equal(result.blocks.length, 2);
    assert.match(result.sourceHash, /^[0-9a-f]{64}$/);
    assert.equal(result.sourceHash, 'a'.repeat(64));
    assert.equal(result.blocks[0].section, 'Title');
});

test('the worker still supports bounded viewport, full search, and print requests', async () => {
    await self.onmessage({ data: { type: 'range', start: 0, end: 1, request: 4 } });
    assert.equal(messages.at(-1).blocks.length, 1);
    await self.onmessage({ data: { type: 'find', query: 'More', request: 5 } });
    assert.deepEqual(messages.at(-1).matches, [3]);
    await self.onmessage({ data: { type: 'print', start: 0 } });
    assert.equal(messages.at(-1).type, 'print-page');
});

test('selection copy and anchors include blocks outside the mounted range', async () => {
    await self.onmessage({data:{type:'load',source:'First **paragraph**.\n\nMiddle paragraph.\n\nLast paragraph.'}});
    const range = {anchor:{index:0,offset:6},focus:{index:2,offset:4}};
    await self.onmessage({data:{type:'selection',selectionID:71,purpose:'copy',range}});
    assert.equal(messages.at(-1).type,'selection-result');
    assert.equal(messages.at(-1).text,'paragraph.\n\nMiddle paragraph.\n\nLast');
    await self.onmessage({data:{type:'selection',selectionID:72,purpose:'anchors',range}});
    assert.equal(messages.at(-1).anchors.length,3);
    assert.equal(messages.at(-1).selectionID,72);
});
