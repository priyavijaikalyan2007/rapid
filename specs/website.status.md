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
