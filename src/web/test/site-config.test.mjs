// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 509829eb-36f7-419e-8562-1d5dc5f58c27
// Created: 2026
// COMPONENT: Website configuration security tests
// PURPOSE: Reject unsafe addresses and output paths before a build writes files.
// RELATES: ../scripts/site-config.mjs
// FLOW: Clone a valid configuration -> change one boundary -> verify rejection.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { validateConfig } from "../scripts/site-config.mjs";

const baseline = JSON.parse(await readFile(new URL("../site.config.json", import.meta.url), "utf8"));

test("the existing website configuration is accepted", () =>
{
    assert.doesNotThrow(() => validateConfig(structuredClone(baseline)));
});

for (const field of ["siteUrl", "themeBaseUrl", "sourceRepositoryUrl", "dnbProfileUrl", "washingtonRegistrationUrl"])
{
    test(`${field} rejects executable URL schemes`, () =>
    {
        const value = structuredClone(baseline);
        value[field] = "javascript:alert(1)";
        assert.throws(() => validateConfig(value));
    });
}

test("application source addresses reject executable URL schemes", () =>
{
    const value = structuredClone(baseline);
    value.apps[0].sourceUrl = "javascript:alert(1)";
    assert.throws(() => validateConfig(value));
});

for (const field of ["pagePath", "iconOutput"])
{
    for (const unsafePath of ["../outside/", "https://example.com/", "//example.com/", "assets/../../outside/"])
    {
        test(`${field} rejects ${unsafePath}`, () =>
        {
            const value = structuredClone(baseline);
            value.apps[0][field] = unsafePath;
            assert.throws(() => validateConfig(value));
        });
    }
}

test("external addresses cannot contain embedded credentials", () =>
{
    const value = structuredClone(baseline);
    value.themeBaseUrl = "https://user:secret@example.com";
    assert.throws(() => validateConfig(value));
});

test("an invalid legal date is rejected before templates render", () =>
{
    const value = structuredClone(baseline);
    value.legalEffectiveDate = "2026-02-31";
    assert.throws(() => validateConfig(value));
});

test("two application pages cannot overwrite the same output", () =>
{
    const value = structuredClone(baseline);
    value.apps.push(structuredClone(value.apps[0]));
    assert.throws(() => validateConfig(value));
});

for (const address of [
    "javascript:alert(1)",
    "http://apps.apple.com/us/app/cropprint/id6808373041",
    "https://user:secret@apps.apple.com/us/app/cropprint/id6808373041",
    "https://apps.apple.com.example.com/us/app/cropprint/id6808373041",
    "https://apps.apple.com/us/app/cropprint/",
])
{
    test(`App Store addresses reject ${address}`, () =>
    {
        const value = structuredClone(baseline);
        value.apps[0].appStoreUrl = address;
        assert.throws(() => validateConfig(value));
    });
}

test("an App Store address must be text", () =>
{
    const value = structuredClone(baseline);
    value.apps[0].appStoreUrl = ["https://apps.apple.com/us/app/cropprint/id6808373041"];
    assert.throws(() => validateConfig(value));
});

test("a canonical Apple app listing is accepted", () =>
{
    const value = structuredClone(baseline);
    value.apps[0].appStoreUrl = "https://apps.apple.com/us/app/cropprint/id6808373041";
    assert.doesNotThrow(() => validateConfig(value));
});
