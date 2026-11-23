<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: c4aed39b-ad7b-49d7-a9de-2e4c98a8be97 -->
<!-- AGENT: iPhone and iPad listing draft and release handoff. -->

# Monoleaf for iPhone and iPad

This is a local draft. No iOS build was uploaded or submitted.
The submitted Mac 1.0.0 build 111 remains separate.

## App Store Connect fields

Use the existing Monoleaf record, app 6837811940, and its iOS platform version.
One iOS build supports both iPhone and iPad. Do not create a separate iPad record.

| Field | Draft value |
| --- | --- |
| Name | Monoleaf |
| Subtitle | Markdown, diagrams, and notes |
| Version | 1.0.0 |
| Bundle identifier | us.outcrop.MonoMark |
| Publisher | Outcrop Inc |
| Language | English (U.S.) |
| Price | Free |
| Release | Manual |
| Categories | Productivity, Utilities |
| Minimum iOS and iPadOS | 18.0 |
| Support | https://outcrop.us/support/ |
| Privacy | https://outcrop.us/privacy/ |
| Copyright | 2026 Outcrop Inc |
| Keywords | markdown,reader,viewer,monospace,mermaid,latex,code,highlight,notes,tables |

The app icon comes from the uploaded binary. It does not need a separate listing upload.
Use CropPrint's authorized private App Review contact directly in App Store Connect.
Do not commit the contact details or account credentials.

## Promotional text

Read Markdown, follow document links, and keep highlights, comments, and notes beside your reading. Rendering and reading data stay on your device.

## Description

Monoleaf is a Markdown reader for iPhone and iPad. Open a file or folder through Files and read rendered Markdown in configurable monospace type.

Browse Files, Contents, Links, and History. Keep several documents open and switch through the Documents menu. On iPhone, navigation opens in a sheet. On a wide iPad, navigation and reading notes appear beside the document.

Read tables, highlighted code, local images, LaTeX equations, Mermaid diagrams, and emoji. Copy code, table data, diagram source, and rendered artifacts through nearby controls.

Select text and add highlights or comments. Keep Markdown or plain-text notes for each document. Reading data stays in the app and does not change the source file.

Export an annotated document copy or a separate reading-data file. Choose inline comments or a generated section at the end. Reading notes appear at the end of an exported document. Mobile exports create files through the system destination picker.

Adjust fonts, text sizes, light and dark palettes, and reading layout. Use Pages or Pageless view and an optional source-line gutter. Choose automatic file reload or refresh manually.

Monoleaf needs no account. Document rendering and reading-data storage run locally. Remote images are blocked, and external links open in your browser.

Monoleaf is a viewer. It does not provide a Markdown source editor.

## Reviewer steps

Download the public [Welcome.md](https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/app/monomark/AppStore/Fixtures/Welcome.md)
and [Guide.md](https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/app/monomark/AppStore/Fixtures/Guide.md).
Keep both files in one folder in Files. No account or network resource is required after download.

1. Tap Open File or choose Open Folder from Document Actions.
2. Open Welcome.md.
3. Open Files and Contents through Document Actions.
4. Select a heading in Contents.
5. Select Links in navigation.
6. Press and hold the companion guide link.
7. Choose Open in New Tab.
8. Switch documents through the Documents menu.
9. Select document text through the standard touch selection menu.
10. Open Notes and Annotations.
11. Add a highlight and enter a comment.
12. Switch to Notes and type or paste a reading note.
13. Close and reopen the app to check local reading-data recovery.
14. Choose Document Actions, Export and Print, then Export Reading Data.
15. Export a separate reading-data file into On My iPhone or On My iPad, then Monoleaf.

Settings includes typography, palettes, appearance, reload and optional view-only reference links.
Mobile export leaves the original document unchanged. The Mac version also offers explicit export into the current file.
Local images require folder access through the system picker. Remote images remain blocked.
The app has no login, subscription, advertising, tracking, analytics or remote rendering service.

## Screenshot preparation

Use actual app captures that show only public example documents and invented notes.
Prepare portrait iPhone screenshots at 1320 × 2868 pixels and iPad screenshots at 2064 × 2752 pixels.
These sizes appear in Apple's [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), checked on 23 November 2026.
Keep screenshot files opaque and verify their dimensions before upload.
Local light/dark JPEG drafts are under local/release-artifacts/monoleaf/MobileDrafts.
Their dimensions, hashes and capture limits appear in specs/monoleaf.mobile-screenshot-drafts.json.

Suggested order: reader, navigation, rich content, private notes.
Draft development captures require comparison against the signed candidate before submission.
The Simulator UI-test receipt does not replace physical touch, Files-provider, keyboard and VoiceOver acceptance.

## Current local candidate

Monoleaf 1.0.0 build 123, source e3b42db2ac36, has a verified development-signed archive.
See specs/monoleaf.mobile-release-candidate123.json and the preserved MobileReleaseCandidate folder.
App Store export currently needs Xcode account access and the iOS App Store profile.
Retry export from the preserved archive after the account is available.
Physical acceptance and comparison of screenshot drafts against the candidate remain open.
No mobile upload, App Review submission or public release occurred.
