// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7546be72-42ab-4b61-a7ba-afae181f80fb
// Created: 2026
// COMPONENT: Monoleaf publication checks
// PURPOSE: Publish a discoverable product guide without claiming unreleased downloads.
// RELATES: ../site.config.json, ../site/apps/monoleaf/index.html
// FLOW: Real static build -> generated product and discovery pages -> release boundary checks.

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const runFile = promisify(execFile);
const webRoot = new URL("../", import.meta.url);
await runFile(process.execPath, [fileURLToPath(new URL("scripts/build-site.mjs", webRoot))]);
const home = await readFile(new URL("dist/index.html", webRoot), "utf8");

/** Read the actual output so missing templates or unresolved build assets fail publication. */
async function readOutput(relativePath)
{
    return readFile(new URL(`dist/${relativePath}`, webRoot), "utf8");
}

test("the catalog exposes Monoleaf as a Mac app awaiting review without a download action", () =>
{
    const card = home.match(/<article\b[\s\S]*?<\/article>/g)?.find((value) => value.includes(">Monoleaf<"));
    assert.ok(card, "Monoleaf must have a visible catalog card");
    assert.match(card, /href="\/apps\/monoleaf\/"/);
    assert.match(card, /App Store review pending/);
    assert.doesNotMatch(card, /apps\.apple\.com|Download on|Available on|iPhone|iPad/);
});

test("the product page describes the Mac release without publishing a premature download", async () =>
{
    const product = await readOutput("apps/monoleaf/index.html");
    assert.match(product, /<title>Monoleaf[^<]*<\/title>/);
    assert.match(product, /App Store review pending/);
    assert.match(product, /itemprop="operatingSystem" content="macOS 15 or later"/);
    assert.doesNotMatch(product, /apps\.apple\.com|itemprop="downloadUrl"|\.dmg["?]|\.pkg["?]/);
});

test("Monoleaf appears in crawler discovery and shared navigation", async () =>
{
    for (const relativePath of ["sitemap.xml", "llms.txt"])
    {
        assert.match(await readOutput(relativePath), /https:\/\/outcrop\.us\/apps\/monoleaf\//);
    }
    assert.match(await readOutput("support/index.html"), /id="monoleaf"/);
    assert.match(await readOutput("privacy/index.html"), /href="\/apps\/monoleaf\/"/);
});

test("all four public example screenshots reach the product page as real PNG assets", async () =>
{
    const product = await readOutput("apps/monoleaf/index.html");
    for (const name of ["01-reader", "02-rich-dark", "03-comments", "04-notes"])
    {
        const imagePath = `assets/apps/monoleaf/${name}.png`;
        assert.ok(product.includes(`href="/${imagePath}"`), "Visitors can open the full screenshot");
        assert.ok(product.includes(`src="/${imagePath}"`), "Screenshots must appear in the guide");
        const image = await readFile(new URL(`dist/${imagePath}`, webRoot));
        assert.equal(image.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
    }
});
