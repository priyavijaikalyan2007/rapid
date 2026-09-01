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
  companyRegistration: createCompanyRegistration(config),
  appCards: createAppCards(config.apps),
  currentYear: String(new Date().getUTCFullYear()),
  legalDate: formatDate(config.legalEffectiveDate),
  siteVersion: escapeHtml(version),
  buildNumber: escapeHtml(buildMetadata.buildNumber),
  buildSha: escapeHtml(buildMetadata.buildSha),
  themeBaseUrl: escapeAttribute(config.themeBaseUrl.replace(/\/$/, "")),
  siteUrl: escapeAttribute(config.siteUrl.replace(/\/$/, "")),
  companyLocation: escapeHtml(config.companyLocation),
  sourceRepositoryUrl: escapeAttribute(config.sourceRepositoryUrl)
};

await copyTemplates(sourceRoot, outputRoot, replacements);
await copyAppIcons(config.apps);

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
          <a class="btn btn-primary btn-sm" href="/support/#${slugify(app.name)}">Get support</a>
          ${sourceLink}
        </div>
      </article>`;
  }).join("\n");
}

function createContactLink(email) {
  const safeEmail = escapeHtml(email);
  return `<a href="mailto:${escapeAttribute(email)}">${safeEmail}</a>`;
}

function createCompanyRegistration(value) {
  return `<div class="company-registration">
          <strong>${escapeHtml(value.organizationName)}</strong>
          <p>${escapeHtml(value.siteDescription)}</p>
          <p class="registration-status">${escapeHtml(value.organizationName)} is registered in Washington State, United States.</p>
          <dl class="registration-details">
            <div>
              <dt>D-U-N-S Number</dt>
              <dd><a href="${escapeAttribute(value.dnbProfileUrl)}" rel="noopener noreferrer">${escapeHtml(value.dunsNumber)}</a></dd>
            </div>
            <div>
              <dt>Washington UBI</dt>
              <dd><a href="${escapeAttribute(value.washingtonRegistrationUrl)}" rel="noopener noreferrer">${escapeHtml(value.washingtonUbiNumber)}</a></dd>
            </div>
          </dl>
          <div class="registration-links">
            <a href="${escapeAttribute(value.dnbProfileUrl)}" rel="noopener noreferrer">Dun &amp; Bradstreet business profile</a>
            <a href="${escapeAttribute(value.washingtonRegistrationUrl)}" rel="noopener noreferrer">Washington business registration</a>
          </div>
        </div>`;
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
    "legalEffectiveDate"
  ];
  for (const key of requiredStrings) {
    if (typeof value[key] !== "string" || value[key].trim() === "") {
      throw new Error(`site.config.json requires a non-empty ${key}.`);
    }
  }

  if (!Array.isArray(value.apps) || value.apps.length === 0) {
    throw new Error("site.config.json requires at least one app.");
  }

  for (const app of value.apps) {
    for (const key of ["name", "platforms", "status", "description", "iconSource", "iconOutput"]) {
      if (typeof app[key] !== "string" || app[key].trim() === "") {
        throw new Error(`Each app requires a non-empty ${key}.`);
      }
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
