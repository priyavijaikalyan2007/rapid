<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 8eb3811b-d691-4476-b279-1728799c44dd -->
<!-- COMPONENT: MonoMark follow-on implementation plan -->

# Reload, invocation, and export refinements

Complete the reader review checkpoint before these changes. That checkpoint is 7d0d53e.
No pattern required - simple function/class suffices. Keep filesystem and export logic in Core services.
Use native controls for preferences, refresh, installation, and export. Tests use synthetic documents only.

## Interfaces and files

1. Add `Core/DocumentWatcher.swift` and tests. `init(file:onChange:)` observes file and directory events.
   `cancel()` releases observation. Coalesce changes and detect replacements without a polling timer.
   `ReaderPreferences.autoReload` defaults to true. `ReaderSession.refresh()` keeps notes and reading position.
   Update `Shared/ReaderSession+Watching.swift`, lifecycle cleanup, settings, toolbar, and the Mac reload command.
2. Add `Core/SourceLocation.swift` with one-based block source ranges and section names.
   `TextAnchor.location` remains optional for older records. Parser metadata supplies section paths.
   Renderer `exportLocations(annotations)` resolves quotations in detached blocks, without growing the visible DOM.
   Worker messages return only referenced blocks. A whole-document SHA-256 stamp detects stale export input.
   Update parser, worker, annotations, host, Native export bridge, `ReadingNotes`, and export services/tests.
3. Add a bundled `tools/monomark` launcher and tests. Resolve symlinks and relative paths before calling native `open`.
   Validate all paths before launch. Include help and a dry-run mode. Add a native install action and documentation.
   Update build resource copying and Mac open-file handling so multiple files use document tabs.
4. Add `Core/ReadingExportOptions.swift` and `InlineAnnotationExporter.swift` with tests.
   Options choose annotations, notes, or both, then end-section or inline layout.
   Support the current file, an annotated copy, or a reading-data-only file.
   Inline annotations follow complete source blocks. Never split a table, list, paragraph, or code fence.
   Remove only validated generated sections before repeat export. Translate source ranges after removal.
   Verify the source stamp before writing. Refuse missing, stale, or ambiguous inline locations without partial writes.
   Notes appear in a generated end section. Keep original newline conventions and all unowned source bytes.
5. Add a shared native export options view and platform presentation. Mac uses save panels and scoped access.
   Mobile uses the existing exporter. Keep local autosave distinct from explicit Markdown export.
6. Verify failing regressions first, native filesystem events, export round trips, launcher paths, renderer/Core tests,
   actual WebKit export resolution, all unsigned builds, repository checks, and source style.
   Update issue evidence, Help, README, knowledge, and package metadata. Commit and push verified stages.

Additional touched files include `Mac/AppDelegate.swift`, `Mac/AppDelegate+Export.swift`,
`Shared/ReaderView.swift`, `Shared/ReaderSettings.swift`, the Xcode project, renderer build resources,
`CONVERSATION.md`, status and issue records, and `agentknowledge/concepts.yaml`.
