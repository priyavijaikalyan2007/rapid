<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 7dd86955-1f1d-49fa-8584-651fe26db366
Created: 2026
-->

<!-- AGENT: Separates project licensing from copied tools and externally supplied resources. -->

# Third-party notices

The copied coding-agent instruction library and repository tooling originate from:
https://github.com/priyavijaikalyan2007/instructions

Copyright (c) 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
Copyright (c) 2026 Outcrop Inc

These copied materials retain the MIT license in instructions/LICENSE.
Their existing file notices remain applicable, including the copied agent entries, guides, templates, and scripts.
The license texts under LICENSES/ and instructions/templates/repository/licenses/ retain their own notices.
All project-owned material follows GPL-3.0-or-later under the root LICENSE.

The repository-index scripts were copied from that same instruction library.
They retain their upstream MIT notices. Project-specific index changes are part of this GPL-licensed repository.

The website uses external theme assets, Bootstrap, Bootstrap Icons, and Google Fonts.
See [the website notices](src/web/THIRD_PARTY_NOTICES.md) for their attribution and license terms.
Development dependencies retain the license records in src/web/package-lock.json and their installed package notices.
Those dependency licenses do not change to GPL merely because the project uses GPL.

CropPrint's optional remote fonts and frames carry per-resource creator, source, and license fields.
See [the catalog model](src/cropprint/CropPrint/Models/RemoteResource.swift) and the in-app Attributions view.
These resources retain their own licenses and attribution requirements.

The local setup used Bats 1.12.0 under ignored local/tools/.
Bats retains its upstream license and is a developer tool, not an application resource or tracked project dependency.
