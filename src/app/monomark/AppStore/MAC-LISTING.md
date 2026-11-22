<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: f827d693-8257-4bbd-8720-3c5641598848 -->
<!-- AGENT: Mac App Store Connect field handoff and screenshot upload order. -->

# Mac listing handoff

The owner selected macOS and iOS in one App Store Connect record on 22 November 2026.
This handoff covers the Monoleaf macOS 1.0.0 listing. The assistant cannot verify saved fields because browser access is unavailable.

## Screenshots

Upload these PNG files to the Mac screenshot area in this order:

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

An app preview video is optional. iPhone and iPad need their own screenshots for the iOS version.

## Listing fields

Use [metadata.json](metadata.json) as the source for the listing text.
The local handoff folder under build/Listing/Monoleaf-1.0.0 contains plain-text copies of each field.

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
| Copyright | metadata.json: copyright |
| What's New | Unavailable for the first version |
| Routing App Coverage File | Leave blank. Monoleaf is not a routing app. |
| App Clip or Game Center | No configuration needed |
| Build | Select the new Monoleaf build after its separately authorized upload finishes processing |

The name and subtitle permit 30 characters each. Promotional Text permits 170 characters.
The description permits 4,000 characters. Keywords permit 100 bytes.
The prepared English text passes these limits.

## Shared app and review settings

Use Productivity as the primary category and Utilities as the secondary category. Keep the price Free.
Use the privacy-policy URL from metadata.json in App Privacy.
Use [STORE-ANSWERS.md](STORE-ANSWERS.md) for the proposed privacy, age-rating, and encryption answers.
Do not claim accessibility support that the remaining evaluation has not verified.

Set Sign-in required to No. Copy the authorized CropPrint review contact directly into the private contact fields.
Use [REVIEW.md](REVIEW.md) for Review Notes. The public examples give reviewers a repeatable workflow.
Choose manual release under Version Release.

Save the listing as a draft. Screenshot and text preparation does not complete the remaining release checks.
No App Store build upload, App Review submission, or public release occurred during this preparation.

## Apple references

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Platform version fields and limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
