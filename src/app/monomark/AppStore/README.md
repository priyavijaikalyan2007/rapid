<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 6212aed3-8c22-4bfb-9a3a-d3f78110eed2 -->
<!-- AGENT: Mac-first release handoff, account prerequisites, and local archive/export instructions. -->

# MonoMark Mac App Store preparation

This folder contains a draft listing, reviewer instructions, and synthetic review documents.
The owner selected Free and confirmed Outcrop Inc as publisher for all repository applications.
The release target is version 1.0.0 for macOS 15 or later, on Apple silicon and Intel.
The bundle identifier remains `us.outcrop.MonoMark`. The secondary iPhone/iPad product is not part of this first submission.
The listing is a draft until the owner checks it and App Store Connect accepts the chosen name and settings.

## Current local candidate

Version 1.0.0 build 93, clean source c1bab98ec3a7, contains the settings, metadata-reload, and maximized-startup fixes.
The App Store installer and Developer ID app export successfully. Both architectures and matching debug symbols verify.
The Developer ID app has sandbox entitlements, hardened runtime, and a secure timestamp.
Signed review, lifecycle, artifact-copy, and appearance/presentation checks pass. Review and artifact checks also pass on repeat.
The local ZIP passes integrity verification. See specs/monomark.release-candidate.json for checksums and evidence.

Artifacts are under src/app/monomark/build/ReleaseCandidate/1.0.0-93, in DeveloperID, AppStore, and Download.
The installed developer app remains unchanged. Personal reading data was not inspected or replaced.
Build 93 awaits notarization approval. Build 86 is the historical notarized baseline and does not contain these fixes.
No App Store build upload, App Review submission, or public app download has occurred.

## Create a local signed candidate

1. Run `./test.sh repository` from the repository root.
2. Run `./src/app/monomark/build.sh all`.
3. Commit the verified source changes.
4. Run `src/app/monomark/tools/archive-app-store --dry-run`.
5. Run `src/app/monomark/tools/archive-app-store`.

Use a clean checkout. The unrelated owner-edited UI-test scheme must remain separate.
The archive command reads the public team ID from config/apple-developer.env and uses Xcode's configured account.
It validates matching symbols and signatures, then exports locally. It has no upload action.
The default numeric build is the Git commit count. Set BUILD_NUMBER to a larger unused value when needed.
Expected archive: build/AppStore/MonoMark-macOS.xcarchive. Expected installer: build/AppStore/Export.
Signing keys, account credentials, and provisioning profiles remain outside source.
The earlier Xcode account and agreement blockers are resolved.

## Store record and review

Use metadata.json, STORE-ANSWERS.md, and REVIEW.md. Proposed store answers are not entered in App Store Connect.
Check name availability and create the macOS record under Outcrop Inc using bundle ID us.outcrop.MonoMark and SKU monomark-2026.
Keep the price Free and release mode manual. Use Productivity and Utilities as the proposed categories.
Reuse CropPrint's authorized private review contact directly in App Store Connect. Keep contact details outside source.
Review the final privacy, age-rating, and export-compliance questions against the selected signed build.
Apple requires initial app-record creation through its website.

The canonical support and privacy pages include MonoMark and were verified again on 21 November 2026.
The app processes documents locally and has no native analytics, account system, or remote rendering service.
Bundled libraries retain their own notices. The current bundled-runtime audit reports zero known vulnerabilities.

## Screenshots and remaining acceptance

Screenshots contains four inspected 2560 × 1600 RGB full-app drafts made from synthetic documents.
The capture uses only the app's own window. It does not require general Screen Recording access.
The desktop must be unlocked for compositor captures. Native CUA and XCTest UI limitations remain separate.

Keep these gates open until executed:

- Real external/provider reopen and export-write grants under #11 and #24.
- VoiceOver, additional physical displays, Intel and minimum-macOS runtime under #28.
- Reference-machine resource budgets and calibrated energy under #14.
- Final store record, listing, privacy, contact, and selected testing under #68.

The owner has no second display or another supported Mac available. Those hardware checks remain unexecuted.
Mobile physical acceptance is outside the first Mac submission. Optional subsection numbering #53 is a future proposal.
Use specs/monomark.manual-release-checks.md and GitHub release #65 to track the remaining work.
Notarization uploads, App Store uploads, review submission, and public distribution remain separate release actions.
