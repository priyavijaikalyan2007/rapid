<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: f6d013d0-4101-47d0-bbab-8087da1052a5 -->
<!-- AGENT: Evidence-based proposed store answers for the exact first Mac candidate. -->

# Proposed App Store answers

These answers describe the intended Monoleaf 1.0.0 submission. The owner confirmed that the new name is available.
The local signed candidate is Monoleaf 1.0.0 build 107, clean source a2aeedca4fa4.
Its App Store installer and Developer ID copy verify locally. Build 107 uploaded successfully.
Apple processing was last observed. No App Review submission occurred.
Saved field values remain unverified by the assistant.
Confirm the displayed questions and company requirements before submitting them. Keep release mode manual.

## Record and listing

| Field | Value |
| --- | --- |
| Publisher | Outcrop Inc |
| Name | Monoleaf, owner-confirmed availability |
| App record platforms | macOS and iOS, selected by the owner |
| Current listing and candidate | macOS |
| Bundle ID | us.outcrop.MonoMark |
| SKU | monomark-2026 |
| Primary language | English, United States |
| Primary category | Productivity |
| Secondary category | Utilities |
| Price | Free |
| Version and build | 1.0.0, build 107 |
| Minimum system | macOS 15.0 |
| Login or demo account | None required |
| Purchases, subscriptions, advertising | None |
| Release mode | Manual |
| Review contact | Reuse CropPrint's authorized private contact directly in App Store Connect |

Use metadata.json for the description, keywords, subtitle, promotion text, and canonical support/privacy URLs.
Use REVIEW.md for reviewer instructions. Use Screenshots/manifest.json for the four inspected Mac screenshots.
Apple requires creation of the app record through the App Store Connect website. Its Apps API does not create new apps.
See [Apple's app-record instructions](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/).

## Privacy

Proposed declaration: Data Not Collected. Tracking, advertising, and app analytics are absent.
Documents, bookmarks, file paths, history, settings, highlights, comments, and Notes remain on the device.
Export writes to the user-chosen file. It does not send reading data to Outcrop.
External links open in the user's browser. Remote document images are blocked.
The website's disclosed analytics are separate from the native app and do not run inside Monoleaf.

Evidence includes Shared/PrivacyInfo.xcprivacy, the renderer's restrictive resource policy, native navigation, and the bundled library audit.
Apple defines collection in its [App Privacy Details guidance](https://developer.apple.com/app-store/app-privacy-details/).
The public policy currently names MonoMark. Local source now names Monoleaf, but its publication remains pending.

## Age-rating questionnaire

Use these feature facts for the live questionnaire. Let App Store Connect calculate the rating.
Do not apply a higher-age override or select the Kids category without an additional product reason.

| Question area | Proposed answer and evidence |
| --- | --- |
| Parental controls or age assurance | No app-provided controls or age-assurance feature |
| Unrestricted web access | No. The app renders local Markdown and opens external links in a separate browser. |
| User-generated content | No broad distribution. Users read local files and keep private local reading data. |
| Messaging or chat | No |
| Advertising | No |
| Profanity, fear, violence, sexual content, substance references | None in the app's supplied content or intended experience |
| Medical or treatment information, health claims | None supplied by the app |
| Gambling, contests, simulated gambling, loot boxes | None |

A user's arbitrary local file is not curated app content. The app supplies technical reading examples.
Apple defines user-generated content through broad distribution and unrestricted web access through navigation within the app.
Use the current [age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
and [questionnaire instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).
Record the calculated global and regional ratings after completing the live form.

## Encryption export declaration

The signed candidate sets ITSAppUsesNonExemptEncryption to false. This is the proposed engineering configuration.
The build 107 Mac archive and both exports retain this Boolean value.
The mobile source now declares the same value. Unsigned iOS and Simulator builds verify its generated property lists.
This mobile change does not alter the signed Mac candidate or establish mobile release readiness.
The source uses SHA-256 for identities and source checks. It does not implement a custom document-encryption service.
System frameworks provide any operating-system encryption or transport behavior.
The final organization response must match the actual build and the questions Apple presents.

Apple explains the flag in its [property-list reference](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption).
The flag covers no encryption or exempt encryption. It is not a claim that system encryption never occurs.
See [Apple's export-compliance guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).
