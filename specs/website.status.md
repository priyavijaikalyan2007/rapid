<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: ec57d9ae-87d3-46d0-b9a8-69798da26464
Created: 2026
-->

<!-- AGENT: Records local website validation separately from deployment. -->

# Website status

Reviewed on 23 October 2026.

The website source and Cloudflare configuration exist under src/web.
The source includes the application catalog, CropPrint page, support, privacy, terms, and an error page.
The site uses an external theme and website-only Google Analytics, as documented in its existing README.
The native applications do not use the website's analytics configuration.

The local website build passed and validated six HTML files on 23 October 2026.
The checks cover required markup, local links, copied icons, and configured analytics markup.
These checks do not load external theme assets or verify production rendering.
No production deployment occurred during this setup task.

The owner enabled GitHub private vulnerability reporting during setup.
The GitHub API confirmed that it is enabled on 23 October 2026.
Both security.txt sources now use the private report form and the owner-provided contact address.
These source changes are local. The deployed website still needs an explicitly requested deployment.

## Source audit on 24 October 2026

The source audit completed on 24 October 2026. Website configuration and browser-state tests passed all 23 cases.
The generated site passed all six HTML-page checks. The updated development-tool lockfile reported zero audit vulnerabilities.
No deployment or production-rendering verification occurred. See the [audit report](source-audit.report.md).

## Published CropPrint listing on 24 October 2026

The source audit completed and was committed as c6799c5 before the release-status update.
The owner confirmed publication and supplied the App Store address.
The Apple listing identifies CropPrint and lists iPhone and iPad compatibility.
The home-page card and product page now show availability and the App Store download action.
The configuration is the single source for the status and address.

All 32 website tests, the six-page generated-site check, and JavaScript lint passed.
A negative generated-site fixture confirmed that a missing product download link fails validation.
These website changes remain local until an authorized push and deployment.
The update did not build or publish a new native application release.

The component deployment script now requires deploy or --dry-run explicitly. The npm deploy command passes deploy explicitly.
The repository suite passed 12 Python tests and 27 Bats tests after this guard change.
