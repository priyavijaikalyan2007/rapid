<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 92c14d75-d82f-4ba9-8ce5-b6fe887be0e7
Created: 2026
-->
<!-- AGENT: Local development, implemented features, platform requirements, and verification boundaries. -->

# Monoleaf

Monoleaf is a local Markdown reader for macOS 15 or later and iOS/iPadOS 18 or later.
The Mac product supports Apple silicon and Intel. Mobile uses the same core and offline renderer.
The app does not provide a Markdown source editor.

The reader includes native document tabs, Files/Contents/Links/History navigation, durable reading positions,
per-document typography, local link previews, diagram and math rendering, syntax highlighting, emoji, and table styles.
Artifact icons copy source text, CSV/TSV/pipe-separated table data, or rendered PNG images where appropriate.
Opening a folder creates a workspace. The menu above Files switches among the 40 most recent workspaces.
Switching resumes the last available document or displays an empty Files tree. Existing tabs keep their own workspace.
Forget This Workspace removes its menu record and keeps files, history, highlights, and notes.
Workspace records and granted folder bookmarks live in a separate local SQLite database.
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
Open `build/DerivedData/Build/Products/Release/Monoleaf.app` after a Mac build.
Internal project and scheme names remain unchanged. Use `apple/MonoMark.xcodeproj` and the MonoMark or MonoMarkMobile scheme in Xcode.
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
Printing supports up to 5,000 blocks, 16 MiB of rendered HTML, and 100,000 rendered elements.
The element count includes expanded equations and diagrams. Each block must fit the 1 MiB rendered-object limit.
A larger job reports its limit instead of printing incomplete content.
AppKit completion restores the reading view after printing or cancellation.

Large tables split at complete rows, with at most 64 rows and a 2,048-cell target per group. A single row stays intact. Tables above 1,024 columns report an explicit limit. Continuation groups repeat the header and share column widths. Copy controls export the entire table, including unloaded rows.
Selections retain logical positions across unloaded content.
PNG copies wait for local image decoding and fit the full artifact into the available viewport.
Large objects may produce reduced-resolution images. Native acceptance verifies copied math, image pixels, and diagrams.

The first implementation does not establish release performance on an untested reference machine.
Multi-display behavior and physical mobile devices need direct acceptance tests.
Selections span unloaded blocks without mounting them. Clipboard text has a 128 MiB UTF-8 limit. Highlights retain at most 128 anchors and 16,000 UTF-16 units per quoted block.
Reading notes support up to 1 MiB of UTF-8 text. Unattached quotations remain visible in the inspector.
Quote reattachment across extensive external edits needs further acceptance work.
Settings > Customize Colors edits separate light and dark palettes for headings, captions, equations, block quotes, and tables.
Eight named swatches and Default/Neutral/Ocean/Forest presets keep choices bounded and readable.
Reset affects only the selected palette. Use as Defaults also retains palette choices for new documents.
Reader text colors use at least 4.5:1 contrast against their selected surfaces. Diagram colors and syntax tokens remain separate.

See the [product specification](../../../specs/monomark.product.md),
[implementation plan](../../../specs/monomark.implementation.md), and
[current status](../../../specs/monomark.status.md) for evidence and remaining work.


The isolated native artifact test uses a generated local fixture and a separate pasteboard:

```sh
./build/DerivedData/Build/Products/Release/Monoleaf.app/Contents/MacOS/Monoleaf --smoke-test /tmp/monomark-artifacts.json --artifact-smoke
```

Run this command from the component folder after a Mac build. A zero exit code and passed report indicate successful checks.
The test does not replace the user's clipboard or read private documents.

## Reload and command-line opening

Settings includes Automatically reload changed files. The default is on. Direct writes and atomic editor
replacements are coalesced. When the option is off, a notice marks external changes. Refresh reads the latest
content without replacing local notes. Reading position remains attached to the current document.

On Mac, choose File > Install Command Line Tool and select a directory on your shell's PATH. The command is
a symlink into Monoleaf.app, so keep the app at that location. Existing unrelated files are not replaced.
Use `monoleaf .` or `monoleaf ..` to open a folder workspace. Use `monoleaf first.md second.md` to open files
in separate native tabs. Quote paths that contain spaces. `monoleaf --dry-run <paths>` prints the resolved launch.
The launcher validates every path before opening anything and accepts at most 100 file arguments.

Annotation exports include section paths and source-line ranges when the quotation resolves. A SHA-256
stamp verifies that the source still matches the displayed document before a coordinated export write.
If the source changed, refresh and retry. Missing locations stay absent rather than receiving guessed line numbers.

## Inline and selective exports

Choose File > Export Reading Data on Mac, or Document Actions > Export Reading Data on mobile.
Select annotations, notes, or both. Choose an annotated document copy or a separate reading-data file.
Mac also offers the current Markdown file. Mobile exports copies through its file exporter.

For document output, choose a section at the end or inline annotations after highlighted blocks.
Inline annotations follow the last complete block in each selection. They do not split paragraphs, tables, lists,
or code fences. Notes appear at the end. Section paths and line references identify the source text.
Inline references account for inserted generated lines. Repeated exports replace validated marked sections.

Reading data remains in the app. The export does not clear local comments or notes.
Missing or stale inline locations stop the export before a write. Refresh and check the quotation, then retry.
A separate reading-data file cannot replace the source through a file alias. Notes-only output remains available
when the original file has disappeared. Existing direct end-section and Export a Copy actions remain available.
Generated reading sections display normally but do not become new annotation targets.

## Optional reference links

Settings > Navigation offers Markdown file references and numbered section references. Both default to off.
Open a folder to resolve unique `.md` or `.markdown` filenames and relative paths, including inline-code filenames.
File references open new tabs. Refresh updates the shared folder index. The index reads paths, not document contents.
Ambiguous, missing, and escaping references stay unchanged. Numbered references such as `§9`, `#9.1`, and `$9`
jump only when one numbered heading matches. Authored links, code blocks, and math remain unchanged.
These links affect the view only. Monoleaf does not rewrite the Markdown source.

Use the standard Copy command on selected document text. Comments and Notes accept the standard Paste command.

## Clean rebuilds

Run `./clean.sh` from this component to remove generated products and test caches before rebuilding.
It removes build/, .build/, DerivedData, and renderer cache, coverage and test-result directories.
It preserves source, installed renderer dependencies, SwiftPM configuration and app reading data.
Help and unsupported arguments do not delete files. Linked or unexpected output paths stop cleanup before deletion.

Preserved release exports and listing files live under local/release-artifacts/monoleaf at the repository root.
The uploaded build 107 archive remains in its isolated release worktree. Component cleanup does not visit those paths.
Run `./build.sh all` to rebuild and verify the renderer, Core, universal Mac and mobile targets.
