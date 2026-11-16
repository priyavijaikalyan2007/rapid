<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# MonoMark status

Updated on 15 November 2026.

MonoMark now has native Mac and iPhone/iPad projects under src/app/monomark.
The first implementation includes document tabs, Files/Contents/Links/History navigation, SQLite reading state,
local previews, per-document typography, a bounded worker-based renderer, complex Markdown, and single-display presentation.
Artifact controls copy source, CSV/TSV/pipe-separated data, or PNG renderings. Appearance offers System, Light, and Dark.
HTML comments are hidden outside literal code. Original Markdown remains unchanged by reading and copy operations.

## Verification

Native-core tests, renderer tests, repository checks, and unsigned active/universal Mac and mobile builds pass.
The Mac executable contains arm64 and x86_64. The initial app bundle is about 9.5 MiB on this host.
Real WebKit smoke evidence shows math, tables, and Mermaid, with 15 mounted blocks for a 16-block fixture.
The [native smoke evidence](monomark.smoke.json) now verifies dark rendering, artifact controls, and successful PNG output.
Visual inspection confirms that exported diagram labels and connector colors remain readable in dark mode.
The regression suite uses real Mermaid output and checks label text after sanitization.
The current renderer suite passes 61 tests, with 97.84% line coverage for loaded renderer modules.
The native core suite passes 89 tests, with 94.63% line coverage including the autosave controller.

The synthetic [indexing evidence](monomark.benchmark.json) records about 487 ms for 10 MiB on this 64 GiB development host.
The Node process RSS after that run was about 264 MB. This is not complete-app or reference-machine performance acceptance.
Inline token graphs are now discarded after each rendered block, reducing retained intermediate work.

The full repository run still fails in unchanged ComposureModelsTests with signal 5.
The MonoMark UI runner could not execute tests because unsigned startup was killed and ad hoc loading reported a Team ID mismatch.
The host's CoreSimulator service is older than the installed Xcode framework, so mobile launch is unverified despite successful compilation.
Physical devices, multiple physical displays, idle energy, and reference-machine acceptance remain unverified.

## Current limits and next stage

The [application guide](../src/app/monomark/README.md) records explicit source, object, image, and print limits.
Cross-viewport selection and very large single-table rendering need further acceptance work.
The reader/copy/appearance checkpoint is committed and pushed as b9677e7.
Annotation checkpoint 639ab63 is also committed and pushed. It adds a native right inspector for highlights, comments, and reading notes.
Annotations and notes use a separate versioned SQLite store with stale-update protection.
Coalesced note writes flush during normal document and application lifecycle changes.
Native smoke and manual UI checks confirm visible highlights, comments, note editing, and recovery from local storage.
The [annotation smoke evidence](monomark.annotations-smoke.json) records highlight restoration after viewport changes.
Direct controller tests cover rapid edits, conflicting windows, recovery, and edits that arrive during a close-time write.

Mac File > Export Notes and Annotations to This File reads current source under file coordination and writes atomically.
Repeated export replaces only one marked section. Tests cover malformed markers, fences, Unicode, and line endings.
Save and Command-S remain unassigned. Export a Copy preserves the original and is also available on mobile.
The signed sandbox write-grant path and physical mobile export remain acceptance checks.
Unmatched quotes receive a visible inspector notice. Reattachment after extensive external edits needs further acceptance work.

## UX refinements

All twelve requests from 14 November are implemented across commits 08ebf87, 2713f6a, and e40c5c6.
The reader now jumps to quoted annotation lines, marks active file rows, reveals folder ancestors, and provides copyable title paths.
Settings uses a horizontal action bar. C#, SQL, and Java use explicit language grammars and distinct token styling.
Annotation panels provide expansion, collapse, and search. New annotations expand automatically.
Notes support separate Unicode-aware search and contextual Mac Find commands.
Font menus include installed families. Native About and offline Help cover build details, reading data, recovery, and export.

Pages and Pageless share the bounded renderer. Paper choices are System, A4, US Letter, and US Legal.
The footer shows approximate current and total pages. Large blocks use expanded sheets rather than clipped content.
Paper selection persists per file and can become an application default. Printing keeps global printer settings unchanged.
Print completion restores the reading location, and document navigation dismisses stale link previews.

An isolated native Mac demo verified page boxes, page progress, paper controls, print-dialog opening,
file selection/revelation, language token colors, horizontal settings controls, installed fonts, About/Help,
annotation expansion, and contextual notes search. The user's existing document windows were left open.
A regression reproduces and prevents repeated remounts while deferred math changes height.
The large-layout test keeps at most 80 mounted blocks for a 10,000-block document.
Physical printer output, mobile interactions, and release performance remain acceptance checks.

## GitHub tracking

