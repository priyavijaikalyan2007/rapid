// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 495e4243-d810-4fcb-97c8-a165af9afba0
// COMPONENT: Renderer trust boundary tests
// PURPOSE: Reject active markup and unsafe resource addresses before DOM insertion.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { sanitizeDocument, localImageURL } from '../src/sanitizer.mjs';

test('sanitization removes active elements and handlers', () => {
    const window = new JSDOM('').window;
    const safe = sanitizeDocument(window, '<img src="x" onerror="alert(1)"><iframe src="https://bad"></iframe><script>x()</script>');
    assert.doesNotMatch(safe, /onerror|iframe|script/);
});
test('local image requests retain path and scope validation at native boundary', () => {
    assert.equal(localImageURL('../images/plot.png'), 'monomark://document/image?path=..%2Fimages%2Fplot.png');
});
test('remote and active images are blocked by default', () => {
    assert.equal(localImageURL('https://example.com/tracker.png'), null);
    assert.equal(localImageURL('javascript:alert(1)'), null);
    assert.equal(localImageURL('data:image/svg+xml,x'), null);
});

test('diagram styling survives sanitization without global style injection', async () => {
    const { sanitizeDiagram } = await import('../src/sanitizer.mjs');
    const window = new JSDOM('').window;
    const safe = sanitizeDiagram(window, '<svg id="diagram"><style>#diagram rect {fill:#234567} #diagram text {fill:#ffffff}</style><rect/><text>Visible</text><script>alert(1)</script></svg>');
    assert.match(safe, /fill:.*(?:#234567|rgb\(35, 69, 103\))/);
    assert.match(safe, /fill:.*(?:#ffffff|rgb\(255, 255, 255\))/);
    assert.doesNotMatch(safe, /<style|<script/);
});
