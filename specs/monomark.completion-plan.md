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
