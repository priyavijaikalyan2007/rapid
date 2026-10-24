// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a4dd0eb7-22ab-4f7a-a636-77229b186cca
// Created: 2026
// COMPONENT: Browser theme tests
// PURPOSE: Keep theme selection local and tolerate blocked browser storage.
// RELATES: ../site/js/theme-init.js
// FLOW: Browser fixture -> theme initializer -> document attributes.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

const source = await readFile(new URL("../site/js/theme-init.js", import.meta.url), "utf8");

/** Execute the real initializer without starting a browser or a network request. */
function initialize(savedMode, prefersDark = false, blocked = false)
{
    const attributes = new Map();
    const context = {
        document: { documentElement: { setAttribute: (key, value) => attributes.set(key, value) } },
        window: {
            localStorage: {
                getItem: () =>
                {
                    if (blocked)
                    {
                        throw new Error("Storage unavailable");
                    }
                    return savedMode;
                },
            },
            matchMedia: () => ({ matches: prefersDark }),
        },
    };
    vm.runInNewContext(source, context);
    return attributes;
}

for (const mode of ["light", "dark"])
{
    test(`explicit ${mode} mode overrides the system preference`, () =>
    {
        assert.equal(initialize(mode, mode === "light").get("data-bs-theme"), mode);
    });
}

test("automatic mode follows the operating system", () =>
{
    assert.equal(initialize("auto", true).get("data-bs-theme"), "dark");
    assert.equal(initialize("auto", false).get("data-bs-theme"), "light");
});

test("unknown storage values fall back to automatic mode", () =>
{
    assert.equal(initialize("invalid", true).get("data-theme-mode"), "auto");
});

test("blocked browser storage does not prevent theme initialization", () =>
{
    assert.equal(initialize(null, true, true).get("data-bs-theme"), "dark");
});
