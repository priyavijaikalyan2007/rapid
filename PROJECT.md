<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 855bc0ef-2254-4e32-9d86-ceb21aa1ce2d
Created: 2026
-->

<!-- AGENT: Authoritative project facts, component boundaries, and local command contracts. -->

# rapid project facts

| Fact | Value |
| --- | --- |
| Project | rapid |
| Owner | Outcrop Inc, WA, USA. |
| Repository | https://github.com/priyavijaikalyan2007/rapid |
| Purpose | Utility applications for iOS, iPadOS and macOS users for specialized or niche capabilities. A simple static website for information about the applications and other products the company provides. |
| Intended users | All users. |
| User problem | Solves various utility problems. Completely local, using local foundational models and local on-device capabilities. |
| Expected value | These are utilities. Anyone with the specialized need these applications solve will find them useful. |
| Initial scope | Applications for cropping images in predefined ways, providing emotional intelligence and quotient feedback in meetings and more. |
| Constraints and exclusions | Should always use local foundational models for AI. Should always use on-device capabilities and APIs without requiring any proprietary external system. Open source or creative commons resources downloaded locally are allowed. Privacy and security are key. |
| Build and test commands | Root build.sh delegates to component builds. Root test.sh validates the repository and selected components. See the command table below. |
| Architecture | The CropPrint iOS, iPadOS and macOS application, the outcrop.us static website. |
| Source locations | Recorded in the component profile linked below |

Component selections are in [PROJECT_PROFILE.md](<PROJECT_PROFILE.md>).
Local refinements are in [ADDITIONAL.md](<ADDITIONAL.md>).
Licensing choices and attribution scope are recorded in the root LICENSE and THIRD_PARTY_NOTICES.md.

## Components

CropPrint is an implemented native application under src/cropprint.
Its Xcode targets support macOS 14 or later and iOS or iPadOS 17 or later.
The source version is in src/cropprint/VERSION.
The macOS scheme is CropPrint. The mobile scheme is CropPrint Mobile.

The public website is a separate static component under src/web.
Its source uses JavaScript, HTML, and CSS. Its build uses Node.js standard-library modules.
Cloudflare Workers Static Assets serves the generated dist directory.
The existing website uses an external theme and website-only Google Analytics.
Native application processing and privacy constraints do not describe website analytics.

Composure contains planning documents under src/composure.
Its normative implementation specification defines planned on-device coaching behavior.
No Composure application target exists yet.

## Development prerequisites

Native builds require macOS and a full Xcode installation with the required Apple platforms.
Existing CropPrint scripts select /Applications/Xcode.app/Contents/Developer when available.
Repository configuration and search require Python 3.10 or later with SQLite full-text search support.
Repository shell checks require Bats 1.12 or later.
Website builds require Node.js. Local setup verified Node.js 26.11.1 and Xcode 27.1.
These observed versions do not establish the oldest supported development-tool versions.
Website preview and deployment require the dependencies from src/web/package-lock.json.

## Root commands

| Command | Result |
| --- | --- |
| ./configure.sh --check | Validates profile selections and instruction routing |
| ./test.sh | Runs repository checks, macOS unit tests, and website validation |
| ./test.sh repository | Checks profile, knowledge, index helpers, and command contracts |
| ./test.sh cropprint | Runs the existing macOS unit-test command |
| ./test.sh web | Builds and validates the static website |
| ./build.sh | Tests CropPrint, packages macOS, builds mobile targets, and builds the website |
| ./build.sh web | Builds and validates only the website |
| ./package.sh macos | Creates src/cropprint/build/CropPrint-unsigned.zip |
| ./run.sh web | Starts the existing local website preview |
| ./smoke.sh web | Checks generated website files and local links |
| ./deploy.sh --dry-run | Previews the configured website deployment |
| ./deploy.sh deploy | Publishes the website after an explicit deployment request |
| ./clean.sh | Removes generated component output and documented local caches |

Native development uses src/cropprint/CropPrint.xcodeproj and an explicit scheme and device in Xcode.
Publishing, signing, uploads, App Review submission, and releases follow PUBLISHING.md.
No local build command implies permission to publish.

## Ownership and records

The owner limits code and documentation contributions to maintainers.
Project-owned software and documentation use GPL-3.0-or-later, including existing project material.
Third-party material retains its required notices.
Project license selection is also recorded in .instructions/INITIALIZATION.json.

Use [SETUP.md](SETUP.md) for setup completion and remaining owner actions.
Use [specs/README.md](specs/README.md) for component status and verified results.
Use [agentknowledge/README.md](agentknowledge/README.md) for code navigation and recorded decisions.
