// COMPONENT: check-site
// PURPOSE: Validate generated pages, local links, delivery headers, and private reporting contacts.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

// SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 45cb7c71-e0c2-4fa7-a717-a9d03c91321b
// Created: 2026
// AGENT: Validates generated website markup, local links, and private security contacts.

/**
 * Validate generated website files without external dependencies.
 */

import { readFile, readdir, stat } from "node:fs/promises";
import path from "node:path";
import { escapeHtml, escapeAttribute } from "./html.mjs";
import { validateConfig } from "./site-config.mjs";

/** Use the same validated application metadata as the template builder. */
const applicationConfig = JSON.parse(await readFile(new URL("../site.config.json", import.meta.url), "utf8"));
validateConfig(applicationConfig);

const outputRoot = path.resolve(process.argv[2] || "dist");
const htmlFiles = await findFiles(outputRoot, ".html");
const failures = [];
const analyticsId = "G-3KMGPMLH78";

if (htmlFiles.length === 0)
{
    failures.push("No HTML files were generated.");
}

for (const htmlPath of htmlFiles)
{
    const html = await readFile(htmlPath, "utf8");
    const relativePath = path.relative(outputRoot, htmlPath);

    check(!html.includes("{{"), relativePath, "contains an unresolved template token");
    check(/<html\s+lang="en"/i.test(html), relativePath, "does not declare the page language");
    check(/<meta\s+name="viewport"/i.test(html), relativePath, "does not include a viewport setting");
    check(/<main[\s>]/i.test(html), relativePath, "does not contain a main landmark");
    check(/<title>[^<]+<\/title>/i.test(html), relativePath, "does not contain a title");
    check(/data-build-number="\d{14}"/i.test(html), relativePath, "does not contain a valid website build number");
    check(/data-git-sha="[0-9a-f]{12}(?:-dirty)?"/i.test(html), relativePath, "does not contain a valid Git SHA");
    check(
        /components\/sitefooter\/sitefooter\.css/i.test(html),
        relativePath,
        "does not load the SiteFooter stylesheet",
    );
    check(/<footer\s+class="[^"]*\bsitefooter\b/i.test(html), relativePath, "does not use the SiteFooter component");
    check(
        html.includes(`https://www.googletagmanager.com/gtag/js?id=${analyticsId}`),
        relativePath,
        "does not load the approved Google Analytics tag",
    );
    check(
        html.includes(`data-measurement-id="${analyticsId}"`),
        relativePath,
        "does not configure the approved Google Analytics property",
    );
    check(
        html.includes('src="/js/google-analytics.js"'),
        relativePath,
        "does not load the local analytics configuration",
    );

    if (relativePath === "index.html")
    {
        check(
            /components\/marketinghero\/marketinghero\.css/i.test(html),
            relativePath,
            "does not load the MarketingHero stylesheet",
        );
        check(
            /<section\s+class="[^"]*\bmarketinghero\b/i.test(html),
            relativePath,
            "does not use the MarketingHero component",
        );
    }

    for (const match of html.matchAll(/<img\b[^>]*>/gi))
    {
        check(/\balt="[^"]*"/i.test(match[0]), relativePath, "contains an image without alt text");
    }

    for (const match of html.matchAll(/(?:href|src)="([^"]+)"/gi))
    {
        const resourcePath = match[1];
        if (resourcePath.startsWith("/") && !resourcePath.startsWith("//"))
        {
            await checkLocalLink(resourcePath, relativePath);
        }
    }

    check(
        !/(facebook\.net|hotjar|segment\.com|doubleclick\.net)/i.test(html),
        relativePath,
        "contains an unapproved tracking or advertising service",
    );
}

await validatePublicFiles();
await validatePublishedApplications();

if (failures.length > 0)
{
    for (const failure of failures)
    {
        console.error(`ERROR: ${failure}`);
    }
    process.exit(1);
}

console.log(`Validated ${htmlFiles.length} HTML files.`);

/** Traverses generated directories and selects pages for validation. */
async function findFiles(directory, extension)
{
    const entries = await readdir(directory, { withFileTypes: true });
    const results = [];

    for (const entry of entries)
    {
        const entryPath = path.join(directory, entry.name);
        if (entry.isDirectory())
        {
            results.push(...(await findFiles(entryPath, extension)));
        }
        else if (entry.name.endsWith(extension))
        {
            results.push(entryPath);
        }
    }

    return results;
}

