<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# MonoMark status

Updated on 18 November 2026.

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

## Mac App Store preparation on 17 November

The owner selected Free, authorized reuse of CropPrint's private review contact, and confirmed Outcrop Inc as publisher
for every repository application. Submission task #68 is a child of release issue #65.
The [submission guide](../src/app/monomark/AppStore/README.md) contains a draft listing, reviewer instructions, synthetic
documents, and a local-only archive/export command. Version/build fields now use Xcode settings. The Mac category is
Productivity, and the team setting uses the existing Outcrop configuration. Contact details remain outside source.

New tests first reproduced missing release metadata and archive safeguards. All 87 repository Python tests, 47 shell
tests, 121 Core tests, 96 renderer tests, source checks, and unsigned platform builds pass.
The full root test command still fails in unchanged ComposureModelsTests with signal 5. This is separate from MonoMark.
Public privacy and support pages returned HTTP 200. MonoMark support copy is prepared locally and not published.
The native/browser automation host remains unavailable for final screenshots and App Store account checks.
The [feature readiness matrix](monomark.feature-readiness.md) lists incomplete acceptance without claiming all features are finished.

The clean-commit archive succeeded from 9fbcc9004bbb as version 0.1.0, build 77.
Its Apple Development signature belongs to Outcrop team 4JD5A6Q2HL and passes strict verification.
Both Mac architectures, matching debug symbols, category, icon, privacy manifest, license, and source stamp were verified.
Local App Store export failed with exit 70: Xcode reports No Accounts and no matching Mac App Store provisioning profile.
The owner was asked to sign in through Xcode Settings > Accounts. Task #68 remains open for export and account follow-through.
The archive command also passes a regression for the Mac's system Bash without optional API credentials.
Final repository checks now include 48 passing shell cases. No archive upload, App Review submission, or public release occurred.

## Version 1.0 and remaining functionality

The owner requested completion before submission and selected version 1.0.0 plus build/revision. Both native products, renderer metadata, and store draft now target 1.0.0. Build commands use a positive numeric BUILD_NUMBER or Git commit count. About retains the source revision separately. New version and invalid-input tests passed after their recorded failures. All unsigned Apple builds, 121 Core tests, and 96 renderer tests pass. The [completion plan](monomark.completion-plan.md) orders the remaining selection, table/print, lifecycle, and resource work. No submission is authorized by this version change.

## Logical document selection checkpoint

Selections now retain block/UTF-16 endpoints across virtualized mounts, Shift extension, long drags, and native menu/keyboard Select All. Copy and quote anchors resolve through the full worker index. Clipboard limits are explicit, and stale document replies cannot replace the clipboard. New loads remove old selectable content immediately. Native text-copy smoke tests use isolated pasteboards.

The [selection evidence](monomark.selection-smoke.json) verifies real WebKit resolution of 60 offscreen anchors, exact partial copy, full-document copy beyond 4 MiB, source preservation, and at most 80 mounted blocks. The existing heading/table/export/link smoke also passes. 125 Core tests and 110 renderer tests pass, alongside unsigned Apple builds. Large-table and print work under #15 continues.


## Large tables and printing checkpoint

Large tables now split at complete rows into bounded groups, with shared column widths, global row parity, stable semantic destinations, and whole-source table ranges. Each table Copy button resolves the entire grid through the worker. Explicit column and clipboard limits reject unsupported data without truncation.

Print requests carry generation tokens and reject excessive block, HTML, or element counts. Enhancement runs sequentially and checks expanded elements. A cancelled or replaced document ignores late print replies. Native printing retains its complete DOM until AppKit reports completion. The synchronous no-panel test first exposed WebKit's asynchronous pagination requirement. The same completion path now drives production and test jobs.

The [native evidence](monomark.table-print-smoke.json) verifies a 20,000-row table with only 288 mounted rows at the distant search result, exact whole-grid clipboard data, aligned columns, unique IDs, and unchanged source. A 240-row table prints to 12 PDF pages with all rows present, then restores the reader. Rendered first, middle, and final pages were visually inspected. WebKit may divide row borders at page boundaries and does not repeat headers on every physical page. Physical printer and arbitrary paper checks remain separate.

125 Core tests, 123 renderer tests, unsigned Mac/mobile builds, repository checks, and source checks pass at this checkpoint. Wider lifecycle, resource, appearance, provider, and physical-device acceptance continues.


