// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 7690c7aa-4f39-4b5b-9489-90f7ed45f573
// COMPONENT: Whole-document highlight recovery
// PURPOSE: Reattach unique quotes after external edits without guessing among unloaded duplicates.
import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveAnnotations } from '../src/anchor-resolution.mjs';
import { parseDocument } from '../src/parser.mjs';
const note={id:'note',anchors:[{blockID:'block-0',quote:'chosen phrase',prefix:'Before ',suffix:' after.',start:7}]};

test('external insertions resolve a quote past a reused block ID and unloaded content',async()=>{
    const {blocks}=parseDocument(Array.from({length:500},(_,i)=>`Inserted paragraph ${i}.`).join('\n\n')+'\n\nBefore chosen phrase after.');
    const result=await resolveAnnotations(blocks,[note]);
    assert.equal(result[0].anchors[0].resolvedBlockID,'block-500');
    assert.equal(note.anchors[0].blockID,'block-0');
});

test('matching context in two distant blocks stays ambiguous even when the old ID still exists',async()=>{
    const {blocks}=parseDocument('Before chosen phrase after.\n\n'+Array.from({length:300},()=> 'Other paragraph.').join('\n\n')+'\n\nBefore chosen phrase after.');
    const result=await resolveAnnotations(blocks,[note]);
    assert.equal(result[0].anchors[0].resolvedBlockID,null);
    assert.equal(result[0].anchors[0].resolution,'ambiguous');
});

test('deleted quotes and application-generated blocks cannot acquire an attachment',async()=>{
    const result=await resolveAnnotations([{blockID:'block-0',text:'Before chosen phrase after.',generated:true}],[note]);
    assert.equal(result[0].anchors[0].resolution,'missing');
});

test('legacy whitespace and unique contexts within repeated text still recover',async()=>{
    const legacy={id:'old',anchors:[{blockID:'old',quote:'chosen phrase\n',prefix:'Before ',suffix:'\n after.'}]};
    const result=await resolveAnnotations([{blockID:'new',text:'Before chosen phrase after. chosen phrase'}],[legacy]);
    assert.equal(result[0].anchors[0].resolvedBlockID,'new');
});

test('superseded resolution work cancels without returning partial records',async()=>{
    const result=await resolveAnnotations([], [note], {isCancelled:()=>true});
    assert.equal(result,null);
});

test('recovery yields and cancels a superseded batch without publishing partial anchors',async()=>{
    let cancelled=false;
    const cache=new Map();
    const work=resolveAnnotations([{blockID:'current',text:'Before chosen phrase after.'}],
        Array.from({length:20},()=>note),{cache,isCancelled:()=>cancelled});
    cancelled=true;
    assert.equal(await work,null);
    assert.equal(cache.size,1);
});

test('quote caches stay bounded and table continuation headers do not create false ambiguity',async()=>{
    const cache=new Map(Array.from({length:256},(_,i)=>[String(i),{}]));
    const blocks=[{blockID:'first',text:'HeadingBody'},
        {blockID:'continuation',text:'HeadingLast',tableContinuation:true,tableHeaderLength:7}];
    const notes=[{id:'header',anchors:[{quote:'Heading',prefix:'',suffix:''}]}];
    const result=await resolveAnnotations(blocks,notes,{cache});
    assert.equal(result[0].anchors[0].resolvedBlockID,'first');
    assert.equal(cache.size,1);
});

test('duplicate matches within one block and empty legacy anchors remain unattached',async()=>{
    const result=await resolveAnnotations([{blockID:'b',text:'SameSame'}],
        [{id:'same',anchors:[{quote:'Same',prefix:'',suffix:''},{quote:'\n',prefix:'',suffix:''}]}]);
    assert.deepEqual(result[0].anchors.map(a=>a.resolution),['ambiguous','missing']);
});
