<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 0f112527-fddf-44af-9ae1-8cc664abb242
Created: 2026
-->

<!-- AGENT: Monoleaf website publication plan and verification boundaries. -->

# Monoleaf website update — 23 November 2026

The owner requested: "great. in the meanwhile, update the website."
This request authorizes updating the public website while Mac App Review is pending.

Add a catalog card and product guide at /apps/monoleaf/. Publish the existing icon and four public example screenshots.
Explain navigation, rich Markdown, reading settings, local annotations, notes and explicit export choices.
Show macOS App Store review as pending. Identify iPhone and iPad as planned.
Do not publish a store download link or a direct app download before those releases exist.

## Files and design

Update src/web/site/support/index.html for current and historical support anchors.
Update src/web/site.config.json, src/web/site/css/site.css, src/web/site/sitemap.xml and src/web/site/llms.txt.
Add src/web/site/apps/monoleaf/index.html and src/web/site/assets/apps/monoleaf/*.png.
Add src/web/test/monoleaf-publication.test.mjs. Update src/web/README.md.
Record evidence in specs/monoleaf.website-deployment.json, specs/website.status.md and specs/monomark.status.md.
Update CHANGELOG.md, CONVERSATION.md, agentknowledge/history.jsonl and specs/monomark.issues.json.

No pattern required. Existing validated catalog data, escaped templates and static HTML/CSS suffice.
No public interface or build architecture changes are needed. The catalog owns app status.
Keep layout in the static template and website styles. Reuse the theme, navigation, footer and support/privacy pages.
Use screenshots of public synthetic documents only. Preserve the unrelated owner-edited Xcode UI-test scheme.

## Verification and publication

1. Establish the existing website baseline.
2. Add failing publication checks for discovery, status, platform claims, local assets and crawler discovery.
3. Add the content and assets.
4. Run website tests, lint, generated-site validation and repository checks.
5. Inspect desktop/mobile and light/dark rendering using an isolated browser if available.
6. Commit and push the verified source.
7. Publish through the existing explicit deploy command.
8. Verify the public home/product/support/privacy pages and new assets.
9. Record deployment evidence and update the release issues.

The baseline passes all 32 website tests and six generated HTML pages.
Wrangler 4.152.0 is installed. Its default version-check logger cannot write outside the sandbox.
The existing deployment wrapper already redirects Wrangler logs into the component directory.

All four publication regressions failed before implementation. The first implementation exposed the old support anchor.
The replacement preserves the historical anchor and adds the current product guide.

Publication completed from 3b223d0. All 36 website tests, seven-page validation, lint and repository checks pass.
Desktop/mobile light/dark captures were inspected. Thirteen live HTTPS/content checks pass.
Cloudflare version: 5713db86-4332-4d28-bd14-0cfe1e5f7e37. Website task #76 is closed.
See monoleaf.website-deployment.json for the verified public assets and source revision.
