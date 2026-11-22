<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: f827d693-8257-4bbd-8720-3c5641598848 -->
<!-- AGENT: Mac App Store Connect field handoff and screenshot upload order. -->

# Mac listing handoff

The owner selected macOS and iOS in one App Store Connect record on 22 November 2026.
This handoff covers the Monoleaf macOS 1.0.0 listing. The assistant cannot verify saved fields because browser access is unavailable.

## Screenshots

In the sidebar, select macOS version 1.0.0.
Under Product Page Information, select App Previews and Screenshots, then the Mac device area.
Upload these PNG files there in this order:

1. [Reading and Files](Screenshots/01-reader.png)
2. [Code, equations, diagrams, and dark appearance](Screenshots/02-rich-dark.png)
3. [Highlights, comments, and Contents](Screenshots/03-comments.png)
4. [Reading notes beside tables and code](Screenshots/04-notes.png)

Each image is 2560 × 1600 pixels, RGB, without transparency.
Apple accepts this 16:10 size for Mac screenshots.
These are actual app captures from synthetic documents, without added marketing artwork.
The [manifest](Screenshots/manifest.json) records their original source, capture date, checksums, and latest visual review.
They are new captures from the renamed development app, not historical signed build 93.
Verify them against the replacement signed candidate before submission.

Extract the listing ZIP before uploading. Select the PNG files inside Screenshots, not the ZIP or a chat preview.
Use the macOS version screenshot area. These Mac dimensions do not meet iPhone or iPad screenshot requirements.

Header and Search Results is a separate, optional creative-artwork tab. Its 5244 × 2950 universal asset and
3840 × 1646 header sizes are not Mac screenshot requirements. Leave that artwork empty for this submission.
In Asset Library, choose + > Previews and Screenshots when uploading these files. Do not choose Upload Creative Assets.

An app preview video is optional. iPhone and iPad need their own screenshots for the iOS version.

## Listing fields

Use [metadata.json](metadata.json) as the source for the listing text.
The local handoff folder under local/release-artifacts/monoleaf/Listing/Monoleaf-1.0.0 contains plain-text copies of each field.

| App Store Connect field | Source or choice |
| --- | --- |
| Language | English (United States) |
| Name | metadata.json: name |
| Subtitle | metadata.json: subtitle |
| Promotional Text | metadata.json: promotionalText |
| Description | metadata.json: description |
| Keywords | metadata.json: keywords |
| Support URL | metadata.json: supportURL |
| Marketing URL | Leave blank. No Monoleaf product page is supplied. |
| Version | metadata.json: version |
| App icon | Included in build 111 through the Xcode asset catalog. No separate App Store icon upload. |
| Copyright | metadata.json: copyright |
| What's New | Unavailable for the first version |
| Routing App Coverage File | Leave blank. Monoleaf is not a routing app. |
| App Clip or Game Center | No configuration needed |
| Build | Monoleaf build 111, attachment confirmed by the owner on 22 November 2026 |

The name and subtitle permit 30 characters each. Promotional Text permits 170 characters.
The description permits 4,000 characters. Keywords permit 100 bytes.
The prepared English text passes these limits.

## Selected build and review draft

The owner confirmed that build 111 replaced build 107 on 22 November 2026.
Remote attachment was not independently inspected.

Click Add for Review to prepare the submission draft and identify missing required fields.
This action does not submit the app to Apple. Submit for Review is a separate action after final acceptance and authorization.

## Shared app and review settings

Use Productivity as the primary category and Utilities as the secondary category. Keep the price Free.
Use the privacy-policy URL from metadata.json in App Privacy.
Use [STORE-ANSWERS.md](STORE-ANSWERS.md) for the proposed privacy, age-rating, and encryption answers.
Do not claim accessibility support that the remaining evaluation has not verified.

Set Sign-in required to No. Copy the authorized CropPrint review contact directly into the private contact fields.
Use [REVIEW.md](REVIEW.md) for Review Notes. The public examples give reviewers a repeatable workflow.
Choose manual release under Version Release.

Save the listing as a draft. Screenshot and text preparation does not complete the remaining release checks.
Build 111 uploaded successfully after owner authorization. The owner confirmed build selection.
The owner confirmed App Review submission on 22 November 2026. Apple approval and public release remain unconfirmed.

## App icon

Build 111 includes the compiled Mac AppIcon. Apple gets the store icon from the uploaded build.
The handoff includes Icon/Monoleaf-1024.png for optional website use. It is the existing app artwork, not a new design.
Website publication remains separate.

## Apple references

- [Asset types and current upload tabs](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets)
- [Creative artwork sizes](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Platform version fields and limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [How Apple receives app icons](https://developer.apple.com/help/app-store-connect/manage-app-information/add-an-app-icon/)
- [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

- [Prepare a review draft and submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
