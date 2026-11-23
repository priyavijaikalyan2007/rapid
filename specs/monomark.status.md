<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 59913417-3725-4ef1-8520-025a41a47ea1
Created: 2026
-->

<!-- AGENT: Records MonoMark scope, progress, decisions, and verification limits. -->

# Monoleaf status

Updated on 22 November 2026.

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


## Notarization and published pages on 18 November

The owner explicitly approved the notarization upload and publication of the two public pages. Xcode used its signed-in Outcrop account to upload the Developer ID archive, then exported the notarized app. No new app-specific password was needed. Apple's attached ticket validates, code signing verifies, and the macOS distribution policy returns no errors. The returned executable retains both original Mach-O UUIDs and source 89853dba9ca7. The notarized ZIP passes integrity checks. The post-notarization native review passes. This was a notary-service upload, not an App Store build upload or App Review submission.

The support and privacy pages are deployed from clean 6565781 and verified live. The public-page record contains the Cloudflare version. The terminal host is cmux. This Mac calls its Accessibility permission Device Control and Data Access. After the owner enabled cmux, native AppleScript accessibility automation became available. The enhanced accessibility tree exposes SwiftUI controls. Real folder-open and save-panel export/cancellation pass using only synthetic files outside the app container. Cross-process/provider recovery and VoiceOver remain separate.

The owner then reported settings lost after restarting the app. Bug #69 is a release blocker. Test normal-mode per-file recovery and new-document defaults before selecting a final submission build. Demo/smoke modes use temporary stores, but that observation does not close the reported bug. An earlier metadata-count inspection was rejected by automatic approval review as outside synthetic scope. The owner was asked for bounded settings/saved-tab metadata access for a controlled restart test. No private document text or comments were inspected.

## Settings persistence fix on 18 November

The owner confirmed that all settings reset and gave source line numbers as an example. A native regression reproduced a settings gap without accessing personal data. Settings edits updated document history, but application defaults changed only through Use as Defaults. With no open document, edits had no durable destination. Both a new session and the first opened document lost the edited settings.

Reader-setting updates now save normalized application defaults automatically. Existing document overrides remain separate. Settings no longer requires Use as Defaults, and Done flushes current preferences. Demo and smoke sessions no longer read or modify personal reader defaults. Tests inject an isolated preferences domain instead. No new pattern or library is required. Existing preference serialization and native UserDefaults provide the persistence contract.

The [settings report](monomark.settings-smoke.json) records the native failure before the fix and passing results afterward. A separate writer process exits before a reader process verifies saved settings. Source line numbers, fonts, size, layout, reload, and palette survive that boundary. The full native review passes. All 141 Core tests, 138 renderer tests, active/universal Mac builds, mobile builds, source-style checks, and repository checks pass. Core-only line coverage is 94.77%, and ReaderPreferences line coverage is 100%.

Build 86 does not contain this fix. A new clean signed candidate must replace it before release. This evidence does not claim an interactive restart of the owner's installed build or inspect existing personal settings, tabs, notes, or documents. The installed build 79 remains unchanged.

The first clean signed build 90 review failed during heading selection while the new settings test shared its document. A repeat also failed to capture the heading. Both reports were retained. The settings test now creates an independent synthetic fixture. A separate hardened, sandboxed Developer ID QA copy passes the complete native review after that isolation change. This QA signature has no secure timestamp. It is not the replacement release candidate.

## Metadata reload defect and remaining hardware

Further diagnostics showed an epoch change during selection, with no view replacement or suspension. Test isolation alone was insufficient. Bug #70 tracks metadata-only file events that incorrectly refreshed the document. The regression failed before the fix. The watcher now retains write flags separately and compares readability as part of its transient fingerprint. Metadata-only changes no longer reload. Same-size writes with restored dates, replacements, cancellation, and lost read permission remain observable. Seven watcher tests, 144 Core tests, 138 renderer tests, all Apple builds, and signed QA review/artifact/lifecycle pass. Native selection now explicitly retains its epoch. The report is monomark.metadata-reload-smoke.json.

The owner has no second display or another supported Mac available. Physical display/reference-machine gates remain unexecuted. The owner also requested maximized startup in regular window mode. That request will receive a separate patch before the next clean candidate.

## Maximized regular startup windows

