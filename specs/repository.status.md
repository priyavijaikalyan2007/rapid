<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 8daa69ce-9823-44f6-aaeb-3875d3ab2f54
Created: 2026
-->

<!-- AGENT: Current repository setup, verification evidence, and operational boundaries. -->

# Repository status

Updated on 23 October 2026.

The local setup is complete. configure.sh corrected the profile and managed instruction routing.
Enabled components are CropPrint, the public website, documentation, and repository tools.
Composure documents remain in the documentation component until implementation begins.
Codex retains all configured roles and the native platform design requirement.

The knowledge bootstrap contains fourteen concepts, nine model records, and six decision records.
The records distinguish accepted constraints, observed architecture, and planned behavior.
Source anchors exist, and the YAML representation and append-only history passed validation.
The ignored local SQLite index builds successfully and finds Swift application code.
The source index can be regenerated through scripts/repo-index.py.

## Verification

- configure.sh --check passed. A repeated dry run reported no changes.
- test.sh passed twelve Python checks, thirteen Bats checks, macOS unit tests, and website validation.
- build.sh passed the macOS package, iOS simulator, iOS device, and website build steps.
- The macOS ZIP passed its integrity check and contains a universal arm64 and x86_64 executable.
- The package is unsigned, as required by the development packaging command.
- smoke.sh web validated six HTML files and their local links.
- The website validator rejected a fixture containing a public issue address for vulnerability reports.
- The GitHub API confirmed that private vulnerability reporting is enabled.

The initial sandboxed Xcode attempt failed because test services were blocked.
The authorized retry and later full validations passed.
The root command contracts also test invalid modes, extra arguments, failures, and paths containing spaces.
GitHub Actions now includes repository checks before the existing build.
The hosted workflow has not run against these changes.

The copied instruction library retains its upstream formatting, including Markdown line breaks.
Git reports whitespace warnings in those copied guides. Project-owned changes pass a separate whitespace check.
Outcrop owns any upstream formatting cleanup during the next shared-library update.

## Owner decisions

All project-owned material uses GPL-3.0-or-later, including existing project material.
Required third-party notices remain intact.
Contributions are limited to maintainers.
GitHub private vulnerability reporting handles security reports, with admin+security@outcrop.us as an email alternative.
Conduct reports use the same email address.

## Operational boundaries

No push, production deployment, App Store upload, submission, or release occurred during setup.
The new website contact files and project policies need an authorized push and deployment before public users receive those source changes.
Mailbox delivery, physical-device flows, signed archives, and live App Store status were not verified.
Local preview and deployment commands passed routing checks but were not started against their external services.
The existing cleanup scripts were reviewed without deleting local caches.

Read [SETUP.md](../SETUP.md) for the completion record and [the status index](README.md) for component-specific work.

## Source audit on 24 October 2026

The source audit completed on 24 October 2026 and recorded every original and added source file.
The knowledge graph now contains 20 concepts, 12 model records, and ten decision records.
The root test command now includes component shell-boundary tests. All 12 Python and 26 Bats checks passed.
See the [audit report](source-audit.report.md) and [inventory](source-audit.inventory.md) for complete evidence.
No source changes were pushed or deployed.

Checked-in editor and formatter rules now support repeatable source checks.
The build workflow runs those checks before product builds. The hosted workflow still awaits an authorized push.
