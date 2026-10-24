<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 9fa99942-d2a7-4ede-95bf-22e411febe9e
Created: 2026
-->

<!-- AGENT: Defines the source audit scope, implementation sequence, and verification gates. -->

<!-- AGENT: Defines the complete src audit and the test gates for each change group. -->

# Source compliance audit plan

Date: 23 October 2026.
Baseline: commit 4996852. The working tree was clean, and the complete test command passed.

## Scope and file plan

Audit every file listed in [the inventory](source-audit.inventory.md).
The inventory records all 169 existing tracked files under src/ and their baseline hashes in the local audit evidence.
Keep binary assets, lockfiles, and tool-owned formats valid. Use scoped REUSE annotations where embedded comments are unsupported.
Do not alter third-party license terms or regenerate product screenshots merely to add source markers.

Split top-level Swift declarations into files named after their types.
Preserve existing target memberships and conditional platform compilation.
Move same-type extensions to Type+Concern.swift where a separate file improves ownership.
The implementation paths are recorded in the final inventory, including each renamed or split original.
The added services cover image input, bitmap allocation, resource transport and catalog policy, cancellable previews,
exclusive export publication, and preview command validation. Focused tests accompany these contracts.

Supporting records: CONVERSATION.md, CHANGELOG.md, agentknowledge/concepts.yaml, entities.yaml, decisions.yaml, history.jsonl,
specs/cropprint.status.md, website.status.md, composure.status.md, repository.status.md, and this plan and inventory.
Update the local search index after marker and path changes.

## Design and interfaces

No pattern required - simple function/class suffices.
Use small value types and injected transport only where isolation makes a security contract testable.
Preserve application entry points and native platform controls.
Keep validation and processing in services rather than views.

ResourceDownloadPolicy validates HTTPS transport, response status, cancellation, and byte limits.
ResourceCatalogPolicy validates identifiers, catalog counts, attribution metadata, license choices, and file types.
BoundedResourceDownloader.data(from:maximumBytes:) async throws returns bounded data and supports cancellation.
ImageInputLimits validates byte and pixel limits before an image decoder allocates a full raster.
Website configuration validation rejects unsafe URL schemes and paths before output files are written.
Shell helpers validate modes and archive identity before any resource creation or external operation.

## Sequence and verification gates

1. Establish tests, coverage, and the complete file inventory before refactoring.
2. Write regression tests for confirmed security defects and verify failures.
3. Fix validation, bounded I/O, cancellation, and error recovery in small groups.
4. Split Swift declarations and update Xcode target membership without changing behavior.
5. Apply formatting, useful comments, navigation headers, and license information to every applicable text file.
6. Extract large routines and view sections while preserving their inputs and behavior.
7. Review native privacy, website delivery, scripts, structured data, documents, and binary assets.
8. Run repository and component checks, negative tests, full unsigned builds, and source-format checks.
9. Record every file's outcome, unresolved verification limits, and code-coverage evidence.
10. Commit each verified logical group locally. Do not push, deploy, upload, or submit a release.

Formatting and comment changes use the existing passing tests as their baseline.
Behavior changes require a failing test that reproduces the defect.
Do not report a coverage target or UI behavior as verified without measurements or direct tests.

## Completion

The [audit report](source-audit.report.md) records final checks and limits.
The complete inventory contains no pending file reviews.

Repeatable conventions use scripts/check-source-style.sh, src/.editorconfig, src/.swiftformat, and the website ESLint configuration.
The existing build workflow now runs those checks before product builds.