Bug #71 now has native red/green evidence in monomark.startup-window-smoke.json. Regular reader windows use the main screen usable frame before display. Title-bar controls and resizing remain. The app does not enter full screen at startup. Native appearance and reversible explicit presentation pass, and both Mac architectures compile. No mobile source changed. The refreshed bundled-runtime dependency audit reports zero known vulnerabilities. A clean signed candidate must include both this change and the metadata-reload fix.

## Verified replacement build 93 on 21 November

The owner resumed after travel and unlocked the Mac. Clean source c1bab98ec3a7 exports as version 1.0.0 build 93 through both distribution routes. Signatures, sandbox entitlements, secure timestamp, universal UUIDs, matching symbols, ZIP integrity and checksums verify. Exact signed review, lifecycle, artifact copy, and appearance/presentation pass. Review and artifact cases also pass on repeat. This candidate includes fixes #69, #70 and #71. The first compositor capture failed while the screen was locked. Unlocking resolved that environmental failure.

The runtime dependency audit reports zero known vulnerabilities. Canonical support/privacy pages return MonoMark content. Build 86 remains a historical notarized baseline. Its ticket does not cover build 93. Build 93 is not notarized, uploaded to App Store Connect, submitted for review, or publicly distributed. The installed app remains unchanged. Private reading data was not inspected. External/provider, VoiceOver, extra-display/reference-hardware, minimum-OS/Intel and store-account gates remain. The owner confirmed no additional display or Mac is available.

GitHub bugs #69, #70 and #71 are now verified closed with immutable 72728e7 evidence links. Thirteen open records remain, including the epic, feature parents, release records and optional numbering proposal. App Store browser access was retried after travel and its host remains unavailable. No App Store fields were entered. New notarization approval is required for build 93 because the earlier approved artifact was build 86.

## Build 93 notarization completed on 21 November

The owner approved submission of build 93 to Apple notarization. Xcode uploaded the verified c1bab98ec3a7 archive through the existing Outcrop account, then exported the notarized app. Apple's attached ticket validates. Code signing and macOS distribution policy pass. Both original executable UUIDs, version, build and source revision match.

Post-notary review passes, including settings retention and selection epoch preservation. The new notarized ZIP passes integrity checks. Its extracted app retains a valid signature and ticket. The candidate record contains its checksum and Xcode distribution identifier.

This submission was notarization for the direct build. No App Store build upload, App Review submission or public app download occurred. The installed app remains unchanged. Remaining manual/provider/accessibility/hardware and store-account gates stay open.

## Multiplatform store record clarification on 22 November

The owner asked whether Mac, iPhone and iPad need an app bundle. Use one New App record with macOS and iOS platform versions. One iOS build supports both mobile device families. The same bundle ID and SKU identify the product across platforms. The current mobile target still has a different bundle ID.

Task #72 tracks its alignment and signed/device-tested mobile candidate. Mac build 93 remains unchanged. The existing Mac-first candidate does not establish mobile release readiness.

## Mac listing handoff on 22 November

The owner selected macOS and iOS in App Store Connect. AppStore/MAC-LISTING.md now maps the Mac version fields and four screenshot uploads. The local Listing folder and ZIP contain copy-ready text, reviewer notes and unchanged inspected screenshots. Their 2560 × 1600 RGB dimensions, checksums, listing limits and ZIP integrity verify. Existing screenshot provenance remains explicit because the build 93 refresh could not access its fixtures. No app source or signed artifact changed.

Browser access remains unavailable. Saved record values and draft uploads remain unverified. Issue #68 remains open for listing entry, final answers and remaining release checks. No App Store upload or review submission occurred.

## Encryption declaration and name conflict on 22 November

The owner restored the removed record, but App Store Connect reports that MonoMark is already used. A replacement name is pending. No branding or bundle ID changed.

Mac source, build 93 archive and notarized app already declare ITSAppUsesNonExemptEncryption=false. Mobile now has the same Boolean. A regression fails before the fix and passes afterward. All 11 release-contract tests, 96 repository Python tests and 49 Bats checks pass. Unsigned iOS device and Simulator builds pass. Their generated Info.plist files retain Boolean false. Mac signed artifacts remain unchanged.

## Monoleaf rename on 22 November

The owner selected Monoleaf after finding Marklet in use. Native products now build as Monoleaf.app. The Mac bundle ID, old application-data directory, defaults and generated-section markers remain stable. Internal project/scheme/module names remain MonoMark. The optional installer creates monoleaf, with the old monomark bundled alias retained. The owner-edited UI-test scheme remains unchanged.

