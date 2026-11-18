<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 69c229aa-6e56-4e98-9a60-6ca8cd8f9de1 -->
<!-- AGENT: Mac-first App Store preparation boundaries, design, and verification. -->

# MonoMark submission preparation

The owner requested release and App Store submission preparation. Prepare a local Mac archive, export configuration,
store listing, review instructions, and nonprivate reviewer files. Keep upload, App Review submission, and public release
as distinct actions. The browser/native automation host remains unavailable at this checkpoint.

## Feature boundary

The main Mac feature set is implemented. Broad feature acceptance remains incomplete for selection across unloaded
blocks, large tables/printing, external edits and file providers, sustained native resource use, and multiple displays.
Automatic subsection numbering remains an optional proposal. Physical iPhone/iPad acceptance and their app icon remain
outside the first Mac submission. Do not claim complete platform parity or verified large-document performance.

## Files and interfaces

Modify Mac/Info.plist and MonoMark.xcodeproj/project.pbxproj for version/build substitution, category, and team settings.
Add AppStore/ExportOptions.plist with a local export destination. Add AppStore/metadata.json as the listing draft.
Add AppStore/REVIEW.md, AppStore/README.md, and AppStore/Fixtures/ for review instructions and synthetic examples.
Add tools/archive-app-store with `--dry-run` and normal local archive/export modes. It has no upload action.
Extend test/monomark.bats for argument, dirty-tree, and dry-run boundaries.
Extend test/test_monomark_release.py for version, category, listing lengths, and local-only export contracts.
Update PUBLISHING.md to route MonoMark to its own guide. Update status, issue map, conversation, and knowledge records.

No pattern required - the existing build tools and small validation helpers suffice.
Keep native settings in the Xcode project, shell entry points thin, and listing text separate from executable code.
Read the existing public Outcrop team configuration. Keep private keys, profiles, and passwords outside the repository.

## Verification sequence

1. Run new contract tests and record their expected failures.
2. Add release configuration and the archive command.
3. Run repository, source, and relevant MonoMark checks.
4. Commit the verified preparation files.
5. Attempt the local signed archive and export from that clean revision.
6. Inspect actual signatures, provenance, architecture, and matching debug symbols when an archive exists.
7. Record account/tool blockers without claiming an upload or review submission.
