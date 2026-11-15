// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 527e470f-45c8-49d8-b41c-15e3054a9144
// COMPONENT: Reader color boundary tests
// PURPOSE: Verify adaptive reader colors without arbitrary CSS or author-diagram changes.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { applyPalette } from '../src/palette.mjs';

test('mode switches apply reader colors and preserve authored diagram colors', () => {
    const dom = new JSDOM('<div data-mermaid><svg><rect fill="#c0ffee"/></svg></div>');
    const palettes = {light:{heading1:'#123456',rowAlternate:'#eeeeee'},dark:{heading1:'#abcdef'}};
    applyPalette(dom.window.document, palettes, false);
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-heading1'),'#123456');
    applyPalette(dom.window.document, palettes, true);
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-heading1'),'#abcdef');
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-rowAlternate'),'');
    assert.equal(dom.window.document.querySelector('rect').getAttribute('fill'),'#c0ffee');
    dom.window.close();
});

test('only known roles and exact RGB values can enter CSS', () => {
    const dom = new JSDOM('');
    applyPalette(dom.window.document,{light:{heading1:'url(https://example.invalid)',caption:'#123456;display:none',
        equation:'#123abc',unknown:'#abcdef'}},false);
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-heading1'),'');
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-caption'),'');
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-equation'),'#123abc');
    assert.equal(dom.window.document.documentElement.style.getPropertyValue('--palette-unknown'),'');
    applyPalette(dom.window.document,null,true);
    assert.equal(dom.window.document.documentElement.style.length,0);
    dom.window.close();
});
