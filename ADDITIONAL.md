<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 117b6c64-7438-4265-857f-0c6a3e7fdf43
Created: 2026
-->

<!-- AGENT: Local constraints, command boundaries, and verified setup lessons. -->

# rapid local instructions

Keep business facts in [PROJECT.md](PROJECT.md) and current verification results in [specs/](specs/README.md).
Use [agentknowledge/](agentknowledge/README.md) to locate existing concepts, models, and recorded decisions.
Record observed designs separately from accepted decisions. Do not infer original decision dates from the bootstrap date.

## Product scope

CropPrint is implemented. Composure provides privacy onboarding, saved profile settings, memory-only Prepare mode, and speech-asset setup.
Composure live coaching remains planned. A Debug-only Mac audio check supports early capture feasibility testing.
Keep Prepare output bounded, scenario-specific, and independently validated.
Use fixed preparation phrases for labeled fallback. Preserve on-device processing and the absence of model tools.
Keep existing source paths. Do not create or move application structure during an instruction update.
Use native platform themes, colors, components, and interaction guidance for native applications.
Use on-device processing and AI. Optional licensed resource downloads do not authorize uploads of user content.
The website's existing external theme and website-only analytics remain separate from native application behavior.

## Operations

Commit and push verified changes in small logical steps as work proceeds.
The owner authorized ongoing pushes for this repository on 24 October 2026.
This instruction replaces the shared workflow's default to commit without pushing.

Use ./test.sh for repository checks, CropPrint tests, Composure core tests, and website validation.
Use ./src/composure/build.sh all after shared Composure changes to compile both application targets.
Use ./test.sh repository when the task only changes repository tooling or knowledge files.
Use Python 3.10 or later and Bats 1.12 or later for repository checks.
The configurator's generic readiness output does not inspect completion. Read SETUP.md for verified setup status.
Use BATS_BIN to select another Bats executable. Ignored local/tools/bats-core/bin/bats is also supported.
Keep the local search database and downloaded developer tools under ignored local/.
The installed index supports build, rebuild, clear, status, and search. It does not implement update.

Use ./package.sh macos for the unsigned development ZIP.
Use ./run.sh web for the website preview. Select native schemes and devices in Xcode.
Use ./smoke.sh web for local generated-site checks. This command does not inspect the deployed website.
Use ./deploy.sh --dry-run only when a deployment preview is requested.
An actual deployment requires an explicit deployment request and the deploy argument.
App Store archives, uploads, submissions, and releases use the separate gates in PUBLISHING.md.

## Ownership and licensing

Contributions are limited to maintainers until the owner changes that policy.
Project-owned material uses GPL-3.0-or-later, including existing project material.
Use the root LICENSE as the authoritative license file for copyright headers.
Preserve required third-party notices and copied instruction-library attribution.
Do not modify third-party dependency licenses to match the project license.

## Verification limits

The machine contains Xcode, but its global active developer directory points to Command Line Tools.
Existing CropPrint scripts select /Applications/Xcode.app/Contents/Developer without changing the global setting.
If the sandbox blocks Xcode test services, request the required execution permission and retry.
Do not claim that application tests failed solely because the sandbox blocked Xcode.
Do not report that device tests, signed archives, uploads, or deployments passed without direct evidence.
