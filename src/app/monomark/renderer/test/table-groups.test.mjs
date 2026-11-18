// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: ec4c5e4f-2cc4-4bc9-b36f-dc3b209dc154
// COMPONENT: Large table rendering contracts
// PURPOSE: Bound rows per mounted group without losing copy data, source ranges, or semantic IDs.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { parseDocument } from '../src/parser.mjs';
import { selectionResult } from '../src/selection-text.mjs';
import { tableClipboard } from '../src/table-clipboard.mjs';

const rows=Array.from({length:2000},(_,index)=>`| ${index} | Value ${index} |`);
const source='# Before\n\n| Index | Value |\n|---|---|\n'+rows.join('\n')+'\n\n## After\n';

test('large tables render bounded row groups with stable IDs and full source ranges',()=>{
    const result=parseDocument(source);
    const groups=result.blocks.filter(block=>block.tableKey);
    assert.ok(groups.length>1);
    assert.equal(result.outline.filter(item=>item.kind==='table').length,1);
    assert.equal(result.blocks.at(-1).blockID,'block-2');
    const window=new JSDOM('').window;
    const widths=[];
    let total=0;
    for(const group of groups)
    {
        const root=window.document.createElement('div');root.innerHTML=group.html;
        const body=root.querySelectorAll('tbody tr');
        assert.ok(body.length<=64);
        assert.equal(group.line,2);
        assert.equal(group.endLine,2004);
        assert.ok(root.querySelector('thead'));
        widths.push(root.querySelector('colgroup').innerHTML);
        total+=body.length;
    }
    assert.equal(total,2000);
    assert.equal(new Set(widths).size,1);
    assert.equal(new Set(groups.map(block=>block.id)).size,groups.length);
    window.close();
});

test('whole-index table text includes one header and every row without group gaps',()=>{
    const result=parseDocument(source);
    const copied=selectionResult(result.blocks,{anchor:{index:0,offset:0},focus:{index:result.blocks.length-1,offset:5}},'copy');
    const expected=['Before','Index\tValue\n'+rows.map((_,index)=>`${index}\tValue ${index}`).join('\n'),'After'].join('\n\n');
    assert.equal(copied.text,expected);
});

test('large table copy rows are kept once in the worker index',()=>{
    const result=parseDocument(source);
    const table=result.tables.get(result.outline.find(item=>item.kind==='table').id);
    assert.equal(table.length,2001);
    assert.deepEqual(table.at(-1),['1999','Value 1999']);
});

test('small tables retain their existing single-block rendering',()=>{
    const result=parseDocument('| A | B |\n|---|---|\n| C | D |');
    assert.equal(result.blocks.length,1);
    assert.equal(result.blocks[0].tableKey,undefined);
});

test('excessively wide tables report their column limit instead of creating an unbounded grid',()=>{
    const source='| '+Array.from({length:1025},()=> 'Heading').join(' | ')+' |\n| '+
        Array.from({length:1025},()=> '---').join(' | ')+' |\n| '+Array.from({length:1025},()=> 'Cell').join(' | ')+' |';
    const result=parseDocument(source);
    assert.match(result.blocks[0].html,/1,024 columns/);
    assert.doesNotMatch(result.blocks[0].html,/<table/);
});

test('whole-table export rejects invalid formats and oversized encoded text atomically',()=>{
    assert.ok(tableClipboard([['日本語']], 'CSV',8).error);
    assert.ok(tableClipboard([['A']], 'constructor').error);
    assert.equal(tableClipboard([['A,B','C']], 'CSV',9).text,'"A,B",C');
});