## Hidden-window artifact and copy ordering checkpoint

Real native acceptance passes equation, image, and diagram PNG pixel checks while the reader window stays hidden. Test copies use isolated pasteboards. A new native regression first reproduced an older PNG request completing after a newer text copy. Native request generations now cancel that stale completion. The system clipboard change count also protects newer copies outside the session. Renderer PNG request identifiers keep an older completion from dismissing a newer copy overlay. A failing bridge regression verifies that case.

The [clipboard evidence](monomark.clipboard-smoke.json) passes visible/hidden artifact pixels, isolated clipboard round trips, newer text ordering, document-replacement cancellation, and source preservation. All unsigned platform builds, 125 Core tests, 124 renderer tests, source checks, repository checks, and the full native review/print harness pass. #17 is complete. Annotation reattachment after source edits remains next.


## Full-document quote recovery checkpoint

Highlight recovery now checks quote context across the worker's complete document index. A reused block identifier cannot capture unrelated text. One matching location attaches the quote. Ambiguous and deleted quotes remain in the sidebar. The original stored anchor stays unchanged. Temporary resolved locations drive decoration, navigation, and current section/line export references. Multi-block highlights decorate their visible portions.

Recovery yields between small batches, cancels obsolete revisions, and keeps a bounded quote cache. Document replacement clears the cache. Export uses the same recovery policy, so an outdated block ID cannot produce an incorrect source reference. New failing regressions cover shifted blocks, unloaded duplicates, stale replies, and visible subsets.

The [native recovery evidence](monomark.reattachment-smoke.json) verifies navigation after 600 inserted paragraphs, the current section and line 1203, unloaded duplicate rejection, deleted-quote handling, original anchor preservation, and bounded mounting. The combined selection, table, PDF, export, and link harness also passes. 125 Core tests, 137 renderer tests, and unsigned Apple builds pass. The new recovery module has 100% line/function coverage and 96.08% branch coverage.

Native automation was retried after these fixes. The host still reports a native pipe startup failure and unavailable browser access. Interactive accessibility/focus, real provider grants, screenshots, physical displays/devices, reference-machine resource acceptance, and signed distribution checks remain open. Version 1.0.0 remains the release target. No upload or submission occurred.


## Lifecycle acceptance on 18 November

The owner requested completion of the remaining release checks in sequence. Native acceptance now verifies tab grouping, saved-snapshot restoration, inactive renderer release/reactivation, duplicate filenames, Find-menu focus, automatic/manual reload, rename/deletion recovery, and workspace switching. The [lifecycle report](monomark.lifecycle-smoke.json) passes every executed case. This Mac has one display.

Regression tests first exposed history deletion and checkpoint-ordering races. Transactional deletion cutoffs now reject older visits, including writes from other connections. An explicit later open remains eligible. Only opaque identity/path hashes persist for individual cutoffs. Clear removes those individual hashes and retains one global cutoff. A version-2 migration preserves existing records and rejects unsupported future schemas.

Coordinated source snapshots refresh current filesystem identity. Annotation metadata follows that identity without clearing drafts or queued writes. Refresh starts a new renderer epoch and rearms observation. Checkpoint update timestamps prevent same-visit writes from rewinding state. Restored tabs consume their saved snapshot even without history. Tab-selection observation also releases inactive renderers when no key-window notification occurs.

136 Core tests, 137 renderer tests, unsigned Apple builds, source checks, and repository checks pass. Core line coverage is 94.43%. The combined native annotation/export/selection/table/PDF harness passes after the lifecycle changes. Signed user-selected/provider grants remain open under #11/#24. They are the next stage.


## Native diagnostics and performance checkpoint on 18 November

The [native performance report](monomark.native-performance.json) records actual WebKit workloads on the 64 GiB M5 Pro. Both mixed 1 MiB and 10 MiB documents render math, Mermaid, syntax highlighting, and a local image. Full-index search and distant navigation pass. Source hashes remain unchanged. The sampler keeps the main process separate from an explicit main-plus-all-WebKit upper bound. Other applications contribute to that upper bound. These development-host results do not establish slower-machine or calibrated energy acceptance.

