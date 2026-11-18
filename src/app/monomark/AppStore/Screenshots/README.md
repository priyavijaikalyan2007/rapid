<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: 3e730bce-733e-4c6e-8f1b-a4366eb3184a -->
<!-- AGENT: Actual-window Mac store screenshot drafts and capture provenance. -->

# Mac screenshot drafts

These four images show the actual MonoMark window. The source documents and reading data are synthetic.
The compositor capture includes native window chrome, navigation, rendered content, and the right inspector.
All images are 2560 × 1600 RGB PNGs without an alpha channel. The manifest records their checksums and source checkpoint.
The current host enables Increase Contrast and Reduce Motion. The screenshots preserve that native appearance.

1. 01-reader.png shows the Files tree and rendered document.
2. 02-rich-dark.png shows highlighted C#, LaTeX, and Mermaid in Dark mode.
3. 03-comments.png shows Contents, a saved highlight, and its separate comment.
4. 04-notes.png shows app-local Markdown reading notes beside the document.

The images were visually inspected. Review them against the final candidate before uploading. No images were uploaded.
The generic temporary document path is part of the actual title bar. No private user path or document is present.

To regenerate, run the built app with `--smoke-test OUTPUT --store-screenshots --screenshots-input FOLDER`.
Use AppStore/Fixtures as FOLDER and a writable ignored build path as OUTPUT.
The test copies the example files into its temporary workspace and verifies that their bytes stay unchanged.
ScreenCaptureKit currentProcess restricts capture to this process's available content. The test selects its own NSWindow ID.
No general Screen Recording permission is requested.
