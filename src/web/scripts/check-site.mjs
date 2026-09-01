/**
 * Validate generated website files without external dependencies.
 */

import { readFile, readdir, stat } from "node:fs/promises";
import path from "node:path";

const outputRoot = path.resolve(process.argv[2] || "dist");
const htmlFiles = await findFiles(outputRoot, ".html");
const failures = [];

if (htmlFiles.length === 0) {
  failures.push("No HTML files were generated.");
}

for (const htmlPath of htmlFiles) {
  const html = await readFile(htmlPath, "utf8");
  const relativePath = path.relative(outputRoot, htmlPath);

  check(!html.includes("{{"), relativePath, "contains an unresolved template token");
  check(/<html\s+lang="en"/i.test(html), relativePath, "does not declare the page language");
  check(/<meta\s+name="viewport"/i.test(html), relativePath, "does not include a viewport setting");
  check(/<main[\s>]/i.test(html), relativePath, "does not contain a main landmark");
  check(/<title>[^<]+<\/title>/i.test(html), relativePath, "does not contain a title");

  for (const match of html.matchAll(/<img\b[^>]*>/gi)) {
    check(/\balt="[^"]*"/i.test(match[0]), relativePath, "contains an image without alt text");
  }

  for (const match of html.matchAll(/(?:href|src)="([^"]+)"/gi)) {
    const resourcePath = match[1];
    if (resourcePath.startsWith("/") && !resourcePath.startsWith("//")) {
      await checkLocalLink(resourcePath, relativePath);
    }
  }

  check(!/(google-analytics|googletagmanager|facebook\.net|hotjar|segment\.com)/i.test(html), relativePath, "contains a known tracking service");
}

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`ERROR: ${failure}`);
  }
  process.exit(1);
}

console.log(`Validated ${htmlFiles.length} HTML files.`);

async function findFiles(directory, extension) {
  const entries = await readdir(directory, { withFileTypes: true });
  const results = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      results.push(...await findFiles(entryPath, extension));
    } else if (entry.name.endsWith(extension)) {
      results.push(entryPath);
    }
  }

  return results;
}

async function checkLocalLink(href, page) {
  const cleanPath = href.split("#", 1)[0].split("?", 1)[0];
  if (!cleanPath) {
    return;
  }

  const relativeTarget = cleanPath.replace(/^\//, "");
  const candidates = cleanPath.endsWith("/")
    ? [path.join(outputRoot, relativeTarget, "index.html")]
    : [path.join(outputRoot, relativeTarget), path.join(outputRoot, `${relativeTarget}.html`)];

  const found = await Promise.all(candidates.map(async (candidate) => {
    const info = await stat(candidate).catch(() => null);
    return Boolean(info);
  }));

  check(found.some(Boolean), page, `links to missing local path ${href}`);
}

function check(condition, page, message) {
  if (!condition) {
    failures.push(`${page} ${message}.`);
  }
}
