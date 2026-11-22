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

## Current local signed candidate

Monoleaf 1.0.0 build 111 uses clean source daed206bff0e. Its archive and both local signing exports pass.
The App Store installer signature and extracted payload verify. Names, version/build, bundle ID, source and encryption declarations agree.
Both Mac architectures and matching symbols verify. The Developer ID copy has sandbox entitlements, hardened runtime and a secure timestamp.
Exact signed review, lifecycle, artifact-copy and presentation checks pass.

Preserved build 111 exports are under local/release-artifacts/monoleaf/ReleaseCandidate/1.0.0-111, in AppStore and DeveloperID.
The owner reports Mac listing and screenshot completion. Build 111 uploaded successfully on 22 November 2026. Xcode reported that Apple began processing it.
No App Review submission occurred. Processing completion and remote icon display remain unverified.
The signed screenshot helper cannot read the external fixtures through its sandbox. Final screenshot comparison remains pending.
See specs/monomark.release-candidate.json for evidence and remaining acceptance.

The Developer ID copy is not notarized. A separate authorized notarization upload is required before direct distribution.
Historical MonoMark build 93 remains preserved under 1.0.0-93, with its record in specs/monomark.release-candidate-build93.json.
Its notarization does not cover build 111. The signed build 111 is installed for local testing. Reading-data paths remain stable, and private reading data was not inspected.

The uploaded record is https://appstoreconnect.apple.com/apps/6837811940/distribution.
The bundled AppIcon supplies the store icon. No separate icon upload is required.
See specs/monoleaf.app-store-upload111.json for the upload receipt.

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

The canonical support and privacy pages now name Monoleaf. The owner approved publication on 22 November 2026.
Both live pages return HTTP 200 and contain the new name.
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
