<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 6212aed3-8c22-4bfb-9a3a-d3f78110eed2 -->
<!-- AGENT: Mac-first release handoff, account prerequisites, and local archive/export instructions. -->

# Monoleaf Mac App Store preparation

This folder contains a draft listing, reviewer instructions, and synthetic review documents.
Use [the Mac listing handoff](MAC-LISTING.md) for the current App Store Connect fields and screenshot order.
The owner selected Free and confirmed Outcrop Inc as publisher for all repository applications.
The release target is version 1.0.0 for macOS 15 or later, on Apple silicon and Intel.
The bundle identifier remains `us.outcrop.MonoMark`. The secondary iPhone/iPad product is not part of this first submission.
The owner reports selecting macOS and iOS in App Store Connect on 22 November 2026.
Saved field values and name acceptance remain unverified by the assistant.

## Historical signed baseline

The app is now named Monoleaf. Do not upload the older MonoMark candidate as the renamed release.
A new signed candidate and new notarization must follow the rename.

Historical version 1.0.0 build 93, clean source c1bab98ec3a7, contains the settings, metadata-reload, and maximized-startup fixes.
The App Store installer and Developer ID app export successfully. Both architectures and matching debug symbols verify.
The Developer ID app has sandbox entitlements, hardened runtime, and a secure timestamp.
Signed review, lifecycle, artifact-copy, and appearance/presentation checks pass. Review and artifact checks also pass on repeat.
The local ZIP passes integrity verification. See specs/monomark.release-candidate.json for checksums and evidence.

Artifacts are under src/app/monomark/build/ReleaseCandidate/1.0.0-93, in Notarized, DeveloperID, AppStore, and Download.
The installed developer app remains unchanged. Personal reading data was not inspected or replaced.

Apple notarized build 93 on 21 November 2026. Its ticket, signature, distribution policy, and extracted ZIP ticket verify.
The post-notarization native review passes. The direct ZIP is MonoMark-1.0.0-93-notarized-macOS.zip.
Build 86 is a superseded historical baseline and does not contain these fixes.
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
Expected new archive: build/AppStore/Monoleaf-macOS.xcarchive. Expected installer: build/AppStore/Export.
Signing keys, account credentials, and provisioning profiles remain outside source.
The earlier Xcode account and agreement blockers are resolved.

## Store record and review

Use metadata.json, STORE-ANSWERS.md, and REVIEW.md. Proposed store answers are not entered in App Store Connect.
Use the restored record under Outcrop Inc with name Monoleaf, bundle ID us.outcrop.MonoMark and its existing SKU monomark-2026.
The owner confirmed that Monoleaf is available after Apple rejected MonoMark.

Choose New App. New App Bundle groups separate products and is not the intended model for platform versions of Monoleaf.
Use macOS and iOS platform versions in that record. The iOS build supports both iPhone and iPad.
The iOS platform can be added later if the Mac version ships first.

Apple requires the platform targets to share the bundle ID for universal purchase.
The mobile target currently uses us.outcrop.MonoMarkMobile. Task #72 tracks alignment and mobile signing before its first store upload.
The notarized Mac build 93 already uses the intended bundle ID. Its artifact remains unchanged.

Keep the price Free and release mode manual. Use Productivity and Utilities as the proposed categories.
Reuse CropPrint's authorized private review contact directly in App Store Connect. Keep contact details outside source.
Review the final privacy, age-rating, and export-compliance questions against the selected signed build.
Apple requires initial app-record creation through its website.

The canonical support and privacy pages include the former name MonoMark, verified on 21 November 2026.
Local page source now uses Monoleaf. Those text changes need a separate publication request.
The app processes documents locally and has no native analytics, account system, or remote rendering service.
Bundled libraries retain their own notices. The current bundled-runtime audit reports zero known vulnerabilities.

## Screenshots and remaining acceptance

Screenshots contains four new inspected 2560 × 1600 RGB drafts from the Monoleaf development app and synthetic documents.
Verify these captures against the replacement signed candidate before submission.
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
