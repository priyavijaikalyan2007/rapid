<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 347782af-904e-4e5b-b3c0-d23d6a9b2f03 -->
<!-- AGENT: Draft App Review notes and repeatable synthetic-document workflow. -->

# Draft App Review notes

Monoleaf is a public Markdown viewer for Mac. It targets readers of technical documents, project notes, and documentation folders.
It requires no account, login, registration, purchase, subscription, or external rendering service.
The app is a viewer. It does not edit Markdown source text.

Download the example documents from the public source repository:

- [Welcome.md](https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/app/monomark/AppStore/Fixtures/Welcome.md)
- [Guide.md](https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/app/monomark/AppStore/Fixtures/Guide.md)

Place both files in the same folder. These examples contain no personal data and need no network resources after download.

1. Open the folder through Monoleaf's native Open command.
2. Select Welcome.md in Files.
3. Select a heading in Contents to move within the document.
4. Open the companion guide link in a new tab through the link actions.
5. Inspect the table, code, equation, and Mermaid diagram.
6. Hover over an artifact's icon controls to see its copy format.
7. Copy selected document text through the standard Copy command.
8. Select a sentence and create a highlight in the right inspector.
9. Add a comment and paste text into its field.
10. Switch the right inspector to Notes and add a reading note.
11. Close and reopen the document to check local reading-data recovery.
12. Choose File > Export Reading Data to inspect the available output choices.

Reading positions, preferences, highlights, comments, and Notes remain in local application data.
The original file changes only after an explicit export to the current file.
An annotated copy preserves the original. Inline comments follow complete source blocks, and Notes appear at the end.
Users can export annotations, Notes, or both to a separate reading-data file.

Settings provides typography, palettes, Light/Dark/System appearance, automatic reload, and optional view-only reference links.
Standard Mac window and full-screen controls apply to each document window.
Local images use the file access granted through the native file picker. Remote images are blocked.
External links open in the user's browser. The app sends no reading documents or reading notes to a rendering service.

The optional command-line launcher opens a folder or multiple files through the installed Mac application.
It is not required for any review workflow. The viewer and local Notes remain usable without installing it.

Before submission, verify these instructions against the uploaded build and provide the private App Review contact in App Store Connect.