The [MonoMark epic](https://github.com/priyavijaikalyan2007/rapid/issues/1) contains nine features and thirty-six task or bug issues.
The [issue map](monomark.issues.json) records the hierarchy. Implementation and acceptance status remain distinct.
All twelve UX refinement issues are closed with implementation and test evidence.
The paper-layout feature #29 is closed. Palette customization is implemented and verified. Remaining platform acceptance stays open.


## Palette checkpoint on 15 November

Native Customize Colors provides independent Light and Dark palettes for all six heading levels,
captions, equations, block-quote text/background/borders, table text/background/header, and alternate rows/columns.
Eight named swatches and Default/Neutral/Ocean/Forest presets use bounded values and contrast validation.
Per-mode reset preserves the other mode. Existing per-file and application-default preferences retain choices.
The renderer accepts only known role names and six-digit RGB values. SVG author colors and syntax token roles remain separate.

Tests cover every swatch/surface combination, light/dark independence, hostile values, reset/presets,
preference recovery, native bridge appearance commands, and simulated operating-system appearance events.
All unsigned builds pass. Isolated Mac QA confirms editing a light heading, independent dark choices,
a Forest dark preset, readable math/tables/diagrams, native dark chrome, and source-view continuity.
Real operating-system appearance transitions and physical mobile interactions remain acceptance checks.


## Workspace checkpoint on 15 November

Feature #42 adds a persistent folder registry (#43), a native workspace switcher (#44), and explicit tab acceptance (#45).
The shared sidebar menu lists recent folders, marks the current workspace, and restores its last available document.
Existing tabs retain their own folder context. Empty workspaces clear prior content and show file-selection guidance.
Normal switching drains notes before the document changes. Granted folder/file scopes are deduplicated and released when unused.
Workspace records use an independent versioned SQLite database. A newer schema fails without destructive migration.
Stale writes cannot replace newer workspace metadata. Forgetting a workspace keeps source files and reading notes.

Core tests cover deduplication, independent connections, stale records, last documents, schema recovery, invalid paths,
missing/moved documents, note detachment, and per-file/default preference boundaries.
Renderer tests verify empty-workspace clearing and rejection of late messages from the previous worker.
Isolated Mac QA switched Alpha to Beta and back, resumed Alpha's second file, and recovered its note.
Two documents remained open in native tabs, with independent workspace and note context.
The empty-workspace test found and fixed a native editor that accepted unsaved text without a document.
The repeat check confirmed that the field rejects edits. New Tab and Close returned to the existing workspace correctly.
The [native regression smoke](monomark.workspaces-smoke.json) confirms note recovery, restored highlights, math, diagrams, and PNG output.
Physical mobile interactions and signed bookmark/provider recovery remain separate acceptance checks.


## Native PNG acceptance checkpoint

The [artifact smoke](monomark.artifacts-smoke.json) verifies equation, local-image, and diagram PNG output
through an isolated native pasteboard. It verifies copied pixels and positive dimensions, not only message delivery.
The local-image test reproduced a blank copy caused by capture before the cloned image decoded.
Image copying now waits for decoding, fails clearly after a deadline/error, and keeps source unchanged.
Document epochs prevent stale copy completion from clearing a newer document's copy overlay.
The native harness also verifies cancellation after document replacement and preserves the user's clipboard.
Visual inspection confirms readable equation output, exact red/blue test-image pixels, and authored diagram colors.
All unsigned builds, 89 Core tests, and 59 renderer tests pass. Native window-occlusion acceptance remains open under #17.


## Development package preparation

The offline bundle now includes the complete project LICENSE alongside third-party notices.
Each renderer rebuild cleans only its own generated output, so obsolete chunk hashes do not accumulate.
Output tests reproduce and prevent missing license files and stale generated assets.
The Mac bundle contains exactly 181 expected renderer files, with no missing or obsolete assets.
All unsigned platform builds, 89 Core tests, and 61 renderer tests pass.
The local Mac package remains an unsigned development build. Signing, notarization, and publishing are separate gates.


## Local Mac development package

[Package verification](monomark.package.json) records MonoMark 0.1.0 build 1 from committed source 32d0b475b442.
The ZIP is src/app/monomark/build/MonoMark-0.1.0-macOS-universal.zip and contains MonoMark.app.
It supports macOS 15 or later on Apple silicon and Intel. The archive is 3,964,290 bytes and passes ZIP integrity checks.
A SHA-256 checksum sits beside it. Runtime dependency audit reports zero known vulnerabilities on 15 November 2026.
Extract the ZIP and copy MonoMark.app to Applications for trial use outside the build directory.
The package has no distribution signing or notarization. Nothing was published or submitted.
Remaining acceptance includes large-document resource budgets, large tables/cross-viewport selection,
window occlusion during copy, broader lifecycle/provider/signed-export cases, and physical mobile/display checks.
