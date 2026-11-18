// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: c734ae99-67a4-4ffd-870a-12f7b188aaaf
// COMPONENT: Print resource limits
// PURPOSE: Reject incomplete or excessive print jobs before mounting their DOM.
import test from 'node:test';
import assert from 'node:assert/strict';
import { printBudget } from '../src/print-budget.mjs';

test('ordinary printing accepts a complete bounded document',()=>{
    assert.equal(printBudget([{html:'<p>Readable.</p>'}]),null);
});

test('print limits report block, rendered byte, individual block, and node limits',()=>{
    assert.match(printBudget(Array.from({length:5001},()=>({html:''}))),/5,000 blocks/);
    assert.match(printBudget(Array.from({length:20},()=>({html:'文'.repeat(300000)}))),/16 MiB/);
    assert.match(printBudget([{html:'a'.repeat(1024*1024+1)}]),/1 MiB/);
    assert.match(printBudget([{html:'<b>'.repeat(100001)}]),/100,000/);
});
