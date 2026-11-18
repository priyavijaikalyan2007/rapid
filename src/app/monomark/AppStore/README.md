<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 6212aed3-8c22-4bfb-9a3a-d3f78110eed2 -->
<!-- AGENT: Mac-first release handoff, account prerequisites, and local archive/export instructions. -->

# MonoMark Mac App Store preparation

This folder contains a draft listing, reviewer instructions, and synthetic review documents.
The owner selected Free and confirmed Outcrop Inc as publisher for all repository applications.
The initial candidate is version 0.1.0 for macOS 15 or later, on Apple silicon and Intel.
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
The native/browser automation host is unavailable, so final screenshot capture remains open.

Apple lists the accepted Mac sizes in its [screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
The [release tracker](https://github.com/priyavijaikalyan2007/rapid/issues/65) retains the open acceptance checks.
Keep provider-file access, native resource budgets, selection across unloaded content, large-table printing, and display checks open.
Do not submit for review until the selected release gates pass and the listing matches the supported behavior.
