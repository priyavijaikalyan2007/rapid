<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 5f39cb9e-bb82-4abf-bf4e-926190efff41 -->
<!-- AGENT: Remaining Mac functionality and acceptance work before 1.0 submission. -->

# MonoMark 1.0 completion plan

The owner requested completion of remaining work before submission and selected version 1.0.0 plus build/revision metadata.
Do not upload, submit, or call the app finished while known functionality or required acceptance remains incomplete.

## Sequence and interfaces

1. Set both native products and the renderer/listing to 1.0.0. Keep Apple's numeric build field separate from the source revision.
2. Preserve document selections across virtualized mounts and add full-index copy/annotation handling without a full-document DOM.
3. Split large table rendering into bounded row groups while retaining semantic destinations and complete source-block export locations.
4. Verify and improve native printing for large tables and documents, including cancellation and restoration of reading state.
5. Exercise the actual signed reader for lifecycle, source replacement, quote reattachment, appearance, obscured PNG, and resource bounds.
6. Record physical display/provider/device cases separately when the required hardware or access is unavailable.

Version files: apple/MonoMark.xcodeproj/project.pbxproj, apple/Mobile/Info.plist, build.sh, renderer/package.json,
renderer/package-lock.json, AppStore/metadata.json, AppStore/README.md, test/test_monomark_release.py, and test/monomark.bats.
Existing About behavior already presents version, numeric build, and Git revision as separate fields.

Selection work affects renderer/src/host.mjs, annotations.mjs, parser.mjs, worker.mjs, new selection helpers and tests,
and native review acceptance. Store logical endpoints as block index and UTF-16 text offset. Keep mounted ranges bounded.
Use the existing worker message boundary for selected text/anchor resolution. Invalidate pending selections when documents change.
Retain ordinary native Copy, Select All, and keyboard extension behavior. Keep annotation storage limits explicit.

Table/print work affects parser/host/CSS, associated tests, and native print acceptance. Preserve original block IDs and
whole-table source ranges so inline reading-data export never splits a source table.

No new GoF pattern is required. Pure selection/range helpers and existing worker/native adapters suffice.
Keep processing in testable helpers, use bounded requests, and record failing regression tests before implementation.
Commit verified stages separately and keep GitHub issue evidence current.


## Whole-index quote recovery

External insertions can reuse an old block identifier for unrelated text. Resolve quote/context matches against worker-owned canonical text. Require one match across the complete document, including unloaded blocks. Keep original anchors in local storage. Use temporary resolved block IDs for decoration, navigation, and current export locations. Yield between small batches, cancel obsolete annotation revisions, and cap the quote cache.

Add renderer/src/anchor-resolution.mjs and its tests. Update worker.mjs, host.mjs, annotations.mjs and their regression tests. Add Mac/ReviewReattachmentSmoke.swift and its project membership. Test block shifts, distant duplicates, deleted text, legacy whitespace, visible subsets, cancellation, and current source references. No pattern required. Pure recovery functions and existing worker/native adapters suffice.


## Release sequence on 18 November

Finish lifecycle, signed provider access, native performance, appearance/accessibility, physical displays, then signing and store materials. Keep mobile hardware outside the first Mac submission. Record exact unavailable cases without marking their parent gates complete.

Lifecycle files: Core/HistoryStore.swift, Tests/HistoryStoreTests.swift, Shared/ReaderSession.swift, Mac/AppDelegate.swift, Mac/AppDelegate+ArtifactSmoke.swift, new Mac/ReviewLifecycleSmoke.swift, and project.pbxproj. Tests cover deleted-history writes, tab restoration, watcher changes, missing files, duplicate filenames, workspace switching, and inactive renderer release.

Keep HistoryStore's existing record/forget/clear interfaces. Add transactional deletion cutoffs keyed by exact identity/path hashes. Reject checkpoints from visits before deletion, including other connections. A new explicit visit remains eligible. Clear removes individual hash barriers and retains only its global cutoff. No pattern required. Existing SQLite transactions and native adapters suffice. Native acceptance entry points remain test-only and use synthetic files.


Lifecycle regressions also cover same-visit checkpoint ordering, source identity reconciliation after coordinated reads, and pending notes during replacement followed by rename. Add an optional ReadingState.updatedAt for write ordering without changing the visit timestamp. Add DocumentAccess.snapshot, AnnotationController.adoptIdentity, and AnnotationStore.identify. ResourceHandler applies the snapshot identity only for the current epoch. Refresh creates a new rendering epoch and rearms its watcher. Preserve note drafts and queued writes while rekeying metadata. Additional files: Core/ReadingState.swift, Core/DocumentAccess.swift, Core/AnnotationController.swift, Core/AnnotationStore.swift, Shared/ResourceHandler.swift, Shared/ReaderSession+Watching.swift, and related Core tests.


## Signed test output

The signed app must not depend on host reads of its protected container. Add Core/SmokeOutput.swift and Tests/SmokeOutputTests.swift. The existing `--smoke-test -` argument sends JSON through stdout and keeps PNG artifacts in the app's temporary directory. Update Mac/AppDelegate+ArtifactSmoke.swift, Mac/AppDelegate+Smoke.swift, Mac/ArtifactSmoke.swift, Shared/ReaderSession+Clipboard.swift, and project membership. Preserve explicit output paths. No pattern required. One pure path resolver and existing test-only adapters suffice.


## Native performance measurement

Add Mac/ReviewPerformanceSmoke.swift, renderer metrics, and the corresponding host regression. External Python tools create 1 MiB and 10 MiB mixed Markdown fixtures before launch. Native events measure mounted-content readiness, a captured first frame, rich rendering, complete search, and distant navigation. The external sampler reads ps and public proc_pid_rusage counters. Report main-process data and main plus all WebKit helpers as an explicit upper bound. This includes other applications' WebKit helpers and must not be presented as exact per-app attribution.

Add scripts/monomark_native_profile.py, scripts/monomark_profile_metrics.py, scripts/monomark_profile_usage.py and test/test_monomark_profile.py. Update AppDelegate.swift, AppDelegate+ArtifactSmoke.swift, project membership, renderer/src/host.mjs and its tests. Keep generated fixtures, raw captures and stderr in ignored output or temporary storage. Do not record unrelated process arguments or memory contents. Idle CPU uses cumulative CPU deltas. Energy counters remain in opaque OS units. No pattern required. Small OS adapters and pure report parsers suffice.
