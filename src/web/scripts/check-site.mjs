/**
 * Validate generated website files without external dependencies.
 */

import { readFile, readdir, stat } from "node:fs/promises";
import path from "node:path";

const outputRoot = path.resolve(process.argv[2] || "dist");
const htmlFiles = await findFiles(outputRoot, ".html");
const failures = [];
const analyticsId = "G-3KMGPMLH78";

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
  check(/data-build-number="\d{14}"/i.test(html), relativePath, "does not contain a valid website build number");
  check(/data-git-sha="[0-9a-f]{12}(?:-dirty)?"/i.test(html), relativePath, "does not contain a valid Git SHA");
  check(/components\/sitefooter\/sitefooter\.css/i.test(html), relativePath, "does not load the SiteFooter stylesheet");
  check(/<footer\s+class="[^"]*\bsitefooter\b/i.test(html), relativePath, "does not use the SiteFooter component");
  check(html.includes(`https://www.googletagmanager.com/gtag/js?id=${analyticsId}`), relativePath, "does not load the approved Google Analytics tag");
  check(html.includes(`data-measurement-id="${analyticsId}"`), relativePath, "does not configure the approved Google Analytics property");
  check(html.includes('src="/js/google-analytics.js"'), relativePath, "does not load the local analytics configuration");

  if (relativePath === "index.html") {
    check(/components\/marketinghero\/marketinghero\.css/i.test(html), relativePath, "does not load the MarketingHero stylesheet");
    check(/<section\s+class="[^"]*\bmarketinghero\b/i.test(html), relativePath, "does not use the MarketingHero component");
  }

  for (const match of html.matchAll(/<img\b[^>]*>/gi)) {
    check(/\balt="[^"]*"/i.test(match[0]), relativePath, "contains an image without alt text");
  }

  for (const match of html.matchAll(/(?:href|src)="([^"]+)"/gi)) {
    const resourcePath = match[1];
    if (resourcePath.startsWith("/") && !resourcePath.startsWith("//")) {
      await checkLocalLink(resourcePath, relativePath);
    }
  }

  check(!/(facebook\.net|hotjar|segment\.com|doubleclick\.net)/i.test(html), relativePath, "contains an unapproved tracking or advertising service");
}

await validatePublicFiles();

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

async function validatePublicFiles() {
  const analyticsSource = await readRequiredFile("js/google-analytics.js");
  check(analyticsSource.includes("allow_google_signals: false"), "js/google-analytics.js", "does not disable Google signals");
  check(analyticsSource.includes("allow_ad_personalization_signals: false"), "js/google-analytics.js", "does not disable advertising personalization");

  const robots = await readRequiredFile("robots.txt");
  check(robots.includes("User-agent: *\nAllow: /"), "robots.txt", "does not allow general crawlers");
  check(robots.includes("User-agent: GPTBot\nAllow: /"), "robots.txt", "does not explicitly allow GPTBot");
  check(robots.includes("Sitemap: https://outcrop.us/sitemap.xml"), "robots.txt", "does not name the canonical sitemap");

  const security = await readRequiredFile(".well-known/security.txt");
  check(security.includes("Contact: https://github.com/priyavijaikalyan2007/rapid/issues/new/choose"), ".well-known/security.txt", "does not contain the security contact");
  check(security.includes("Canonical: https://outcrop.us/.well-known/security.txt"), ".well-known/security.txt", "does not contain its canonical address");
  check(/^Expires: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/m.test(security), ".well-known/security.txt", "does not contain a valid expiration time");

  const sitemap = await readRequiredFile("sitemap.xml");
  check(sitemap.includes("https://outcrop.us/apps/cropprint/"), "sitemap.xml", "does not list the CropPrint page");

  const llms = await readRequiredFile("llms.txt");
  check(llms.includes("https://outcrop.us/apps/cropprint/"), "llms.txt", "does not describe the CropPrint page");

  const headers = await readRequiredFile("_headers");
  check(headers.includes("https://www.googletagmanager.com"), "_headers", "does not permit the approved analytics script");
  check(headers.includes("https://*.google-analytics.com"), "_headers", "does not permit Google Analytics requests");
}

async function readRequiredFile(relativePath) {
  const fullPath = path.join(outputRoot, relativePath);
  return readFile(fullPath, "utf8").catch(() => {
    failures.push(`${relativePath} was not generated.`);
    return "";
  });
}
