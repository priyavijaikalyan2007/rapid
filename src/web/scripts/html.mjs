// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: af6b3327-63bf-4e2b-8e3c-a9a5153a6d1c
// Created: 2026
// COMPONENT: Website HTML escaping
// PURPOSE: Keep configured text and download addresses inert in generated markup.
// RELATES: build-site.mjs, check-site.mjs, ../test/html.test.mjs
// FLOW: Validated configuration -> context-safe text -> generated HTML.

/** Escape markup delimiters before inserting authored values into HTML text. */
export function escapeHtml(value)
{
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
}

/** Apply the same entity policy to a value inside a quoted HTML attribute. */
export function escapeAttribute(value)
{
    return escapeHtml(value);
}
