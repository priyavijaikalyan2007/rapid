<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 92c14d75-d82f-4ba9-8ce5-b6fe887be0e7
Created: 2026
-->
<!-- AGENT: Local development, implemented features, platform requirements, and verification boundaries. -->

# MonoMark

MonoMark is a local Markdown reader for macOS 15 or later and iOS/iPadOS 18 or later.
The Mac product supports Apple silicon and Intel. Mobile uses the same core and offline renderer.
The app does not provide a Markdown source editor.

The reader includes native document tabs, Files/Contents/Links/History navigation, durable reading positions,
per-document typography, local link previews, diagram and math rendering, syntax highlighting, emoji, and table styles.
Artifact icons copy source text, CSV/TSV/pipe-separated table data, or rendered PNG images where appropriate.
Settings offers System, Light, and Dark modes. Mac presentation fills only the active window's display.
The right inspector provides colored highlights, quote comments, and Markdown or plain-text reading notes.
Annotation panels support expansion, collapse, quote jumps, and search. Notes provide separate search with standard Mac Find commands.
Font selectors include installed system families. About shows version/build/revision details, and Help works offline.
Reading Layout switches between Pages and Pageless. Settings offers System, A4, US Letter, and US Legal paper sizes.
The status bar shows estimated current and total pages. Use as Defaults applies these settings to new documents.
Pages keeps whole blocks inside separate paper boxes and expands sheets for oversized objects.
Page counts change with width, fonts, and measured content. Printed page breaks can differ.
Mac printing uses a private copy of printer settings. Mobile chooses the nearest paper supported by the printer.
These records save locally. The reader does not change the source file during reading or note editing.

On Mac, use File > Export Notes and Annotations to This File for explicit source export.
Export replaces one marked generated section and preserves surrounding content. File > Export a Copy preserves the original.
Saved read-only access may require the system destination picker before the first source export.
On iPhone and iPad, Document Actions provides Export a Copy and Print.

## Build and run

Install the locked renderer dependencies:

```sh
npm ci --prefix src/app/monomark/renderer --ignore-scripts
```

Build and test both platform targets without distribution signing:

```sh
./src/app/monomark/build.sh all
```

Use `test`, `macos`, or `ios` to select a narrower build.
Open `build/DerivedData/Build/Products/Release/MonoMark.app` after a Mac build.
Use `apple/MonoMark.xcodeproj` and the MonoMark or MonoMarkMobile scheme in Xcode.
A signed mobile-device installation requires your development team and normal Apple provisioning.
These commands do not upload, publish, notarize, or submit an application.

## Implementation

A background worker parses document-wide references and creates source-aligned block, heading, object, and link indexes.
Inline token graphs are released after each block renders. The WebKit document mounts a bounded viewport rather than a full-document DOM.
Expensive renderer libraries load on demand from bundled assets. No rendering service or runtime CDN is required.
Mutable files use coordinated bounded reads rather than unsafe long-lived memory mappings.

Reading history and per-file state live in the platform's Application Support directory under MonoMark.
SQLite stores small records and pages the history list. The complete history has no automatic recent-file truncation.
Normal Mac document tabs restore their saved metadata, and inactive tabs can release their renderer.
Security-scoped bookmarks preserve authorized document access. A stored path alone does not grant access to another file.
Annotations use a separate versioned SQLite database, so clearing reading history does not remove notes.
Note writes are coalesced and flushed before document changes, tab closure, and normal Mac termination.
Conflicting updates preserve the visible draft and offer explicit retry or reload controls.

## Current limits

The source limit is 100 MiB. A rendered block larger than 1 MiB receives an explicit fallback.
Code highlighting is bounded to 100,000 characters per block. Mermaid and math source are bounded to 16,384 characters.
Local raster images are supported within granted access, with a 20 MiB encoded-file limit.
Remote image requests are blocked. The Links tab can open their sources in the browser.
Printing currently supports up to 5,000 blocks and constructs a separate print view.
Cross-viewport text selection and very large single tables still need further native acceptance work.
PNG copies fit the full artifact into the available viewport, so large objects may produce reduced-resolution images.

The first implementation does not establish release performance on an untested reference machine.
Multi-display behavior and physical mobile devices need direct acceptance tests.
Selections are limited to mounted blocks, with at most 128 anchors and 16,000 UTF-16 units per quoted block.
Reading notes support up to 1 MiB of UTF-8 text. Unattached quotations remain visible in the inspector.
Quote reattachment across extensive external edits needs further acceptance work.
Palette customization remains planned in the issue tracker.

See the [product specification](../../../specs/monomark.product.md),
[implementation plan](../../../specs/monomark.implementation.md), and
[current status](../../../specs/monomark.status.md) for evidence and remaining work.
