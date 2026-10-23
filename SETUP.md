<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
File GUID: a2f3dda4-c44e-48c0-83ce-dd37e93a5eee
Created: 2026
-->

<!-- AGENT: Project-owned setup completion checklist. -->

# Project setup checklist

Setup reviewed and completed locally on 23 October 2026.
This record separates completed setup from release and deployment work.
The configurator prints generic scaffold reminders after a dry run, even when these items are complete.
Use this record and the component status files to determine actual completion.

## Files to complete

- [x] PROJECT_PROFILE.md separates CropPrint, the website, documentation, and repository tools.
- [x] configure.sh regenerated managed routing, passed its check, and produced no changes on a repeated dry run.
- [x] PROJECT.md records source locations, prerequisites, commands, ownership, and operation boundaries.
- [x] ADDITIONAL.md records local constraints and verified setup lessons.
- [x] README.md links setup, status, knowledge files, and development commands.
- [x] CONTRIBUTING.md limits contributions to maintainers, as the owner requested.
- [x] CODE_OF_CONDUCT.md records conduct rules and admin+security@outcrop.us as the private contact.
- [x] SECURITY.md records private reporting, assessment scope, and response limits.
- [x] The GitHub API confirmed that private vulnerability reporting is enabled.
- [x] LICENSE and CropPrint license statements use GPL-3.0-or-later for project-owned material.
- [x] THIRD_PARTY_NOTICES.md preserves copied instruction, dependency, and optional resource attribution.
- [x] agentknowledge contains source-backed concepts, model records, decisions, and append-only history.
- [x] specs contains the repository and application status records.
- [x] The local SQLite index builds and finds Swift source. Git ignores its database and downloaded tools.
- [x] GitHub Actions includes repository checks before the existing full build. The hosted workflow was not run during setup.

## Operation scripts

| Operation | Verification |
| --- | --- |
| build.sh | Full unsigned build passed for macOS, iOS simulator, iOS device, and the website |
| test.sh | Passed 12 Python checks, 13 Bats checks, macOS unit tests, and website validation |
| clean.sh | Existing component-owned cleanup paths reviewed. Cleanup was not executed |
| run.sh web | Routing and argument handling tested. The development server was not started |
| package.sh macos | Routing tested. The same component packager produced the ZIP during the full build |
| smoke.sh web | Generated-site validation passed for six HTML files |
| deploy.sh | Explicit argument handling tested. No deployment or Wrangler deployment preview was executed |

The ZIP integrity check passed, and the macOS executable contains arm64 and x86_64 architectures.
The development application is unsigned. This package is not a signed release artifact.
The knowledge files also passed safe YAML parsing.
The website validator rejected a temporary fixture that directed vulnerabilities to public issues.

## Work outside setup

The private GitHub reporting setting is live.
The policy files, updated security.txt sources, and license text remain local until an authorized push and deployment.
The supplied contact address was recorded. This task did not send a test email or verify mailbox delivery.
Physical-device testing, signed archives, App Store Connect state, uploads, and App Review submissions remain separate release work.
Composure remains planned. No application project or source folders were created for it.

See [the status index](specs/README.md) for ongoing work and verification limits.
