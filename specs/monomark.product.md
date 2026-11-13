<!--
SPDX-FileCopyrightText: 2026 Priya Vijai Kalyan <priyavijai.kalyan2007@proton.me>
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 8ab87515-8655-40ca-a106-56deed7a5a35
Created: 2026
-->

<!-- AGENT: Captures MonoMark requirements and separates proposed design from verified implementation. -->

# MonoMark product brief

Recorded on 13 November 2026. Status: requirements captured, design proposed, implementation not started.
The owner selected MonoMark after considering MacDownMono. Name availability remains unverified.

## Product goal

MonoMark is a fast, read-only Markdown viewer centered on clear monospace text and document navigation.
macOS is the primary target. iOS and iPadOS are secondary targets, ideally using the same rendering features.
The owner permits a smaller mobile feature set when platform limits require it.
Speed, low memory use, low CPU use, and viewing clarity guide implementation choices.

The inspiration is [MonoReader](https://apps.microsoft.com/detail/9nhr7vv7zwkt?hl=en-US&gl=US).
The owner's description supplies the reference behavior. Automated access exposed only a JavaScript requirement.
No independent comparison of MonoReader's interface or performance is claimed.

## Confirmed requirements

The owner confirmed one sidebar on the left. Its three tabs are Files, Contents, and Links.
The main area displays one rendered document. The app does not edit Markdown files.

| Area | Required behavior |
| --- | --- |
| Files | Show a folder tree of Markdown files when a folder is opened. Selecting a file changes the document. |
| Contents | Show nested headings and child entries for figures, tables, and other navigable objects. |
| Links | List embedded links and sources so the reader can navigate or copy them. |
| Link actions | Offer navigation and copying on hover. Open external links in the browser and local Markdown links in MonoMark. |
| Typography | Configure the monospace font and sizes for headings, body text, and other text elements. |
| Rendering | Support LaTeX-style math, Mermaid diagrams, highlighted code, emoji, images, and complex Markdown. |
| Platforms | Prioritize macOS. Preserve a path to comparable iPhone and iPad behavior. |

## Proposed reading behavior

These details refine the requirements. They remain proposals until reviewed or validated through implementation.

Open a file or folder through native dialogs, Finder, or drag and drop.
Opening one file must not require folder access. Request folder access when related files need that permission.
Keep the sidebar collapsible and resizable. Retain the selected tab, file, and reading position during navigation.
Provide document search, text selection, copying, zoom, and backward and forward navigation.
Use native controls and system appearance for application chrome.
Task lists remain read-only. Selection and copying must never modify the source file.

The Files tab shows Markdown files and their folder hierarchy, including folders needed to reach those files.
Proposed extensions are `.md` and `.markdown`, matched without case sensitivity.
Enumerate folders asynchronously without rendering every file or parsing the entire folder on open.
Avoid symlink cycles. Do not follow links outside the granted folder without additional access.
Observe external file changes without frequent polling. Refresh the document while preserving its reading position when possible.
Handle moved, deleted, unavailable, and partially written files without replacing readable content with a blank view.

The Contents tab nests headings by level. Objects belong under their nearest preceding containing heading.
Objects before the first heading belong at the root. Preserve source order among siblings.
Include block images, Mermaid diagrams, tables, and display equations. Exclude inline emoji and decorative inline images.
Use an explicit caption or title when available, then image alternative text where appropriate.
Use stable fallback labels such as “Figure 2,” “Table 3,” and “Equation 1” when no label exists.
Do not infer captions from arbitrary adjacent paragraphs. Document supported caption syntax before adding it.
Each entry must target the rendered object, even when headings repeat or images load later.

The Links tab lists destinations from the current document, including inline links, reference links, autolinks, and image sources.
Show the label, destination, type, and location in the document. Group repeated destinations but retain their individual occurrences.
Do not fetch destination pages to build this list.
Offer “Copy link” and “Copy resolved address” when a relative target has a different resolved address.
Use the same destination rules in the document, sidebar, and context menus.

| Destination | Proposed action |
| --- | --- |
| Current-document fragment | Scroll to the target within the current document. |
| Local Markdown file, optionally with a fragment | Open the file in MonoMark, then navigate to the fragment. |
| HTTP or HTTPS address | Open the system browser after the user selects navigation. |
| Other local file or supported system scheme | Use an explicit platform action after validating the destination and access. |
| Missing, denied, or unsafe destination | Explain the failure and retain the current document. |

Resolve local paths relative to the current file. Decode and normalize paths before checking folder access.
Check symlink destinations as well as textual paths. Never treat an external web page as a trusted local document.
Hover exposes a small action popover on Mac. Keyboard focus and context menus expose equivalent actions.
On touch devices, use a long-press menu. Hover must not be the only way to reach an action.

## Typography and Markdown compatibility

Use a system monospace font by default. Allow a global font choice and overrides for headings, body, code, and tables.
Support sizes for heading levels one through six, body text, code, tables, and captions.
Include line spacing, document width, and a reset action. Font changes must preserve the reading position.
Use system fallback fonts for emoji and missing characters.
Math needs mathematical typesetting fonts. Preserve the selected monospace font for surrounding prose and code.
Configure diagram label fonts where the renderer supports them, and test clipping after a font change.

Propose CommonMark plus GitHub Flavored Markdown as the baseline, including tables, strikethrough, and read-only task lists.
Math, Mermaid, footnotes, and emoji shortcodes need explicit extension contracts and compatibility fixtures.
Do not promise every Markdown dialect or a complete LaTeX engine.
KaTeX is a candidate for mathematical expressions. Its [supported functions](https://katex.org/docs/supported.html) define a bounded subset.
Its [output options](https://katex.org/docs/options.html) include visual HTML plus MathML for accessibility.
Recognize Unicode emoji directly. A bundled shortcode mapping can support forms such as `:smile:` outside literal code.
Unsupported code languages remain readable without highlighting. Invalid math and diagrams show local errors without blocking the document.

## Proposed architecture and main tradeoff

Start the feasibility work with a native SwiftUI shell and one reusable WebKit document view per window.
Keep file access, sidebar state, navigation policy, settings, and lifecycle in native code.
Bundle renderer code, styles, fonts, and required resources for offline use.
Load math, Mermaid, and code-language support only when the document needs them.
No server, account, cloud rendering, or runtime CDN dependency is needed.

This is a provisional recommendation, not a measured claim about speed or memory.
WebKit offers an integration path for the requested rendering libraries but adds web-process and layout costs.
A native text renderer may reduce those costs, but complex tables, selection, math, and diagram integration need more custom work.
The feasibility prototype must measure resource use before the rendering architecture becomes an accepted decision.
Include relevant WebKit helper processes in memory and CPU measurements.

Derive the rendered document, outline, and link index from one authoritative parse result.
Use source locations and stable identifiers so the sidebars cannot disagree with rendered navigation targets.
Cancel obsolete work when the reader switches files. Reject late results from older document generations.
Bound parsed-document caches, decoded images, generated diagrams, and temporary buffers.
Avoid one hidden web view per file. Preserve layout space for deferred images and diagrams to limit scroll movement.

Use a small Adapter boundary for WebKit and platform file access because these APIs differ from shared document logic.
Use direct typed models and functions for outline and link rules. No additional pattern hierarchy is required.
Keep parsing and navigation policy testable without application views.

## Document trust and privacy

Treat every document as untrusted. Execute only bundled application scripts, never scripts supplied by the document.
Sanitize supported HTML and generated rich content without removing required math or diagram semantics.
Validate native bridge messages and expose only narrow document-navigation commands.
Restrict file reads to user-granted locations. Do not grant broad filesystem access to a web view.
Apply a restrictive content security policy and intercept navigation and subresource requests.

Propose remote images blocked by default, with a document-level action to load them.
Local images render within granted access. Remote content must not make an offline document unusable.
Reject active embedded content and unsafe URL schemes. Bound embedded image sizes and diagram or macro expansion work.
Use Mermaid's [strict security setting](https://mermaid.js.org/config/usage) and prevent document overrides from weakening application policy.
Keep KaTeX trust disabled and apply its [size and expansion limits](https://katex.org/docs/security).
These settings supplement content isolation and sanitization. They do not replace those controls.

## Performance acceptance proposal

Choose the minimum OS versions, Mac architectures, and reference devices before setting numerical release limits.
Do not inherit Composure's hardware or OS constraints for this separate app.
Set measurable thresholds after the first baseline and before production implementation expands.
Record Release configuration, hardware, OS, corpus hashes, cache state, trial counts, and measurement definitions.

| Workload | Required evidence |
| --- | --- |
| Cold launch and first small document | Time to readable text and time to full rendering. |
| Switching previously opened documents | Median and tail latency, including sidebar synchronization. |
| Large text and folder trees | UI responsiveness, indexing cost, cancellation, and peak memory. |
| Math, code, images, and Mermaid | First rendering time, scroll stability, and failure isolation. |
| Repeated file switches and window closure | Retained memory, cache bounds, and released access or observers. |
| Idle foreground and background | CPU and energy use across the app and renderer processes. |

Use separate small, large, and complex fixture groups. Include malformed and adversarial documents.
Define supported document and object limits. Provide a clear fallback when a document exceeds them.
Do not hide slow diagram completion behind a fast plain-text measurement.

## Delivery sequence

1. Confirm platform floors, supported Mac architectures, reference devices, and the initial compatibility corpus.
2. Record the planned app component in `PROJECT_PROFILE.md` and update project facts before source work.
3. Define the prototype file list, interfaces, and failing acceptance tests before implementation.
4. Build a bounded rendering prototype that covers text, math, tables, code, Mermaid, and images.
5. Measure fidelity, startup, switching, combined process memory, idle CPU, and scroll behavior.
6. Select the rendering architecture and freeze performance thresholds from that evidence.
7. Implement the Mac viewer, folder navigation, object outline, links, preferences, and file lifecycle through failing tests.
8. Adapt the shared renderer and document logic to iPad and iPhone, and record any feature differences.

Mobile layout should adapt navigation rather than duplicate the desktop sidebar at a narrow width.
On iPad, retain the sidebar when space permits. On iPhone, show the three navigation tabs in a sheet or separate view.
Validate file-provider access, touch actions, accessibility, and memory on physical devices.
Mobile remains part of the product direction. A reduced feature set must be explicit rather than silently omitted.

## Unresolved decisions

- Minimum macOS, iOS, and iPadOS versions, plus Apple silicon and Intel support.
- Reference hardware, numerical performance limits, and maximum supported document sizes.
- Exact math delimiters, caption syntax, footnote behavior, and supported emoji shortcode set.
- Confirmation of remote-image defaults and any additional embedded content types.
- Distribution method and release scope for the secondary mobile targets.

No application source, Xcode project, dependencies, or validated rendering prototype exists for MonoMark yet.