Rename task #73 links to store task #68. Regressions, 144 Core and 138 renderer tests, 98 repository Python tests, 50 Bats checks, all Apple builds, native development-app review, screenshot capture, website source build and source-style checks pass. New Monoleaf screenshots and the listing ZIP replace earlier listing materials. See monoleaf.rename-checks.json and monoleaf.rename-review-smoke.json.

These screenshots come from the renamed development app. They need comparison with the new signed candidate. MonoMark build 93 remains historical and must not be uploaded as Monoleaf. New signing/notarization, selected manual/store/mobile checks and website publication remain. No installed-app replacement, private-data inspection, upload or submission occurred.

The owner reports screenshot upload failure. The new raw PNGs pass independent 8-bit RGB/no-alpha/dimension checks. Exact App Store error and platform/file selection remain pending. Successful upload is unverified and tracked separately from rename completion.

Task #73 is closed against commit 4cedc42. Open issue titles now use Monoleaf. Screenshot upload bug #74 is attached to #68 and remains open. The actual rejection message and successful Apple processing remain unverified.

The owner supplied upload-field text requesting 5244 × 2950 and 3840 × 1646. Apple identifies these as optional creative artwork sizes. The handoff now names Product Page Information > App Previews and Screenshots explicitly and distinguishes Header and Search Results. Issue #74 awaits successful upload confirmation in the screenshot area.

## Owner-confirmed Mac listing completion on 22 November

The owner reports that Mac listing fields and screenshots are complete. Issue #74 is resolved by successful owner-confirmed upload after selecting the correct screenshot tab. The new signed Monoleaf candidate is next. Clean detached source a2aeedca4fa4 has numeric build 107. Local archival/export starts before any request for App Store upload approval. Final acceptance, upload/processing/testing, build selection and review submission remain separate.

## Local signed Monoleaf build 107 verified

Clean source a2aeedca4fa4 archives and exports through both Mac distribution routes. The 6,959,383-byte App Store installer signature and extracted app verify. Archive and both exports agree on Monoleaf, 1.0.0/107, us.outcrop.MonoMark, source and the false encryption declaration. Both architectures and matching archive symbols verify. The Developer ID copy retains sandbox, hardened runtime and secure timestamp. Exact signed review/lifecycle/artifact/presentation pass.

The main candidate record now describes build 107. Historical build 93 is preserved separately. The owner-completed listing and screenshot upload are recorded, and #74 is closed. The signed screenshot helper still lacks access to external public fixtures, so manual screenshot comparison remains. App Store upload authorization, processing/exact-build testing, remaining provider/VoiceOver/hardware acceptance, website publication and later App Review submission remain. The direct build also needs new notarization authorization. Nothing was uploaded or submitted.

## Authorized App Store upload completed on 22 November

The owner approved upload of build 107. Xcode reports successful upload and the start of Apple processing for app record 6837811940. The archive receipt confirms uploaded build 107 and App Store destination. See monoleaf.app-store-upload107.json. The app already includes AppIcon.icns and the complete Mac asset catalog. Apple gets that icon from the uploaded build. A 1024-pixel PNG copy is available in the local listing handoff for optional website use.

Browser access remains unavailable. Apple processing completion, displayed store icon and build selection remain unverified. Exact-build testing and remaining release checks precede App Review submission. No review submission, website deployment or new direct-build notarization occurred.

## Attached build and approved public-page deployment

The owner reports that build 107 is attached to the Mac version and manual testing is not yet done. The owner approved publishing both prepared pages. Cloudflare version 7f018c00-7748-46c1-9bf0-3d617eae648b is deployed. Canonical support/privacy pages return HTTP 200 through curl and contain Monoleaf. See monoleaf.public-pages-deployment.json. App Review submission remains pending.

The owner then requested safe cleanup of old generated products, an audit/fix of clean.sh, a rebuild and installation in Applications. Source/project rename scope was asked separately. The generated-output path is the current assumption. Build 107 release artifacts will be preserved outside source cleanup.

## Cleanup safety and preserved release artifacts

Task #75 adds six failing-then-passing cleanup regressions. Root help and argument rejection are side-effect free. Component cleanup validates every output before deleting any directory. It protects linked targets/parents and unexpected files, then removes all seven documented build/cache roots. Renderer dependencies, source, SwiftPM configuration and reading data remain.

