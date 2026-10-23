<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: f1561151-a253-4dbf-9bee-1c49e2242905
Created: 2026
-->

<!-- AGENT: Records user requests and response summaries for repository work. -->

# Conversation record

## 23 October 2026: Instruction and status review

### User request

> Ok. I setup various instructions in this repository. Can you read them back, summarize the instructions and let me know your role in this repository. Also, summarize the status.

The user also supplied the root instruction entry point and writing rules for this workspace.
Those rules require plain language, accurate technical terms, connected reasoning, and restrained formatting.

### Response summary

The instruction entry point routes through WORKFLOW.md, PROJECT_PROFILE.md, PROJECT.md, and ADDITIONAL.md.
The profile assigns Codex all eleven listed roles, from product and planning through implementation and operations.
Codex must use native platform themes, colors, components, and official interaction guidance.
Project facts require local processing, on-device AI, privacy, and no required proprietary external services.
The shared workflow requires planning, tests before implementation, regression checks, documentation, and local commits without a push.

The profile check passed.
Only the native-client component is enabled, and its source scope includes all of src/.
The existing website lacks a separately enabled website component.
ADDITIONAL.md and SETUP.md still contain unfinished setup work.
The root test, run, and package scripts are placeholders.
The root test command exited with status 2 and a configuration TODO.
The existing build.sh routes to component builds, but this review did not run application builds or tests.

CropPrint source, tests, packaging scripts, and App Review materials exist.
Its metadata script reported version 1.0.0, build 18, and source 3b8593a881e1-dirty before this review record.
This metadata does not prove that an archive was built or uploaded.
The website source and deployment scripts exist.
Composure contains three planning documents and no application implementation.
Its plan also references specification filenames that differ from the files present.

At review start, main matched the locally recorded origin/main at 3b8593a.
Tracked files had no changes, but the newly installed instructions and setup files were untracked.
Required agentknowledge files, specs status records, CHANGELOG.md, and this conversation record were absent.
The new root license selects GPL-3.0-or-later, while the CropPrint README states MIT.
Copied instructions retain their MIT notices.
License scope and document consistency need review before further changes rely on them.

Historical memory recorded an unfinished replacement App Store release.
That historical release status may be stale and was not verified against App Store Connect during this review.
The review changed only this conversation record and preserved the user's setup files.

## 23 October 2026: Complete repository setup

### User request

> Yes, let's finish the setup gaps using the ./configure.sh script. Agent Knowledge files are new; I started this repo bare but we can potentially reverse the agent knowledge and repo index. Walk me through anything else you may need.

### Owner answers

> Everything (past nad present) are GPL-3.0-or-later.

The owner limited code and documentation contributions to maintainers.
The owner asked how to enable GitHub private vulnerability reporting.
The response directed the owner to repository Settings, Advanced Security, and Private vulnerability reporting.
GitHub documentation: https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository.
The owner then confirmed that the feature was enabled.
The GitHub API returned enabled: true.
The owner supplied admin+security@outcrop.us as the private conduct contact.
The security policy also uses that address as an alternative to the private GitHub form.

### Changes and results

Used configure.sh with JSON answers to preview and apply separate CropPrint, website, documentation, and repository-tool scopes.
The configurator preserved the Codex role assignments and native platform design requirement.
The repeated dry run reported no changes, and the profile check passed.

Replaced root operation placeholders with explicit routing to existing component commands.
Added tests for invalid modes, extra arguments, component failures, and repository paths containing spaces.
The full root test command passed twelve Python checks, thirteen Bats checks, macOS unit tests, and website validation.
The full unsigned build passed for macOS, iOS simulator, iOS device, and the website.
The macOS ZIP passed its integrity check and contains arm64 and x86_64 code.
The development package is unsigned.
The initial sandboxed Xcode test attempt failed. The authorized retry passed.

Bootstrapped fourteen concepts, nine model records, and six decisions from existing source and explicit owner decisions.
Recorded original decision dates as unknown where only current architecture was observed.
Added application status files and a specifications index.
Copied the shared local SQLite index tools, added the project's actual source formats, and excluded local and credential directories.
The local index built and found Swift source. Its database and downloaded Bats tools are ignored by Git.

Completed the contribution, conduct, security, setup, and attribution documents.
Applied GPL-3.0-or-later to project-owned material and corrected CropPrint's local license statements and About view.
Preserved required third-party license notices.
Updated both website security contact files to the private form and owner-provided email address.
The website validator passed and rejected a temporary fixture that used public issues for vulnerability reports.
Corrected Composure specification links and kept Composure marked as planned.
Added repository checks before the existing GitHub Actions build. The hosted workflow was not executed.

The setup did not push, deploy, sign a release, upload, submit for review, or verify mailbox delivery.
The public website and existing App Store submission do not receive these local source changes until their separate publishing steps occur.
The configurator still prints generic scaffold reminders after a no-change dry run. SETUP.md records actual completion.
