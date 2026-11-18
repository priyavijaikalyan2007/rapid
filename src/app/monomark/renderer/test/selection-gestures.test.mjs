// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 0eb457b3-d68a-43b5-aedb-bec74914ec60
// COMPONENT: Virtual selection gesture regressions
// PURPOSE: Keep the original anchor during drag, Shift extension, menu selection, and edge scrolling.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { createDocumentSelection } from '../src/selection-controller.mjs';

function fixture()
{
    const window=new JSDOM('<main></main>').window;
    const root=window.document.querySelector('main');
    const sent=[],emitted=[],frames=[],scrolls=[];
    window.requestAnimationFrame=callback=>{frames.push(callback);return frames.length;};
    window.cancelAnimationFrame=()=>{};
    window.scrollBy=(_,delta)=>scrolls.push(delta);
    const blocks=Array.from({length:100},(_,index)=>({id:`block-${index}`,textLength:12}));
    const controller=createDocumentSelection(window,root,{blocks:()=>blocks,send:message=>sent.push(message),
        emit:(type,payload)=>emitted.push({type,...payload})});
    const mount=indexes=>{root.innerHTML=indexes.map(index=>
        `<section class="monomark-block" data-block="${index}" id="block-${index}"><p>Text block ${index}</p></section>`).join('');};
    mount([0,1,2]);
    return {window,root,controller,sent,emitted,mount,frames,scrolls};
}

test('releasing a drag preserves an unloaded original anchor',()=>{
    const f=fixture();
    f.root.dispatchEvent(new f.window.MouseEvent('mousedown',{bubbles:true,button:0}));
    const nodes=f.root.querySelectorAll('p');
    f.window.getSelection().setBaseAndExtent(nodes[0].firstChild,2,nodes[2].firstChild,4);
    f.controller.report();
    f.controller.beginMount();f.mount([1,2,3]);f.controller.afterMount();
    const current=f.root.querySelectorAll('p');
    f.window.getSelection().setBaseAndExtent(current[0].firstChild,0,current[2].firstChild,6);
    f.window.document.dispatchEvent(new f.window.MouseEvent('mouseup',{bubbles:true}));
    assert.equal(f.sent.at(-1).range.anchor.index,0);
    assert.equal(f.sent.at(-1).range.focus.index,3);
    const copy=new f.window.Event('copy',{bubbles:true,cancelable:true});
    f.root.dispatchEvent(copy);
    assert.equal(copy.defaultPrevented,true);
    assert.equal(f.sent.at(-1).range.anchor.index,0);
    f.window.close();
});

test('native menu Select All includes the full document index',()=>{
    const f=fixture();
    const range=f.window.document.createRange();range.selectNodeContents(f.window.document.body);
    f.window.getSelection().addRange(range);f.controller.report();
    assert.equal(f.sent.at(-1)?.range.focus.index,99);
    assert.equal(f.root.children.length,3);
    f.window.close();
});

test('Shift extension and edge drag can advance without restoring unloaded DOM',()=>{
    const f=fixture();
    const nodes=f.root.querySelectorAll('p');
    f.window.getSelection().setBaseAndExtent(nodes[0].firstChild,0,nodes[1].firstChild,4);f.controller.report();
    f.controller.beginMount();f.mount([3,4,5]);f.controller.afterMount();
    const current=f.root.querySelectorAll('p');
    f.root.dispatchEvent(new f.window.MouseEvent('mousedown',{bubbles:true,shiftKey:true,button:0}));
    f.window.document.caretRangeFromPoint=()=>{
        const range=f.window.document.createRange();range.setStart(current[2].firstChild,5);range.collapse(true);return range;};
    f.window.document.dispatchEvent(new f.window.MouseEvent('mousemove',{bubbles:true,buttons:1,clientX:100,clientY:900}));
    assert.equal(f.sent.at(-1).range.anchor.index,0);
    assert.equal(f.sent.at(-1).range.focus.index,5);
    f.frames.shift()();assert.ok(f.scrolls.at(-1)>0);
    f.window.dispatchEvent(new f.window.Event('blur'));
    assert.equal(f.root.children.length,3);
    f.window.close();
});

test('copy errors preserve clipboard ownership and stale highlight replies are ignored',()=>{
    const f=fixture();f.controller.selectAll();
    const old=f.sent.at(-1);f.controller.reset();
    f.controller.receive({purpose:'anchors',selectionID:old.selectionID,anchors:[{quote:'stale'}]});
    assert.equal(f.emitted.length,0);
    f.controller.selectAll();
    f.root.dispatchEvent(new f.window.Event('copy',{bubbles:true,cancelable:true}));
    const copy=f.sent.at(-1);
    f.controller.receive({purpose:'copy',selectionID:copy.selectionID,error:'The selection is too large to copy.'});
    assert.equal(f.emitted.at(-1).type,'status');
    f.window.close();
});