/** Checks local generated assets without issuing external network requests. */
async function checkLocalLink(href, page)
{
    const cleanPath = href.split("#", 1)[0].split("?", 1)[0];
    if (!cleanPath)
    {
        return;
    }

    const relativeTarget = cleanPath.replace(/^\//, "");
    const candidates = cleanPath.endsWith("/")
        ? [path.join(outputRoot, relativeTarget, "index.html")]
        : [path.join(outputRoot, relativeTarget), path.join(outputRoot, `${relativeTarget}.html`)];

    const found = await Promise.all(
        candidates.map(async (candidate) =>
        {
            const info = await stat(candidate).catch(() => null);
            return Boolean(info);
        }),
    );

    check(found.some(Boolean), page, `links to missing local path ${href}`);
}

/** Collects a failure so one validation run reports all discovered page defects. */
function check(condition, page, message)
{
    if (!condition)
    {
        failures.push(`${page} ${message}.`);
    }
}

/** Checks privacy configuration, crawler files, security contacts, and delivery headers. */
async function validatePublicFiles()
{
    const analyticsSource = await readRequiredFile("js/google-analytics.js");
    check(
        analyticsSource.includes("allow_google_signals: false"),
        "js/google-analytics.js",
        "does not disable Google signals",
    );
    check(
        analyticsSource.includes("allow_ad_personalization_signals: false"),
        "js/google-analytics.js",
        "does not disable advertising personalization",
    );

    const robots = await readRequiredFile("robots.txt");
    check(robots.includes("User-agent: *\nAllow: /"), "robots.txt", "does not allow general crawlers");
    check(robots.includes("User-agent: GPTBot\nAllow: /"), "robots.txt", "does not explicitly allow GPTBot");
    check(
        robots.includes("Sitemap: https://outcrop.us/sitemap.xml"),
        "robots.txt",
        "does not name the canonical sitemap",
    );

    await validateSecurityContact();

    const sitemap = await readRequiredFile("sitemap.xml");
    check(sitemap.includes("https://outcrop.us/apps/cropprint/"), "sitemap.xml", "does not list the CropPrint page");

    const llms = await readRequiredFile("llms.txt");
    check(llms.includes("https://outcrop.us/apps/cropprint/"), "llms.txt", "does not describe the CropPrint page");

    const headers = await readRequiredFile("_headers");
    check(
        headers.includes("https://www.googletagmanager.com"),
        "_headers",
        "does not permit the approved analytics script",
    );
    check(headers.includes("https://*.google-analytics.com"), "_headers", "does not permit Google Analytics requests");
}

/** Requires matching canonical and alias files that use private reporting channels. */
async function validateSecurityContact()
{
    const canonicalPath = ".well-known/security.txt";
    const security = await readRequiredFile(canonicalPath);
    const alias = await readRequiredFile("security.txt");
    check(
        security.includes("Contact: https://github.com/priyavijaikalyan2007/rapid/security/advisories/new"),
        canonicalPath,
        "does not contain the private vulnerability reporting form",
    );
    check(
        security.includes("Contact: mailto:admin+security@outcrop.us"),
        canonicalPath,
        "has no private email contact",
    );
    check(!security.includes("/issues"), canonicalPath, "must not direct vulnerabilities to public issues");
    check(alias === security, "security.txt", "does not match the canonical security contact file");
    check(
        security.includes("Canonical: https://outcrop.us/.well-known/security.txt"),
        canonicalPath,
        "does not contain its canonical address",
    );
    check(
        /^Expires: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/m.test(security),
        canonicalPath,
        "does not contain a valid expiration time",
    );
}

/** Records a missing public file without hiding other validation failures. */
async function readRequiredFile(relativePath)
{
    const fullPath = path.join(outputRoot, relativePath);
    return readFile(fullPath, "utf8").catch(() =>
    {
        failures.push(`${relativePath} was not generated.`);
        return "";
    });
}

/** Require both discovery and product pages to publish the configured download and availability. */
async function validatePublishedApplications()
{
    const home = await readRequiredFile("index.html");
    for (const app of applicationConfig.apps.filter((entry) => entry.appStoreUrl))
    {
        const page = `${app.pagePath}index.html`;
        const product = await readRequiredFile(page);
        const link = `href="${escapeAttribute(app.appStoreUrl)}"`;
        const status = escapeHtml(app.status);
        check(home.includes(link), "index.html", `does not link to the ${app.name} App Store listing`);
        check(product.includes(link), page, "does not link to its configured App Store listing");
        check(home.includes(status), "index.html", `does not show the ${app.name} availability`);
        check(product.includes(status), page, "does not show its configured availability");
    }
}
