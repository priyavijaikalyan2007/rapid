<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# MonoMark status

Updated on 16 November 2026.

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
The current renderer suite passes 71 tests, with 97.92% line coverage for loaded renderer modules.
The native core suite passes 90 tests, with 94.17% line coverage including the autosave controller.

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


## Reader review checkpoint on 16 November

Issues #47–#55 track the nine review items. Inline code now uses a separate monospace default and visible styling.
The native Document Location popover keeps a selectable path and Copy Path action available.
Plain file clicks reuse the current tab. Command-click and the context action open a new tab.
Native QA reproduced the modifier bug and confirmed two tabs after using the current event's modifier flags.

Heading selection omits structural whitespace. Legacy empty table anchors are ignored during decoration.
Marks cannot introduce anonymous table cells, tables retain one grid, and semantic navigation IDs are unique.
Known offscreen locations prevent exported quotations from stealing an original highlight.
Export labels highlighted text and comments separately, quotes only the highlighted text, and escapes literal annotation text.

Settings adds optional preserved source line breaks and a padded source-line gutter.
The gutter shows each block's starting line, with the source range on hover. It is excluded from annotations and print.
Front matter and hidden comments retain their original source-line offsets. Standard soft-break behavior remains the default.
Numbering remains author-controlled. Automatic subsection numbering is a proposal under #53.

The [review smoke](monomark.review-smoke.json) measures actual WebKit header/body column geometry before and after
an offscreen annotation jump. It verifies heading text, one saved anchor, unique IDs, monospace code, preserved preamble
lines, source numbering, and unchanged fixture source. Native QA confirms path clipboard round-trip and both settings.
All unsigned platforms compile. Renderer tests pass 71 cases at 97.92% line coverage. Core passes 90 tests at 94.17%.
Repository and source checks pass. Physical mobile execution and the native UI runner remain unverified.


## Reload, invocation, and source-reference checkpoint

Tasks #56–#58 add selectable auto-reload, manual Refresh, section/line export references, and a bundled Mac launcher.
The watcher observes the file and parent directory, coalesces bursts, rearms after replacement, and filters unrelated writes.
It uses event notifications rather than a polling timer. Core tests cover direct writes, replacements, filtering, and cancellation.

The launcher validates paths, supports dot/parent folders and multiple files, follows its installed symlink, and preserves spaces.
The native install action creates the link at a user-selected location. Native QA verifies the installed link, two-file tab opening,
and `monomark .` workspace opening. Existing tabs remain open. Manual mode retains content until Refresh.

Exports resolve saved quotations in bounded detached blocks. The visible viewport remains unchanged. Section paths and
one-based block source ranges accompany each resolved annotation. A native source-response SHA-256 stamp is carried through
the worker and checked against fresh coordinated source before writing. Tests verify stale source remains unchanged.
The [follow-on evidence](monomark.followon-smoke.json) verifies the real WebKit/native source-stamp contract and references.
Inline/selective exports (#59–#60) and optional implicit file/section links (#61–#62) remain in progress.

Checkpoint verification: 97 Core tests and 83 renderer tests pass, including an empty-document notes-export regression.
All unsigned platform builds, repository checks, source style, and launcher shell checks pass.


## Inline and selective export checkpoint on 17 November

Tasks #59–#60 add native choices for annotations, notes, or both. Output can be a document copy, a reading-data-only
file, or the current file on Mac. Document output offers end-section or inline placement. Mobile exports copies.
Inline annotations follow complete source blocks. Notes appear at the end. Marked ranges are validated before replacement.
Unowned source bytes survive CRLF files and files without a final newline. Repeated exports remain stable.
Source-line references account for inserted blocks. Missing and stale inline locations fail before a write.

Generated sections retain original block IDs and remain outside annotation targets. Literal comment text preserves
math/strike characters and newline conventions. Standalone data cannot overwrite the source through symlinks or file aliases.
Notes-only export does not require the original file to exist. Local notes remain after export and identity migration.
The [inline evidence](monomark.inline-smoke.json) records actual WebKit and native dialog checks.
All unsigned builds, 109 Core tests, and 86 renderer tests pass. Physical mobile and signed-provider checks remain open.

## Reference navigation and clipboard checkpoint on 17 November

Tasks #61–#62 add optional implicit file and numbered-section links. Both settings default to off.
A bounded shared metadata index coalesces folder scans across tabs. It excludes hidden paths, packages, and symlinks.
Unique Markdown filenames and relative paths open new tabs. Unique numbered headings accept §, #, and $ references.
Missing and ambiguous references remain literal. The view preserves code, math, authored links, and source files.

All unsigned platform builds, 112 Core tests, and 96 renderer tests pass. Renderer line coverage is 97.65%.
The [reference evidence](monomark.references-smoke.json) records WebKit dispatch, section jumps, and bounded mounting.
Native UI checks confirm new tabs for Other.md and My File.md and a jump to section 9.
Actual Command-C selection copied a sentence from the rendered document. Command-V pasted the same sentence into
both an annotation comment and Notes. The checks used synthetic files in an isolated QA application.
The owner authorized release checks after these features. Distribution signing and publication remain separate gates.

## First release checks on 17 November

The owner selected Mac App Store and downloadable builds. GitHub #65 tracks the two routes and remaining release gates.
Release checks reproduced duplicate history rows after atomic file replacement (#63). A path fallback now recovers reading
metadata after access is granted. One SQLite transaction retains the latest row and rejects stale windows.
Tests cover real replacement, preferences, position, rename, reopen, and unrelated paths.
Shared privacy declarations now cover app-only preferences and selected/app-owned file metadata (#64).
Resource tests failed before implementation and pass afterward. Mac, iOS simulator, and device bundles contain the manifest.
No source or reading-data upload occurs. Both signing certificate types are present. No signed archive or upload is claimed.

## Icon and signed-sandbox checkpoint on 17 November

The generated Mac icon includes all ten required sizes and compiles into AppIcon.icns and Assets.car (#66).
Signed QA reproduced missing WebKit helper permission (#67). The corrected outgoing client entitlement preserves
the strict bundled-only renderer policy. The signed review harness exited zero. Its container report remains protected
from host reads. Signature validation passed. This was a local untimestamped QA signature, not a distribution package.
Repeated renderer crashes now stop after two automatic retries in 60 seconds. Refresh explicitly restarts the reader.
All unsigned Apple builds, 121 Core tests, 96 renderer tests, repository checks, and source checks pass.
Core line coverage is 94.33%, including 100% for the recovery policy. Renderer line coverage is 97.65%.
Full and runtime-only MonoMark dependency audits report zero known vulnerabilities. The three repository alerts
concern separate website and Composure dependencies. Native automation is currently unavailable.
The [release check record](monomark.release-checks.md) distinguishes local evidence from open release gates.

The refreshed local trial ZIP now uses source a37978c1e9f2, includes the Mac icon, and contains 5,957,866 bytes.
Its checksum and exact resource verification appear in [the package record](monomark.package.json).
The [final artifact evidence](monomark.final-artifact-smoke.json) passes equation, image, and diagram pixel/clipboard
checks, stale-copy cancellation, and unchanged source. The trial ZIP remains unsigned and unnotarized.
