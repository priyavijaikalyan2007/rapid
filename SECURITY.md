<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 8f8666f2-266e-4c11-a168-763788732580
Created: 2026
-->

<!-- AGENT: Private vulnerability reporting, assessment scope, and disclosure expectations. -->

# Security policy for rapid

## Supported versions

Report security issues against the current main branch or a released application build.
Include the exact version, build number, and source Git SHA when available.
The project does not publish a guaranteed security-support period for older builds.
The maintainer will assess whether a report also applies to current source.

## Private vulnerability reporting

Use [GitHub private vulnerability reporting](https://github.com/priyavijaikalyan2007/rapid/security/advisories/new).
The owner enabled this feature, and the GitHub API confirmed it on 23 October 2026.
GitHub requires an account to submit a private report.
If you cannot use the form, email admin+security@outcrop.us.
Do not disclose vulnerabilities, secrets, or private customer content in a public issue.

Include affected versions, reproduction steps, impact, and relevant environment details.

## Scope and response

This policy covers CropPrint, the Outcrop website source, and repository build and release tooling.
Composure currently contains specifications. Report privacy or security defects in those requirements through the same channel.
Report upstream dependency defects to the dependency maintainer and explain any impact on this repository.

Outcrop Inc owns triage and assigns maintainers as needed.
The project does not promise acknowledgment, remediation, or release within a fixed period.
Maintainers use the private report to clarify impact, reproduce the issue, and coordinate a fix and disclosure.
Share only the information needed to reproduce the issue. Use synthetic data where possible.
Do not send credentials, private photos, or meeting content.
Discuss public disclosure timing and attribution with the maintainer before publication.
Maintainers will ask for your preferred credit before naming you in a public advisory.
