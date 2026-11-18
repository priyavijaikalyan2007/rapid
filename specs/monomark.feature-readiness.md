<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: ba58d6de-9915-42d2-bc65-d58a1f8f758f -->
<!-- AGENT: Distinguishes implemented Mac behavior from incomplete acceptance and secondary-platform work. -->

# MonoMark feature readiness

The main Mac feature set is implemented. That statement does not mean every requested behavior passed release acceptance.
The owner selected a free Mac App Store release under Outcrop Inc, alongside a future direct-download build.
This matrix records the remaining distinctions before submission.

| Area | Implemented behavior | Remaining work or acceptance |
| --- | --- | --- |
| Reader navigation | Files/Contents/Links/History, native document tabs, workspaces, local link previews, and optional implicit references | Broader lifecycle, renamed/provider files, and multi-display acceptance (#11, #28) |
| Typography and appearance | Installed fonts, element sizes, separate light/dark palettes, and System mode | Broader actual OS appearance/accessibility checks (#18) |
| Rich Markdown | Tables, syntax highlighting, LaTeX, Mermaid, emoji, local images, and hidden HTML comments | Native resource budgets and large-document workloads (#14) |
| Artifact clipboard | Table formats, code/source text, equation/diagram/image PNG, plus content Copy | Obscured-window PNG behavior remains unverified (#17) |
| Highlights and comments | Local storage, quote jumps, colors, search, expansion controls, comment Paste | Wider selection and quote reattachment after external edits (#20) |
| Notes and exports | Local Markdown/plain Notes, search/Paste, inline/end-section export, separate reading-data files, section/line references | Signed source/provider grants and broader external-edit cases (#24) |
| Pages and printing | Paper sizes, estimated page progress, Pages/Pageless, and native print action | Large single tables and print fidelity (#15) |
| Reload and command line | Selectable auto-reload, manual Refresh, folder invocation, and multiple file arguments | Signed user-selected-file lifecycle coverage remains open (#11) |
| Window input | Standard Mac menus, shortcuts, independent windows, and native full screen | Physical multi-display acceptance (#28) |
| Secondary mobile app | Shared implementation and unsigned simulator/device builds | Physical iPhone/iPad testing, mobile icon, and platform-specific release preparation (#28) |
| Optional numbering | Existing author-written numbers and numbered-reference links | Automatic subsection numbering remains a proposal (#53) |

Logical selections now survive unloaded blocks. Native WebKit acceptance verifies 60 offscreen anchors and full-document clipboard text beyond 4 MiB without a full-document DOM. Highlights retain their separate bounded storage limits.
The reader caps source size at 100 MiB and individual rendered blocks at 1 MiB. Remote images remain blocked.
Printing constructs a separate view for up to 5,000 blocks. Estimated page counts can differ from printed output.
These limits must match the final help and store listing.

Current passing evidence includes 121 Core tests, 96 renderer tests, native clipboard/navigation checks, and actual artifact PNG pixels.
The [release issue](https://github.com/priyavijaikalyan2007/rapid/issues/65) tracks distribution separately from feature acceptance.
Mac App Store submission remains pending until its selected acceptance gates and account/material checks pass.