The 1 MiB workload reached a captured frame in about 0.2 seconds. The 10 MiB workload took about 1.2 seconds. The main process peaked at about 92 MB and 130 MB, respectively. These app-only figures exclude WebKit. Idle main-process CPU measured 0–0.4% of one core across five-second samples. The report retains complete timings, combined upper bounds, and sampling limits. A process-exit counter regression and stream-phase regression were corrected before accepting the sampler result.

The new `--smoke-test -` output keeps images in app-owned temporary storage and sends JSON through stdout. The [signed artifact report](monomark.signed-artifact-smoke.json) passes visible/hidden PNG pixels, clipboard round trips, copy ordering, and source preservation. It uses a separate sandboxed Developer ID QA copy without a secure timestamp. The combined signed review still needs investigation. It must not be counted as passing from artifact-only evidence.

The 1.0.0 build 84 archive from clean revision be10919 passes signature and matching-symbol checks. After the owner signed into Xcode, local export reached Apple's membership service. Apple now requires acceptance of the latest Program License Agreement before it can create the missing Mac App Store profile. No upload, notarization submission, or App Review submission occurred.

The development-signed UI app and runner now share Outcrop's Team ID. The former mismatch is no longer the observed blocker. The runner stalls before main during app-sandbox initialization, so no UI cases executed. The supported native/browser automation host was retried and remains unavailable. Real provider panels, VoiceOver, store screenshots, physical multi-display cases, and slower-machine resource acceptance remain open. Current passing suites contain 138 Core and 138 renderer tests. Repository checks and source style checks pass.


## Signed distribution and presentation checkpoint

The signed combined review and signed lifecycle checks now pass. The [review report](monomark.signed-review-smoke.json) covers annotations, exports, implicit links, long selections, large tables, and PDF output. The [lifecycle report](monomark.signed-lifecycle-smoke.json) covers tabs, reload, source replacement, rename/deletion recovery, workspaces, and Find focus. Real external file/provider grants remain separate.

Both local distribution routes succeed for the clean 1.0.0 build 84 preflight. The [distribution record](monomark.distribution-preflight.json) records its source revision, package checksum, architectures, and signing checks. The App Store installer uses Outcrop's installer certificate. The downloadable app uses Developer ID, hardened runtime, and a secure timestamp. It is not notarized. Neither route was uploaded or submitted. The final candidate must include the next verified diagnostics checkpoint.

The [presentation report](monomark.presentation-smoke.json) passes native Light/Dark chrome, rich Markdown colors, System-mode propagation through app-local AppKit appearance changes, mode retention after reload, enlarged type, document landmarks, named/focusable artifact actions, and reversible single-display presentation. Native captures are actual 2560 × 1600 RGB compositor images of the test app's own window. The earlier view-cache capture omitted compositor effects and falsely showed dark file labels. All proposed UI workarounds were removed. The supported currentProcess capture requires no general Screen Recording grant.

Four actual-window screenshot drafts now show reading, rich content in Dark mode, comments, and Notes using synthetic documents. Source bytes remain unchanged. The runtime dependency audit reports zero known vulnerabilities. The unsupported in-process SwiftUI accessibility probe does not establish VoiceOver acceptance. The [manual release checks](monomark.manual-release-checks.md) retain real provider dialogs, VoiceOver, physical multi-display behavior, reference-machine resources, and final store-account review. Physical mobile checks remain outside the first Mac submission.


## Exact candidate 1.0.0 build 86

The [candidate record](monomark.release-candidate.json) supersedes build 84 preflight for final local testing. Clean source 89853dba9ca7 exports successfully as a Mac Store installer and a Developer ID app. Both Mac architectures and matching debug symbols verify. The Developer ID signature includes hardened runtime and a secure timestamp. The local ZIP passes integrity verification. Package and ZIP checksums are recorded.

The exact signed candidate passes [review](monomark.candidate-review-smoke.json), [lifecycle](monomark.candidate-lifecycle-smoke.json), [appearance/presentation](monomark.candidate-presentation-smoke.json), and [artifact clipboard](monomark.candidate-artifacts-smoke.json) acceptance. Execution used this ARM64 M5 Pro. Intel and minimum-macOS runtime acceptance remain unexecuted. The native/browser interaction host was retried and remains unavailable. Real provider grants, VoiceOver, physical displays, reference-machine resources, and final store-account review remain in the manual checklist. No notarization submission, upload, or App Review submission occurred.
