/**
 * Build the static website from templates and site.config.json.
 * This script uses only Node.js standard-library modules.
 */

import { cp, mkdir, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

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
  contactLink: createContactLink(config.contactEmail),
  appCards: createAppCards(config.apps),
  legalDate: formatDate(config.legalEffectiveDate),
  themeBaseUrl: escapeAttribute(config.themeBaseUrl.replace(/\/$/, "")),
  siteUrl: escapeAttribute(config.siteUrl.replace(/\/$/, "")),
  companyLocation: escapeHtml(config.companyLocation),
  sourceRepositoryUrl: escapeAttribute(config.sourceRepositoryUrl),
  analyticsTag: createAnalyticsTag(config.googleAnalyticsId),
  siteFooter: createSiteFooter(config, version, buildMetadata)
};

await copyTemplates(sourceRoot, outputRoot, replacements);
await copyAppIcons(config.apps);
await validateAppPages(config.apps);

console.log(`Build info: Website ${version}+${buildMetadata.buildSha} (build ${buildMetadata.buildNumber})`);

async function copyTemplates(sourceDirectory, targetDirectory, values) {
  await mkdir(targetDirectory, { recursive: true });
  const entries = await readdir(sourceDirectory, { withFileTypes: true });

  for (const entry of entries) {
    const sourcePath = path.join(sourceDirectory, entry.name);
    const targetPath = path.join(targetDirectory, entry.name);

    if (entry.isDirectory()) {
      await copyTemplates(sourcePath, targetPath, values);
      continue;
    }

    if (isTemplateFile(entry.name)) {
      const template = await readFile(sourcePath, "utf8");
      await writeFile(targetPath, replaceTokens(template, values), "utf8");
      continue;
    }

    await cp(sourcePath, targetPath);
  }
}

async function copyAppIcons(apps) {
  for (const app of apps) {
    const sourcePath = path.resolve(webRoot, app.iconSource);
    const targetPath = path.resolve(outputRoot, app.iconOutput);
    ensureChildPath(targetPath, outputRoot, "icon output");

    const sourceInfo = await stat(sourcePath).catch(() => null);
    if (!sourceInfo?.isFile()) {
      throw new Error(`App icon does not exist: ${sourcePath}`);
    }

    await mkdir(path.dirname(targetPath), { recursive: true });
    await cp(sourcePath, targetPath);
  }
}

