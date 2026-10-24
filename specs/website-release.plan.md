<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: ed116ab2-6b83-496d-89ed-dc092ba7521b
Created: 2026
-->

<!-- AGENT: Updates published CropPrint availability after the completed source-audit commit. -->

# CropPrint website release update

The source audit completed in commit c6799c5 before this separate website change.
The owner supplied the published App Store address on 24 October 2026.
Apple's listing identifies CropPrint and lists iPhone and iPad compatibility.

Keep the App Store address in the existing application configuration.
Validate HTTPS, Apple host identity, and the app identifier path before generating links.
Use that value for the home-page card and CropPrint product page.
Show the configured availability status in both locations.
Share the existing escaping functions between template generation and generated-site checks.
No pattern is required. Small functions and the existing template pipeline suffice.

The changes affect site.config.json, build-site.mjs, check-site.mjs, site-config.mjs, and the CropPrint HTML template.
Add html.mjs and focused configuration and escaping tests.
Update PROJECT.md, website status, the changelog, conversation record, and agent knowledge history.

Validate failing boundary tests before implementation. Then run website tests, the generated-site checker, and JavaScript lint.
Run repository record checks after updating navigation evidence.
Commit the verified website changes separately. Deployment requires a separate explicit deployment request.

## Completion

The home and product pages now use the configured published status and App Store address.
The App Store URL boundary tests failed before implementation and passed after the validation changes.
All 32 website tests and the generated-site and lint checks passed.
A fixture with a missing download link failed the generated-site check as expected.
No deployment occurred.

The component deployment helper also requires an explicit mode, matching ADDITIONAL.md and the existing root wrapper.
A failing command-boundary test reproduced the missing guard before the fix. No deployment command ran against Cloudflare.
