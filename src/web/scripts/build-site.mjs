// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 40982967-1158-49e5-839f-d6ac643742e0
// Created: 2026
// COMPONENT: build-site
// PURPOSE: Build escaped static templates from validated project configuration.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

/**
 * Build the static website from templates and site.config.json.
 * This script uses only Node.js standard-library modules.
 */

import { cp, mkdir, readFile, readdir, realpath, rm, stat, writeFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

import { validateConfig } from "./site-config.mjs";
import { escapeHtml, escapeAttribute } from "./html.mjs";

const runFile = promisify(execFile);

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(webRoot, "../..");
const sourceRoot = path.join(webRoot, "site");
const outputRoot = path.join(webRoot, "dist");

const config = JSON.parse(await readFile(path.join(webRoot, "site.config.json"), "utf8"));
const version = (await readFile(path.join(webRoot, "VERSION"), "utf8")).trim();
const buildMetadata = await getBuildMetadata();

validateConfig(config);

await rm(outputRoot, { recursive: true, force: true });
await mkdir(outputRoot, { recursive: true });

const replacements = {
    organizationName: escapeHtml(config.organizationName),
    siteDescription: escapeHtml(config.siteDescription),
    appCards: createAppCards(config.apps),
    legalDate: formatDate(config.legalEffectiveDate),
    themeBaseUrl: escapeAttribute(config.themeBaseUrl.replace(/\/$/, "")),
    siteUrl: escapeAttribute(config.siteUrl.replace(/\/$/, "")),
    companyLocation: escapeHtml(config.companyLocation),
    sourceRepositoryUrl: escapeAttribute(config.sourceRepositoryUrl),
    analyticsTag: createAnalyticsTag(config.googleAnalyticsId),
    siteFooter: createSiteFooter(config, version, buildMetadata),
};

await copyTemplates(sourceRoot, outputRoot, replacements);
await copyAppIcons(config.apps);
await validateAppPages(config.apps);

console.log(`Build info: Website ${version}+${buildMetadata.buildSha} (build ${buildMetadata.buildNumber})`);

/** Copies authored pages and replaces only known escaped template values. */
async function copyTemplates(sourceDirectory, targetDirectory, values)
{
    await mkdir(targetDirectory, { recursive: true });
    const entries = await readdir(sourceDirectory, { withFileTypes: true });

    for (const entry of entries)
    {
        const sourcePath = path.join(sourceDirectory, entry.name);
        const targetPath = path.join(targetDirectory, entry.name);

        if (entry.isDirectory())
        {
            await copyTemplates(sourcePath, targetPath, values);
            continue;
        }

        if (isTemplateFile(entry.name))
        {
            const template = await readFile(sourcePath, "utf8");
            await writeFile(targetPath, replaceTokens(template, valuesForTemplate(sourcePath, values)), "utf8");
            continue;
        }

        await cp(sourcePath, targetPath);
    }
}

/** Add only the matching application metadata to its product page template. */
function valuesForTemplate(sourcePath, values)
{
    const app = config.apps.find((entry) =>
        path.resolve(sourceRoot, entry.pagePath, "index.html") === sourcePath);
    if (!app)
    {
        return values;
    }
    return {
        ...values,
        appStatus: escapeHtml(app.status),
        ...(app.appStoreUrl ? { appStoreUrl: escapeAttribute(app.appStoreUrl) } : {}),
    };
}

/** Resolves image symlinks and confines copied assets to the repository and output roots. */
async function copyAppIcons(apps)
{
    for (const app of apps)
    {
        const sourcePath = await realpath(path.resolve(webRoot, app.iconSource));
        ensureChildPath(sourcePath, await realpath(repositoryRoot), "icon source");
        const targetPath = path.resolve(outputRoot, app.iconOutput);
        ensureChildPath(targetPath, outputRoot, "icon output");

        const sourceInfo = await stat(sourcePath).catch(() => null);
        if (!sourceInfo?.isFile())
        {
            throw new Error(`App icon does not exist: ${sourcePath}`);
        }

        await mkdir(path.dirname(targetPath), { recursive: true });
        await cp(sourcePath, targetPath);
    }
}

/** Builds application cards from validated paths and escaped text. */
function createAppCards(apps)
{
    return apps
        .map((app) =>
        {
            const storeLink = createAppStoreLink(app);
            const detailStyle = app.appStoreUrl ? "btn-outline-primary" : "btn-primary";
            const statusStyle = app.appStoreUrl ? "text-bg-success" : "text-bg-secondary";
            const sourceLink = app.sourceUrl
                ? `<a class="btn btn-outline-primary btn-sm" href="${escapeAttribute(app.sourceUrl)}" rel="noopener noreferrer">Source code</a>`
                : "";

            return `
      <article class="card app-card h-100">
        <div class="card-body">
          <div class="app-card-heading">
            <img class="app-icon" src="/${escapeAttribute(app.iconOutput)}" alt="${escapeAttribute(app.name)} app icon" width="96" height="96">
            <div>
              <p class="eyebrow">${escapeHtml(app.platforms)}</p>
              <h3 class="card-title h4">${escapeHtml(app.name)}</h3>
              <span class="badge ${statusStyle}">${escapeHtml(app.status)}</span>
            </div>
          </div>
          <p class="card-text">${escapeHtml(app.description)}</p>
        </div>
        <div class="card-footer app-card-actions">
          ${storeLink}
          <a class="btn ${detailStyle} btn-sm" href="/${escapeAttribute(app.pagePath)}">Learn more</a>
          <a class="btn btn-outline-primary btn-sm" href="/support/#${slugify(app.name)}">Get support</a>
          ${sourceLink}
        </div>
      </article>`;
        })
        .join("\n");
}

/** Build the explicit Apple download action only when an application has a validated listing. */
function createAppStoreLink(app)
{
    if (!app.appStoreUrl)
    {
        return "";
    }
    return `<a class="btn btn-primary btn-sm" href="${escapeAttribute(app.appStoreUrl)}"
      rel="noopener noreferrer">Download on the App Store</a>`;
}

/** Loads the configured website analytics property and its local privacy settings. */
function createAnalyticsTag(measurementId)
{
    const safeId = escapeAttribute(measurementId);
    return `<script async src="https://www.googletagmanager.com/gtag/js?id=${safeId}"></script>
  <script src="/js/google-analytics.js" data-measurement-id="${safeId}"></script>`;
}

/** Builds the shared legal, attribution, and build-information footer. */
function createSiteFooter(value, siteVersion, metadata)
{
    const organizationName = escapeHtml(value.organizationName);
    const buildNumber = escapeAttribute(metadata.buildNumber);
    const buildSha = escapeAttribute(metadata.buildSha);
    const appLinks = value.apps
        .map((app) => `<li><a href="/${escapeAttribute(app.pagePath)}">${escapeHtml(app.name)}</a></li>`)
        .join("\n          ");

    return `<footer class="sitefooter outcrop-sitefooter">
    <div class="sitefooter-grid sitefooter-cols-4">
      <div class="sitefooter-org" itemscope itemtype="https://schema.org/Organization">
        <p class="sitefooter-orgname">${organizationName}</p>
        <meta itemprop="name" content="${organizationName}">
        <meta itemprop="url" content="${escapeAttribute(value.siteUrl)}">
        <p class="sitefooter-orgdesc">${escapeHtml(value.siteDescription)} ${organizationName} is registered in Washington State, United States.</p>
        <address class="sitefooter-contact">
          <p>${escapeHtml(value.companyLocation)}</p>
        </address>
      </div>
      <nav class="sitefooter-group" aria-labelledby="footer-applications">
        <h2 class="sitefooter-grouptitle" id="footer-applications">Applications</h2>
        <ul class="sitefooter-links">
          ${appLinks}
        </ul>
      </nav>
      <nav class="sitefooter-group" aria-labelledby="footer-company">
        <h2 class="sitefooter-grouptitle" id="footer-company">Company</h2>
        <ul class="sitefooter-links">
          <li><a href="/">Home</a></li>
          <li><a href="/#apps">App catalog</a></li>
          <li><a href="/support/">Support</a></li>
          <li><a href="${escapeAttribute(value.sourceRepositoryUrl)}" rel="noopener noreferrer">Source code</a></li>
        </ul>
      </nav>
      <nav class="sitefooter-group" aria-labelledby="footer-registration">
        <h2 class="sitefooter-grouptitle" id="footer-registration">Business registration</h2>
        <ul class="sitefooter-links">
          <li><a href="${escapeAttribute(value.dnbProfileUrl)}" rel="noopener noreferrer">D-U-N-S ${escapeHtml(value.dunsNumber)}</a></li>
          <li><a href="${escapeAttribute(value.washingtonRegistrationUrl)}" rel="noopener noreferrer">Washington UBI ${escapeHtml(value.washingtonUbiNumber)}</a></li>
        </ul>
      </nav>
    </div>
    <div class="sitefooter-legal">
      <p class="sitefooter-copyright">© ${new Date().getUTCFullYear()} ${organizationName}</p>
      <ul class="sitefooter-legallinks">
        <li><a href="/privacy/">Privacy Policy</a></li>
        <li><a href="/terms/">Terms and Conditions</a></li>
      </ul>
      <p class="sitefooter-build" data-build-number="${buildNumber}" data-git-sha="${buildSha}">Site ${escapeHtml(siteVersion)} · Build ${buildNumber} · Git ${buildSha}</p>
    </div>
  </footer>`;
}

/** Rejects unknown tokens instead of publishing unresolved template placeholders. */
function replaceTokens(template, values)
{
    return template.replace(/\{\{([A-Za-z0-9]+)\}\}/g, (match, key) =>
    {
        if (!(key in values))
        {
            throw new Error(`Unknown template token: ${match}`);
        }

        return values[key];
    });
}

/** Confirms that each configured application has a generated local page. */
async function validateAppPages(apps)
{
    for (const app of apps)
    {
        const pagePath = path.resolve(outputRoot, app.pagePath, "index.html");
        ensureChildPath(pagePath, outputRoot, "app page");
        const pageInfo = await stat(pagePath).catch(() => null);
        if (!pageInfo?.isFile())
        {
            throw new Error(`App page does not exist: ${app.pagePath}`);
        }
    }
}

/** Selects text formats whose authored placeholders require expansion. */
function isTemplateFile(name)
{
    return [".html", ".css", ".js", ".json", ".txt", ".xml"].includes(path.extname(name)) || name.startsWith("_");
}

/** Rejects paths that escape the allowed source or output directory. */
function ensureChildPath(candidate, parent, label)
{
    const relativePath = path.relative(parent, candidate);
    if (relativePath.startsWith("..") || path.isAbsolute(relativePath))
    {
        throw new Error(`The ${label} must stay inside ${parent}.`);
    }
}

/** Derives visible version provenance from validated CI values or the local Git commit. */
async function getBuildMetadata()
{
    const sourceSha =
        process.env.WORKERS_CI_COMMIT_SHA || process.env.GITHUB_SHA || (await runGit(["rev-parse", "HEAD"]));
    const normalizedSha = sourceSha.trim().toLowerCase();

    if (!/^[0-9a-f]{40}$/.test(normalizedSha))
    {
        throw new Error("The website build requires a complete Git SHA.");
    }

    const commitTime = await runGit(["show", "-s", "--format=%ct", normalizedSha]);
    const buildNumber = process.env.SITE_BUILD_NUMBER?.trim() || formatBuildNumber(commitTime.trim());

    if (!/^\d{14}$/.test(buildNumber))
    {
        throw new Error("SITE_BUILD_NUMBER must use the YYYYMMDDHHMMSS format.");
    }

    const dirtySuffix = (await hasRelevantLocalChanges()) ? "-dirty" : "";
    return {
        buildNumber,
        buildSha: `${normalizedSha.slice(0, 12)}${dirtySuffix}`,
    };
}

/** Runs Git without a shell and captures its result inside this repository. */
async function runGit(argumentsList)
{
    const { stdout } = await runFile("git", ["-C", repositoryRoot, ...argumentsList]);
    return stdout;
}

/** Marks local builds dirty when website or shared icon sources differ from Git. */
async function hasRelevantLocalChanges()
{
    if (process.env.WORKERS_CI || process.env.GITHUB_ACTIONS)
    {
        return false;
    }

    const status = await runGit([
        "status",
        "--porcelain",
        "--",
        "src/web",
        "src/cropprint/CropPrint/Assets.xcassets/AppIcon.appiconset",
    ]);
    return status.trim() !== "";
}

/** Converts a validated commit timestamp to a UTC build identifier. */
function formatBuildNumber(epochSeconds)
{
    if (!/^\d+$/.test(epochSeconds))
    {
        throw new Error("The Git commit time is not valid.");
    }

    const commitDate = new Date(Number(epochSeconds) * 1000);
    if (Number.isNaN(commitDate.getTime()))
    {
        throw new Error("The Git commit time is outside the supported date range.");
    }

    return commitDate.toISOString().replace(/\D/g, "").slice(0, 14);
}

/** Formats the validated legal effective date without local time-zone shifts. */
function formatDate(dateText)
{
    const date = new Date(`${dateText}T00:00:00Z`);
    return new Intl.DateTimeFormat("en-US", {
        day: "numeric",
        month: "long",
        year: "numeric",
        timeZone: "UTC",
    }).format(date);
}

/** Produces stable local support anchors from application names. */
function slugify(value)
{
    return String(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");
}
