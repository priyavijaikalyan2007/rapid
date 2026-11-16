<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: f0033447-e278-4543-af45-0ea123c2d691 -->
<!-- COMPONENT: MonoMark review fixes -->

# Reader review fixes, 15 November 2026

The owner reported nine items after reviewing a local specification. Use synthetic fixtures in tracked evidence.
Do not modify or publish the source document or local annotations.

## Plan

No pattern required - simple function/class suffices. Keep processing in renderer functions and Core services.
Native views bind preferences and dispatch navigation. Retain the existing worker and bounded viewport.

1. File nine issues under rendering, reader, annotations, or export features.
2. Add failing regressions for inline-code font fallback, unique DOM IDs, heading selections, and export distinction.
3. Fix `renderer/src/host.mjs`, `annotations.mjs`, `reader.css`, and `apple/Core/AnnotationExporter.swift`.
4. Add stable native path-copy access and Command-click in `Shared/ReaderView.swift`, `FolderRow.swift`,
   `Mac/ReaderWindowController.swift`, and a new `Shared/DocumentLocationView.swift`.
5. Add opt-in soft breaks and source-line gutters through `Core/ReaderPreferences.swift`, `Shared/ReaderSettings.swift`,
   `renderer/src/parser.mjs`, a new `source-lines.mjs`, host integration, and their tests.
6. Preserve existing anchor IDs through aliases. Skip empty selections and never wrap table-formatting whitespace.
7. Verify renderer/Core regressions, native WebKit rendering, native controls, all unsigned builds, and repository checks.
8. Update Help, status, issue evidence, knowledge, and the local development ZIP. Commit and push verified changes.

Interfaces: `sourceLineLabel(line, total)` uses one-based zero-padded source lines.
`decorateSourceLine(document, element, block, total)` adds a non-selectable block-start label and source range.
`ReaderPreferences.showLineNumbers` and `preserveLineBreaks` default to false and decode older records safely.
`DocumentLocationView(session:)` presents a persistent native popover with selectable path and Copy action.

Files also affected: renderer tests, Core tests, Xcode source registration, `CONVERSATION.md`,
`specs/monomark.issues.json`, `monomark.status.md`, `monomark.package.json`, and `agentknowledge/concepts.yaml`.
Section numbering remains author-controlled. Track automatic numbering as a proposal.

Verification harness files: `Mac/ReviewSmoke.swift`, `Mac/AppDelegate.swift`, and
`Mac/AppDelegate+ArtifactSmoke.swift`. Evidence: `specs/monomark.review-smoke.json`.
The first native harness run failed because a CSS selector began with a digit. The harness now uses ID lookup.
The product's navigation already used ID lookup. Native QA then found and fixed the separate Command-click defect.
