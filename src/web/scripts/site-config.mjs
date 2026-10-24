// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b8ec9ef0-6f15-40f8-8110-e65b75ce6d32
// Created: 2026
// COMPONENT: Website configuration policy
// PURPOSE: Validate authored site configuration before output changes.
// RELATES: build-site.mjs
// FLOW: Configuration object -> validation -> template build.

/** Required text fields in the authored website configuration. */
const REQUIRED_FIELDS = [
    "organizationName",
    "siteDescription",
    "siteUrl",
    "companyLocation",
    "dunsNumber",
    "dnbProfileUrl",
    "washingtonUbiNumber",
    "washingtonRegistrationUrl",
    "sourceRepositoryUrl",
    "themeBaseUrl",
    "googleAnalyticsId",
    "legalEffectiveDate",
];

/** Addresses that templates use as links or external asset origins. */
const HTTPS_FIELDS = ["siteUrl", "dnbProfileUrl", "washingtonRegistrationUrl", "sourceRepositoryUrl", "themeBaseUrl"];

/** Required application-card fields. Text is escaped by the template builder. */
const APP_FIELDS = ["name", "platforms", "status", "description", "iconSource", "iconOutput", "pagePath"];

/** Validate configuration before deleting or writing generated output. */
export function validateConfig(value)
{
    requireStrings(value, REQUIRED_FIELDS, "site.config.json");
    for (const field of HTTPS_FIELDS)
    {
        validateHttpsAddress(value[field], field);
    }
    if (!/^G-[A-Z0-9]+$/.test(value.googleAnalyticsId))
    {
        throw new Error("Enter a valid Google Analytics measurement ID in site.config.json.");
    }
    validateLegalDate(value.legalEffectiveDate);
    validateApplications(value.apps);
}

/** Reject missing fields without coercing objects or arrays to strings. */
function requireStrings(value, fields, label)
{
    if (value === null || typeof value !== "object" || Array.isArray(value))
    {
        throw new Error(`The ${label} must be an object.`);
    }
    for (const field of fields)
    {
        if (typeof value[field] !== "string" || value[field].trim() === "" || value[field].length > 2000)
        {
            throw new Error(`The ${label} requires a nonempty ${field} of at most 2,000 characters.`);
        }
    }
}

/** Allow secure web links without embedded credentials or executable schemes. */
export function validateHttpsAddress(value, label)
{
    let address;
    try
    {
        address = new URL(value);
    }
    catch
    {
        throw new Error(`Enter a complete HTTPS address for ${label}.`);
    }
    if (address.protocol !== "https:" || !address.hostname || address.username || address.password)
    {
        throw new Error(`The ${label} must use HTTPS without embedded credentials.`);
    }
}

/** Require a real calendar date rather than JavaScript's automatic date normalization. */
function validateLegalDate(value)
{
    const date = new Date(`${value}T00:00:00Z`);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || Number.isNaN(date.getTime()))
    {
        throw new Error("Enter legalEffectiveDate as a valid YYYY-MM-DD date.");
    }
    if (date.toISOString().slice(0, 10) !== value)
    {
        throw new Error("The legalEffectiveDate is not a valid calendar date.");
    }
}

/** Bound the catalog and reject duplicate page or icon destinations. */
function validateApplications(apps)
{
    if (!Array.isArray(apps) || apps.length === 0 || apps.length > 100)
    {
        throw new Error("Configure between 1 and 100 application entries.");
    }
    const pages = new Set();
    const icons = new Set();
    for (const app of apps)
    {
        validateApplication(app);
        if (pages.has(app.pagePath) || icons.has(app.iconOutput))
        {
            throw new Error("Give each application a unique pagePath and iconOutput.");
        }
        pages.add(app.pagePath);
        icons.add(app.iconOutput);
    }
}

/** Validate every value that becomes a path or link in an application card. */
function validateApplication(app)
{
    requireStrings(app, APP_FIELDS, "application");
    validateOutputPath(app.pagePath, "pagePath");
    validateOutputPath(app.iconOutput, "iconOutput");
    if (!app.pagePath.endsWith("/"))
    {
        throw new Error("Each application pagePath must end with a slash.");
    }
    if (app.sourceUrl)
    {
        validateHttpsAddress(app.sourceUrl, "application sourceUrl");
    }
}

/** Keep browser paths relative and prevent traversal, URL origins, and encoded separators. */
function validateOutputPath(value, label)
{
    const segments = value.split("/");
    if (
        !/^[A-Za-z0-9._/-]+$/.test(value) ||
        value.startsWith("/") ||
        segments.includes("..") ||
        segments.includes(".") ||
        value.includes("//")
    )
    {
        throw new Error(`The ${label} must be a relative output path without traversal segments.`);
    }
}
