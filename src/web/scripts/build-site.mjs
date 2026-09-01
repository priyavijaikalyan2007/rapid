/**
 * Build the static website from templates and site.config.json.
 * This script uses only Node.js standard-library modules.
 */

import { cp, mkdir, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(webRoot, "../..");
const sourceRoot = path.join(webRoot, "site");
const outputRoot = path.join(webRoot, "dist");

const config = JSON.parse(await readFile(path.join(webRoot, "site.config.json"), "utf8"));
const version = (await readFile(path.join(webRoot, "VERSION"), "utf8")).trim();
const buildSha = process.env.GITHUB_SHA?.slice(0, 12) || await getGitSha();

validateConfig(config);

await rm(outputRoot, { recursive: true, force: true });
await mkdir(outputRoot, { recursive: true });

const replacements = {
  organizationName: escapeHtml(config.organizationName),
  siteDescription: escapeHtml(config.siteDescription),
  contactLink: createContactLink(config.contactEmail),
  appCards: createAppCards(config.apps),
  currentYear: String(new Date().getUTCFullYear()),
  legalDate: formatDate(config.legalEffectiveDate),
  siteVersion: escapeHtml(version),
  buildSha: escapeHtml(buildSha),
  themeBaseUrl: escapeAttribute(config.themeBaseUrl.replace(/\/$/, "")),
  siteUrl: escapeAttribute(config.siteUrl.replace(/\/$/, "")),
  companyLocation: escapeHtml(config.companyLocation),
  sourceRepositoryUrl: escapeAttribute(config.sourceRepositoryUrl)
};

await copyTemplates(sourceRoot, outputRoot, replacements);
await copyAppIcons(config.apps);

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

function replaceTokens(template, values) {
  return template.replace(/\{\{([A-Za-z0-9]+)\}\}/g, (match, key) => {
    if (!(key in values)) {
      throw new Error(`Unknown template token: ${match}`);
    }

    return values[key];
  });
}

function validateConfig(value) {
  const requiredStrings = ["organizationName", "siteDescription", "siteUrl", "contactEmail", "companyLocation", "sourceRepositoryUrl", "themeBaseUrl", "legalEffectiveDate"];
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

async function getGitSha() {
  const gitHead = await readFile(path.join(repositoryRoot, ".git", "HEAD"), "utf8").catch(() => "");
  const head = gitHead.trim();

  if (!head) {
    return "unavailable";
  }

  if (!head.startsWith("ref: ")) {
    return head.slice(0, 12);
  }

  const reference = head.slice(5);
  const referenceValue = await readFile(path.join(repositoryRoot, ".git", reference), "utf8").catch(() => "");
  return referenceValue.trim().slice(0, 12) || "unavailable";
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
