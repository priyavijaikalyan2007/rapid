// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 8845afc3-9243-4dd7-b03f-cf518ae7074e
// Created: 2026
// COMPONENT: Website template escaping tests
// PURPOSE: Keep configured text and download addresses safe in HTML and quoted attributes.
// RELATES: ../scripts/html.mjs
// FLOW: Authored text -> escaping boundary -> inert template content.

import assert from "node:assert/strict";
import test from "node:test";
import { escapeHtml, escapeAttribute } from "../scripts/html.mjs";

test("markup and quotes remain text inside a template", () =>
{
    assert.equal(escapeHtml('<a title="sample">&\'</a>'), "&lt;a title=&quot;sample&quot;&gt;&amp;&#39;&lt;/a&gt;");
});

test("download address query separators remain inside the quoted attribute", () =>
{
    assert.equal(escapeAttribute("https://apps.apple.com/app/id1?a=1&b=2"), "https://apps.apple.com/app/id1?a=1&amp;b=2");
});
