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

## Create a local signed candidate

1. Run `./test.sh repository` from the repository root.
2. Run `./src/app/monomark/build.sh all`.
3. Commit the verified source changes.
4. Run `src/app/monomark/tools/archive-app-store --dry-run`.
5. Run `src/app/monomark/tools/archive-app-store`.

The command reads the public team ID from `config/apple-developer.env`.
Xcode uses its configured Apple account or all three existing App Store Connect API environment variables.
Private keys and provisioning profiles remain outside the repository. The command can update signing profiles through Xcode.
The command creates a universal Mac archive, checks matching debug symbols, verifies its signature, and exports locally.
It has no upload action. The export options use `destination=export` and preserve the chosen version/build number.
The default numeric build number is the Git commit count. Set `BUILD_NUMBER` to a larger unused integer when required.
The complete source tree must be clean before a real archive starts.

Expected archive: `build/AppStore/MonoMark-macOS.xcarchive`.
Expected local package: `build/AppStore/Export/`.
A failed signing operation is not an archive or upload success. Keep the Xcode error in the release evidence.

An earlier 0.1 development candidate archived successfully as version 0.1.0, build 77, from source 9fbcc9004bbb.
Its development signature belongs to Outcrop team 4JD5A6Q2HL. Both Mac architectures and matching debug symbols were verified.
App Store export failed with `No Accounts` and no matching Mac App Store provisioning profile.
Sign in through Xcode Settings > Accounts using an account that can access Outcrop Inc, then repeat the local export workflow.
The signed development archive is not an App Store distribution package.

## Store record and review

Use the draft fields in [metadata.json](metadata.json) and the procedures in [REVIEW.md](REVIEW.md).
Use Productivity as the primary category and Utilities as the secondary category.
Reserve the name, bundle identifier, and proposed SKU `monomark-2026` in the Outcrop account when account access is available.
Select macOS only for this candidate. Do not reuse CropPrint's app record, bundle ID, or screenshots.
Keep release mode manual. Reuse CropPrint's private App Review contact, as authorized by the owner.
Leave the actual contact details out of the source repository.

Review the app's privacy and export-compliance answers against the final signed build before submission.
The source uses local hashes and Apple system frameworks, with no custom encryption or remote rendering service.
The draft declares no developer data collection, tracking, advertising, or analytics.
Bundled third-party libraries retain their notices. They are not described as absent.

The public privacy and support URLs returned HTTP 200 during preparation.
The privacy page describes local app processing. The support page currently describes CropPrint and generic GitHub support.
Add MonoMark-specific support instructions before final submission. [SUPPORT-DRAFT.md](SUPPORT-DRAFT.md) supplies that text.
This preparation does not publish a website change.

## Screenshots and remaining acceptance

Capture actual current Mac UI from the synthetic files in Fixtures. Keep private paths, documents, and notes out of the images.
Use one accepted 16:10 size, preferably 2560 × 1600 pixels, without an alpha channel.
Capture the reader with Files, rendered math/diagram/table content, annotations and Notes, and appearance controls.
Inspect each screenshot before adding it to the store. Do not substitute a document-only WebKit snapshot for the full app UI.
The native/browser automation host is unavailable. An app-owned ScreenCaptureKit capture now produces four full-window drafts without general Screen Recording access. See Screenshots for the inspected RGB images and manifest.

Apple lists the accepted Mac sizes in its [screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
The [release tracker](https://github.com/priyavijaikalyan2007/rapid/issues/65) retains the open acceptance checks.
Keep provider-file access, native resource budgets, selection across unloaded content, large-table printing, and display checks open.
Do not submit for review until the selected release gates pass and the listing matches the supported behavior.


## Verified local distribution preflight

Version 1.0.0 build 84 from clean be10919e49f1 exports through both channels. The Mac Store installer signature and Developer ID app signature verify. The Developer ID app includes hardened runtime and a secure timestamp. Its notarization remains pending. See specs/monomark.distribution-preflight.json for exact evidence. Nothing was uploaded or submitted. Rebuild from the final verified checkpoint before selecting the submission build.

The owner signed into Xcode and accepted Apple's latest Program License Agreement. Xcode created the matching Mac Store profile. The earlier account/agreement blockers are resolved. Store-record and final privacy/export-compliance checks remain separate. The manual checks are in specs/monomark.manual-release-checks.md.


## Exact local candidate

The current candidate is 1.0.0 build 86 from clean source 89853dba9ca7. Both signed exports and the exact Developer ID app's review, lifecycle, presentation, and artifact checks pass. The checked-in candidate report at specs/monomark.release-candidate.json records artifacts, checksums, and manual gates. The local app is under src/app/monomark/build/ReleaseCandidate/1.0.0-86/DeveloperID/MonoMark.app. The App Store package and direct ZIP are in sibling AppStore and Download folders. The ZIP is not notarized and is not approved for public distribution.


## Final store answers and public pages

STORE-ANSWERS.md records proposed privacy, age-rating, encryption, and listing answers for build 86. It cites Apple's current definitions and the implementation evidence. Nothing was entered in App Store Connect. Apple requires initial app-record creation through its website.

The live support and privacy pages return HTTP 200 but do not yet name MonoMark. The repository now includes the prepared MonoMark support section and local-reading-data policy text. Website tests, generated HTML/link validation, and Wrangler's local deployment preview pass. Publication requires the explicit deployment request in ADDITIONAL.md. This documentation work does not change the signed app candidate.