Existing release exports and listing files are preserved under local/release-artifacts/monoleaf. All 1,593 file hashes match, and preserved signature/ticket checks pass. The uploaded build 107 archive remains outside src in its isolated worktree. Actual source-output cleanup succeeded. A fresh signed rebuild and Applications installation are next.

## Clean rebuild installed for testing

Monoleaf 1.0.0 build 111, clean source daed206bff0e, now runs from /Applications/Monoleaf.app. Signature and installed executable hash match the verified Developer ID export. There was no prior app at the standard Applications paths. Current source output contains only build/Monoleaf.app. Historical release exports and the fresh signed archive/symbols remain in local/release-artifacts/monoleaf. The temporary rebuild worktree is removed. No private app data or windows were inspected.

All 144 Core tests, 138 renderer tests, Apple platform builds, archive/export and four exact signed native suites pass. The repository passes 98 Python tests and 56 Bats checks, including six cleanup safety regressions. See monoleaf.local-install111.json and the build111 smoke reports. Task #75 covers this completed generated-output cleanup/rebuild/install. Source/project rename was not selected. Build 111 has not been uploaded, and App Store build 107 remains attached. Manual owner testing and final release steps remain pending.

## Owner-tested build 111 uploaded

The owner reports that the installed app works well and authorizes upload. Uploaded the preserved clean daed206bff0e archive without rebuilding. Xcode confirms delivery of build 111 and start of Apple processing for app 6837811940, receipt 38156dbd-eef3-4b33-9a1b-a3a36ac03038. See monoleaf.app-store-upload111.json. Build 107 remains the last owner-confirmed selection. Once 111 processes, the owner can remove 107 from macOS version 1.0.0, save, add 111 and save. Listing text/screenshots remain version metadata.

General owner feedback is positive. Specific provider/VoiceOver/hardware acceptance is not inferred from that statement. No review submission, new notarization or deployment occurred in this upload.

## Build 111 selection confirmed by owner

The owner confirms that build 111 replaced build 107 in the macOS 1.0.0 listing. Remote state was not independently inspected. Add for Review is the next draft-validation action. Final acceptance and separately authorized Submit for Review remain pending. Existing unexecuted checks remain open.

## Mac App Review submission confirmed by owner

The owner confirms submission of Monoleaf macOS 1.0.0 build 111 for App Review on 22 November 2026. Remote status was not independently inspected. Apple review outcome and the later manual public-release decision remain pending. Existing unexecuted acceptance checks remain open. Direct notarization and mobile release work remain separate.

## Monoleaf public product guide prepared

The owner requested the website update on 23 November 2026. Task #76 adds the catalog card, product guide, current icon and four public synthetic screenshots. It explains local reading data and explicit export choices. Mac App Store review remains pending and mobile is planned. All 36 site tests, seven-page validation, lint and desktop/mobile light/dark browser checks pass. Deployment follows the verified source commit.

The website update is now published at https://outcrop.us/apps/monoleaf/. Cloudflare version 5713db86-4332-4d28-bd14-0cfe1e5f7e37 deployed from 3b223d0. Thirteen live HTTPS/content checks pass, including matching screenshot/icon bytes and support anchors. Website task #76 is complete. App Review outcome, public app release and remaining app acceptance checks remain separate.

## Mobile readiness and Linux feasibility audit

On 23 November 2026, the owner asked about starting iPad/iPhone work and cross-compiling the Mac app for Linux. Existing MobileReaderView and shared reader/renderer provide a starting point for both mobile form factors. Task #72 still covers bundle-ID alignment, signing, archive validation and physical-device acceptance. Recommend mobile work next. No new mobile build or acceptance result is claimed by this audit.

Linux is a separate port. Swift supports Linux cross-compilation, but AppKit/SwiftUI/WKWebView and Core's Combine/Darwin/file-coordination dependencies prevent compiling the current application unchanged. Platform-independent Swift logic and the bundled web renderer are potential reuse points. A Linux UI, webview bridge and system adapters are required. No Linux target was added or tested.

## Mobile identity and icon prepared

Task #72 now has matching mobile bundle ID/team, a dedicated opaque iOS icon and local-only archive/export tooling. Five new release regressions failed first, then passed. All 18 release contracts, unsigned mobile builds, 103 Python tests, 56 Bats checks and source style pass. See monoleaf.mobile-resources.json. Signed archive, native UI regressions (#77) and physical acceptance remain. The submitted Mac build is unchanged.