function createAppCards(apps) {
  return apps.map((app) => {
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
              <span class="badge text-bg-secondary">${escapeHtml(app.status)}</span>
            </div>
          </div>
          <p class="card-text">${escapeHtml(app.description)}</p>
        </div>
        <div class="card-footer app-card-actions">
          <a class="btn btn-primary btn-sm" href="/${escapeAttribute(app.pagePath)}">Learn more</a>
          <a class="btn btn-outline-primary btn-sm" href="/support/#${slugify(app.name)}">Get support</a>
          ${sourceLink}
        </div>
      </article>`;
  }).join("\n");
}

function createAnalyticsTag(measurementId) {
  const safeId = escapeAttribute(measurementId);
  return `<script async src="https://www.googletagmanager.com/gtag/js?id=${safeId}"></script>
  <script src="/js/google-analytics.js" data-measurement-id="${safeId}"></script>`;
}

function createContactLink(email) {
  const safeEmail = escapeHtml(email);
  return `<a href="mailto:${escapeAttribute(email)}">${safeEmail}</a>`;
}

function createSiteFooter(value, siteVersion, metadata) {
  const organizationName = escapeHtml(value.organizationName);
  const buildNumber = escapeAttribute(metadata.buildNumber);
  const buildSha = escapeAttribute(metadata.buildSha);
  const appLinks = value.apps.map((app) =>
    `<li><a href="/${escapeAttribute(app.pagePath)}">${escapeHtml(app.name)}</a></li>`
  ).join("\n          ");

  return `<footer class="sitefooter outcrop-sitefooter">
    <div class="sitefooter-grid sitefooter-cols-4">
      <div class="sitefooter-org" itemscope itemtype="https://schema.org/Organization">
        <p class="sitefooter-orgname">${organizationName}</p>
        <meta itemprop="name" content="${organizationName}">
        <meta itemprop="url" content="${escapeAttribute(value.siteUrl)}">
        <meta itemprop="email" content="${escapeAttribute(value.contactEmail)}">
        <p class="sitefooter-orgdesc">${escapeHtml(value.siteDescription)} ${organizationName} is registered in Washington State, United States.</p>
        <address class="sitefooter-contact">
          <p><a href="mailto:${escapeAttribute(value.contactEmail)}">${escapeHtml(value.contactEmail)}</a></p>
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

function replaceTokens(template, values) {
  return template.replace(/\{\{([A-Za-z0-9]+)\}\}/g, (match, key) => {
    if (!(key in values)) {
      throw new Error(`Unknown template token: ${match}`);
    }

    return values[key];
  });
}

function validateConfig(value) {
  const requiredStrings = [
    "organizationName",
    "siteDescription",
    "siteUrl",
    "contactEmail",
    "companyLocation",
    "dunsNumber",
    "dnbProfileUrl",
    "washingtonUbiNumber",
    "washingtonRegistrationUrl",
    "sourceRepositoryUrl",
    "themeBaseUrl",
    "googleAnalyticsId",
    "legalEffectiveDate"
  ];
  for (const key of requiredStrings) {
    if (typeof value[key] !== "string" || value[key].trim() === "") {
      throw new Error(`site.config.json requires a non-empty ${key}.`);
    }
  }

  if (!/^G-[A-Z0-9]+$/.test(value.googleAnalyticsId)) {
    throw new Error("googleAnalyticsId must be a valid Google Analytics measurement ID.");
  }

  if (!Array.isArray(value.apps) || value.apps.length === 0) {
    throw new Error("site.config.json requires at least one app.");
  }

  for (const app of value.apps) {
    for (const key of ["name", "platforms", "status", "description", "iconSource", "iconOutput", "pagePath"]) {
      if (typeof app[key] !== "string" || app[key].trim() === "") {
        throw new Error(`Each app requires a non-empty ${key}.`);
      }
    }

    if (app.pagePath.startsWith("/") || !app.pagePath.endsWith("/")) {
      throw new Error("Each app pagePath must be a relative directory that ends with a slash.");
    }
  }
}

async function validateAppPages(apps) {
  for (const app of apps) {
    const pagePath = path.resolve(outputRoot, app.pagePath, "index.html");
    ensureChildPath(pagePath, outputRoot, "app page");
    const pageInfo = await stat(pagePath).catch(() => null);
    if (!pageInfo?.isFile()) {
      throw new Error(`App page does not exist: ${app.pagePath}`);
    }
  }
}

function isTemplateFile(name) {
  return [".html", ".css", ".js", ".json", ".txt", ".xml"].includes(path.extname(name)) || name.startsWith("_");
}

function ensureChildPath(candidate, parent, label) {
  const relativePath = path.relative(parent, candidate);
  if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
    throw new Error(`The ${label} must stay inside ${parent}.`);
  }
}

async function getBuildMetadata() {
  const sourceSha = process.env.WORKERS_CI_COMMIT_SHA
    || process.env.GITHUB_SHA
    || await runGit(["rev-parse", "HEAD"]);
  const normalizedSha = sourceSha.trim().toLowerCase();

  if (!/^[0-9a-f]{40}$/.test(normalizedSha)) {
    throw new Error("The website build requires a complete Git SHA.");
  }

  const commitTime = await runGit(["show", "-s", "--format=%ct", normalizedSha]);
  const buildNumber = process.env.SITE_BUILD_NUMBER?.trim()
    || formatBuildNumber(commitTime.trim());

  if (!/^\d{14}$/.test(buildNumber)) {
    throw new Error("SITE_BUILD_NUMBER must use the YYYYMMDDHHMMSS format.");
  }

  const dirtySuffix = await hasRelevantLocalChanges() ? "-dirty" : "";
  return {
    buildNumber,
    buildSha: `${normalizedSha.slice(0, 12)}${dirtySuffix}`
  };
}

async function runGit(argumentsList) {
  const { stdout } = await runFile("git", ["-C", repositoryRoot, ...argumentsList]);
  return stdout;
}

async function hasRelevantLocalChanges() {
  if (process.env.WORKERS_CI || process.env.GITHUB_ACTIONS) {
    return false;
  }

  const status = await runGit([
    "status",
    "--porcelain",
    "--",
    "src/web",
    "src/cropprint/CropPrint/Assets.xcassets/AppIcon.appiconset"
  ]);
  return status.trim() !== "";
}

function formatBuildNumber(epochSeconds) {
  if (!/^\d+$/.test(epochSeconds)) {
    throw new Error("The Git commit time is not valid.");
  }

  const commitDate = new Date(Number(epochSeconds) * 1000);
  if (Number.isNaN(commitDate.getTime())) {
    throw new Error("The Git commit time is outside the supported date range.");
  }

  return commitDate.toISOString().replace(/\D/g, "").slice(0, 14);
}

function formatDate(dateText) {
  const date = new Date(`${dateText}T00:00:00Z`);
  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC"
  }).format(date);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function escapeAttribute(value) {
  return escapeHtml(value);
}

function slugify(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}
