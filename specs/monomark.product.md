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

Recorded on 13 November 2026. The owner approved the product baseline and supplied further refinements.
Implementation started. See monomark.status.md for current evidence and remaining acceptance limits.
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

The owner confirmed one sidebar on the left. Its four tabs are Files, Contents, Links, and History.
The main area displays the active document tab. The app does not edit Markdown files.

| Area | Required behavior |
| --- | --- |
| Files | Show a folder tree of Markdown files when a folder is opened. Selecting a file changes the document. |
| Contents | Show nested headings and child entries for figures, tables, and other navigable objects. |
| Links | List embedded links and sources so the reader can navigate or copy them. |
| Link actions | Offer navigation and copying on hover. Open external links in the browser and local Markdown links in MonoMark. |
| Typography | Configure the monospace font and sizes for headings, body text, and other text elements. |
| Rendering | Support LaTeX-style math, Mermaid diagrams, highlighted code, emoji, images, and complex Markdown. |
| Platforms | Prioritize macOS. Preserve a path to comparable iPhone and iPad behavior. |
| Window modes | Support both a resizable window and full-screen reading on the window's current display, with switching between modes. |
| Keyboard and pointer | Provide deliberate shortcuts for opening, closing, printing, zooming, panning, scrolling, and navigation. |
| Reading state | Keep per-file reading positions and settings in the user's local application data. |
| Large documents | Optimize file access, parsing, rendering, and navigation for very large documents. |
| Document tabs | Use platform-appropriate document tabs to support navigation among files. |
| Local link previews | Show a bounded preamble or target-section preview for accessible linked Markdown documents. |
| History | Retain a searchable local record of every Markdown document viewed, ordered by most recent use. |
| Tables | Study Zed's table rendering and provide clear, theme-aware row and column differentiation. |
| Platform conventions | Use macOS, iOS, and iPadOS keyboard conventions. Do not invent conflicting shortcut mappings. |

## Proposed reading behavior

These details refine the approved baseline. Mechanisms described as provisional still require implementation evidence.

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

## Local reading state and history

Store reading positions, per-file preferences, and viewing history persistently within the user's local application data.
Use OS-provided directories under the user's home or app container, rather than a hardcoded home path.
On a nonsandboxed Mac, the proposed durable location is `~/Library/Application Support/MonoMark/`.
Use the sandbox-resolved Application Support directory on sandboxed Mac, iPhone, and iPad installations.
Keep disposable rendering data in the corresponding Caches directory. Never rely on purgeable caches for reading history or settings.
This distinction follows [Apple's file-system guidance](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively).
No sidecar file or modification to the Markdown document is required.

Each file record contains its identity, last known location, access bookmark where supported, first-viewed time, and last-viewed time.
Store the reading anchor, relative offset within that block, document-version information, zoom, and per-file display overrides.
Keep global defaults separate from per-file overrides. Preserve unmodified defaults when a file has no override.
Use filesystem or provider identity where available, with a path fallback and explicit handling for replacement at the same path.
Resolve bookmarks and access rights before reading. A history record never grants new filesystem permission.
Handle renamed, moved, replaced, removed, and provider-unavailable documents without silently assigning state to an unrelated file.

Restore a semantic anchor and its local offset when possible. Use a bounded relative-position fallback if the source changed.
Do not rely solely on a saved pixel offset, because fonts, window width, and deferred content change layout.
Save through coalesced background writes and flush at tab closure and normal lifecycle boundaries.
Use atomic updates or transactions, a versioned schema, and safe migration or recovery after interruption.
Coordinate updates across windows so an older inactive tab cannot overwrite a newer reading position.
The exact persistence engine remains provisional. Test its real transaction and recovery behavior before adoption.

The History sidebar tab shows the complete retained machine-local viewing history, newest first.
Provide search, filename and path disambiguation, and reopening at the saved reading position.
Retain small history records until the user explicitly forgets an entry or clears history.
Do not silently truncate history to a small recent-files limit or evict history when rendering caches fill.
Load history rows in pages instead of keeping all entries in memory.
Only actual document viewing records a visit. Folder scans and link previews do not create history entries.

Keep missing or inaccessible files visible with their availability state and an explicit relink or forget action.
Expose a native Open Recent menu backed by the same store. The menu may show a short list, while History retains all entries.
Clearing history removes its records, associated reading positions, and stored file access references without deleting source files.
Reset global preferences separately. Provide a separate action to clear disposable rendering caches.
Keep history local to this installation. Do not add account sync or upload file paths, previews, or document content.
Store no full document copies or preview excerpts persistently by default, and do not log file contents or history paths.
Protect metadata through platform file protections and app-private storage. Do not describe that storage as independently encrypted.

Validate restoration after relaunch, font changes, window resizing, source edits, renames, replacement, and permission loss.
Test interrupted writes, disk-full errors, schema migration, corrupt records, and simultaneous window updates.
If state cannot be saved, retain reading access and report the persistence failure without changing the source file.
Test a large history dataset, explicit forgetting, complete clearing, and cache eviction without history loss.

## Document tabs and link previews

Use native document tabs on Mac and an adaptive tab presentation on iPad and iPhone.
Document tabs are separate from the four sidebar tabs. Each document tab owns its location history, reading state, and zoom.
The sidebar always describes the active document tab. Tab labels disambiguate identical filenames from different folders.
Provide visible actions to open a link in the current tab or a new document tab.
By default, file selection and local-link navigation use the active tab, with backward navigation retained.
When explicitly opening a file in a new tab, reuse an existing tab for that file in the same window where practical.
Closing a tab retains its saved state and history entry. Closing the final tab follows the platform's document-window convention.
Restore tab metadata without eagerly loading every document, starting a renderer for every tab, or triggering provider downloads.
Release inactive renderers and large decoded resources under pressure. Reload them from saved state when needed.
Native Mac tabs may have separate window objects. Count active visible document surfaces, rather than window objects, when budgeting renderers.

Extend the link popover with a preview for an accessible local Markdown destination.
Show the destination title or filename and a bounded excerpt from its opening prose.
If a link targets a heading, prefer that section's opening text and identify the section.
Skip front matter and decorative or expensive content when selecting the excerpt.
Keep Open, Open in New Tab, and Copy actions available without requiring the preview to succeed.
Previewing does not change the active document, reading position, location history, or most-recently-viewed ordering.

Load previews only on deliberate hover, keyboard focus, or the touch preview action.
Limit input bytes, output length, concurrent tasks, and preview memory. Cancel work when the target changes or the popover closes.
Do not render Mermaid, execute document scripts, decode large images, or recursively preview links inside a preview.
Apply the same sanitization and folder-access rules as normal viewing.
Show an unavailable or permission-needed state for inaccessible destinations. Do not download cloud placeholders silently on hover.
External web links retain their destination and navigation actions. Fetching remote preview pages is outside this refinement.

## Window modes and multiple displays

Both window mode and single-display full-screen mode are required. Full screen applies only to the active document window.
Enter full screen on the display that currently contains that window, even when the pointer is on another display.
If the window spans displays, use the display containing the largest part of the window.
Do not span displays, blank other displays, create mirrored document windows, or change the modes of other MonoMark windows.
In an extended desktop, other displays must remain available for unrelated applications and windows.
System-mirrored displays share a desktop. MonoMark must not alter that system configuration.

Provide visible Enter Full Screen and Exit Full Screen commands in the View menu.
Keep an exit control discoverable when window chrome is hidden. Full-screen reading must retain access to the sidebar.
Switch modes without reopening the file or losing reading position, selection, zoom, or sidebar state.
On exit, restore the previous window size and position within the available display area.
If a display disconnects, recover the document on an available display and keep the exit command reachable.
Opening another file must not force window mode or full-screen mode on other windows.

Use native window behavior where it meets this contract.
Apple provides a per-window [full-screen toggle](https://developer.apple.com/documentation/appkit/nswindow/togglefullscreen(_:)).
Validate behavior under both settings for “Displays have separate Spaces,” as well as mirrored and extended display arrangements.
Do not change system display or Spaces settings to satisfy this requirement.
If native full screen cannot preserve other displays, evaluate a screen-limited presentation window as the fallback.
The mechanism remains provisional until multi-display testing proves the required behavior.

## Keyboard, scrolling, and panning contract

Keyboard access is required from the first prototype. Use the platform's commands, responder behavior, and menu equivalents.
The references are [Pages on Mac](https://support.apple.com/en-ae/guide/pages/tanc0ffef022/mac),
[Pages on iPhone and iPad](https://support.apple.com/en-ae/guide/pages-ipad/tan3b1ff7f35/ipados),
and [Apple's general Mac shortcuts](https://support.apple.com/en-us/102650).
Respect system customizations, keyboard layouts, accessibility navigation, and platform-reserved keys.

| Action | Mac convention | iPhone and iPad hardware keyboard |
| --- | --- | --- |
| Open | Command-O | Command-O opens the document picker. |
| Close active document tab or final window | Command-W | Use the native document or tab close command where supported. |
| Print | Command-P | Use the platform Print command and its supplied equivalent, where available. |
| Full screen | Control-Command-F | Use platform window controls. Do not impose the Mac binding. |
| View zoom in or out | Shift-Command-> or Shift-Command-<, as in Pages | The same Pages zoom commands. |
| Increase or decrease reading text size | Command-Plus or Command-Minus | The same Pages text-size commands. |
| Actual size | Command-0 | Expose the native action without assigning an unsupported shortcut. |
| Find | Command-F | Command-F. |
| Next or previous match | Command-G or Shift-Command-G | The same commands while Find owns the interaction. |
| Copy or select all | Command-C or Command-A | The same commands in the focused context. |
| Settings or quit | Native Command-Comma or Command-Q | Use platform settings and lifecycle conventions. |

View zoom and reading text size are different actions. Text-size changes preserve the configured heading hierarchy and source content.
Actual Size resets view zoom, not saved font preferences.
Open Folder, sidebar selection, location history, and tab management remain visible menu or control actions.
Use their native equivalents only when the selected platform supplies them. Do not assign custom number keys or other speculative mappings.
In particular, remove the earlier sidebar-number, custom folder-open, and location-history bindings from the proposed contract.

Escape performs the first applicable action in this order:

1. Cancel the active system dialog, sheet, or input composition through its native handling.
2. Dismiss the foremost temporary interaction, such as a context menu, link popover, or search bar.
3. Exit full-screen mode and retain the open document in its restored window.

This platform-convention refinement supersedes the earlier proposal that Escape closes an ordinary document window.
Use the native Close command for tab or window closure. Escape never quits the application or closes an ordinary reading tab.
One press must not dismiss a popover and also exit full screen. Ignore key repeat across Escape dismissal transitions.
After dismissing an interaction, restore focus to its invoking control or the document.

| Interaction | Required behavior |
| --- | --- |
| Vertical scrolling | Mouse wheel, trackpad, and Up or Down Arrow scroll the focused reading viewport. |
| Mac page scrolling | Page Up or Page Down, including Fn-Up Arrow or Fn-Down Arrow, scrolls without moving the text selection. |
| Mac document boundaries | Home or Fn-Left Arrow scrolls to the start. End or Fn-Right Arrow scrolls to the end. |
| Mac text navigation | Preserve native Command-arrow and Shift-modified selection commands in text contexts. Do not reinterpret them as global scrolling. |
| iPhone and iPad reading navigation | Follow Pages reading view: Command-Up or Command-Down reaches the document boundaries. Option-Up or Option-Down changes pages. |
| iPhone and iPad reading canvas | Command-Left or Command-Right moves horizontally when the reading canvas owns focus. Preserve text-field behavior. |
| Space scrolling | Preserve native reading-view behavior where supplied. Do not override a focused control or text field. |
| Horizontal panning | Two-axis trackpad gestures, horizontal wheel input, and Shift-wheel move wide tables, code, and diagrams. |
| Keyboard panning | Left or Right Arrow pans a focused overflow viewport. A wide object must be keyboard-focusable. |
| Sidebar navigation | Arrow keys move among entries or expand and collapse a tree. Return activates the selected target. |
| Focus navigation | Tab and Shift-Tab follow platform keyboard-navigation settings and retain visible focus. |
| Text selection | Dragging selects document text. Panning must not replace selection or require a drag-only gesture. |

Scrolling keys must respect focus. Space activates a focused button, and arrow keys edit text within a search field.
Text fields, menus, trees, and accessibility interactions must receive their normal keys before document scrolling handles them.
An event must trigger only one action across native controls and the rendered document.
Bound zoom and pan values. Keep small documents readable, and prevent movement beyond an object's usable viewport.
Avoid idle timers or continuous work merely to support keyboard handling, scrolling, or panning.
On iPhone and iPad, expose supported commands through native shortcut discovery and provide touch equivalents.
Recheck supported OS versions during implementation. Do not infer a mobile shortcut from the Mac table.

Printing uses rendered content and excludes application chrome, sidebars, hover controls, and error debugging details.
Complete required deferred local diagrams and images for the print layout, without silently loading blocked remote resources.
Use readable page breaks and handle wide content without clipping. Keep source files and on-screen zoom unchanged.
Canceling printing must retain the current document, reading position, and window mode.

## Window and input acceptance checks

These checks define future validation. No application currently exists to execute them.

- Switch repeatedly between window mode and full screen while retaining the document, reading anchor, zoom, and sidebar state.
- Enter full screen on either of two displays, including when the pointer is on the other display.
- On an extended desktop, keep other displays usable and other document windows unchanged under both Spaces settings.
- Recover from display disconnection, display scaling changes, and interrupted full-screen transitions.
- Verify Escape precedence in dialogs, search, link popovers, and full screen, without closing an ordinary tab or window.
- Verify that a held Escape key cannot cascade through several dismissal or window-mode actions.
- Open, navigate, search, copy, zoom, pan, print, and close through keyboard commands without duplicate actions.
- Preserve text-field editing, tree navigation, visible focus, VoiceOver interaction, and non-US keyboard access.
- Print long documents containing wide tables, highlighted code, local images, math, and deferred Mermaid diagrams.
- Test trackpads, a mouse wheel, a keyboard without dedicated page keys, and an iPad hardware keyboard.

## Very large documents

Optimize the whole path from file access to rendered navigation. Memory mapping alone does not bound parser or layout memory.
Evaluate [Foundation's mapped-if-safe reading](https://developer.apple.com/documentation/foundation/nsdata/readingoptions/mappedifsafe) for suitable local files.
The option is a hint, not a guarantee of mapping or zero-copy decoding.
Use mapping only when stable backing storage and safe lifetime handling can be established.
Handle external replacement or truncation, file-provider changes, and network or removable storage explicitly.
Fall back to coordinated, bounded reads when mapping is unsafe. Do not require mapping for correctness.

Avoid simultaneous full-size byte, decoded-text, HTML, and rendered-document copies.
Parse away from the UI thread and build a compact, source-aligned block index.
Evaluate a disk-backed index when retaining all index entries would exceed the memory budget.
Preserve block boundaries, open fences, nested structures, link definitions, and other document-wide Markdown semantics.
Do not split arbitrary byte or line chunks and parse each chunk as an independent document.

Render only a bounded region around the viewport and reclaim distant rendered blocks and decoded objects.
Load images, syntax grammars, math, and diagrams on demand. Reserve estimated layout space to limit scroll movement.
Prioritize visible content and explicit navigation targets over speculative work.
Cancel obsolete indexing, rendering, and search tasks when the active document changes.
Keep inactive tabs lightweight and cap concurrent work across previews, tabs, and windows.
Do not promise constant total memory merely because the visible view is virtualized.

Contents and Links indexes can populate progressively, with a clear indexing state and cancelable work.
Find must cover the entire document, including unloaded blocks, and report progress while indexing remains incomplete.
Jumping to a distant heading or the document end must not require rendering every intervening block.
Report progress when parsing context is still needed before a target can be resolved safely.
Preserve selection, copying, accessible reading order, and location history across unloaded regions.
Printing must cover the whole document through bounded pagination rather than materializing one enormous screen view.

Window or paginate very large tables without losing headers, alignment, selection, or copying across unloaded rows.
Bound individual code blocks, images, equations, and diagram complexity as well as total document size.
For an object beyond safe rendering limits, show an explicit readable fallback and its navigation target.
Keep the rest of the document usable. Do not silently remove objects from the outline.

Benchmark increasing file sizes, extremely long lines, many headings, large tables, mixed scripts, and heavy object counts.
Include repeated tab switching, distant jumps, complete-document search, printing, and externally changed files.
Record first readable content, complete indexing, target-jump latency, scrolling, peak and retained memory, CPU, and energy separately.
Memory measurements include the app, renderer processes, decoded resources, and resident mapped pages.
Freeze supported sizes and release thresholds after prototype evidence, before widening the supported workload.

## Table clarity and Zed reference

Reviewed Zed's Markdown renderer source on 13 November 2026 at commit `4fd48c02acb46500b832a3a90f89ceea4735f9f8`.
The [table-cell styling](https://github.com/zed-industries/zed/blob/4fd48c02acb46500b832a3a90f89ceea4735f9f8/crates/markdown/src/markdown.rs#L3157-L3200)
uses a title-bar background for headers, a panel background on alternating body rows, and themed horizontal and vertical borders.
This inspected path does not alternate column backgrounds. The observation comes from source review, not a visual test of Zed.

Use a distinct header, subtle alternating rows, clear cell boundaries, adequate padding, and Markdown column alignment in MonoMark.
Provide an optional alternating-column style for readers who need stronger column tracking.
Treat column banding as a MonoMark feature rather than a verified Zed behavior.
Choose row or column banding without stacking both into a distracting checkerboard.
Use semantic platform colors, sufficient text contrast, and borders so color is not the only way to distinguish cells.
Support light, dark, increased-contrast, and monochrome print appearances.
Keep long cells readable through wrapping and horizontal scrolling rather than clipping or shrinking all text.
Validate unequal column widths, inline code, links, math, tall rows, very wide tables, selection, and copying.
Banding follows logical row or column indices when rows are virtualized, rather than restarting at each rendered viewport.

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

Start with a native SwiftUI shell and a reusable WebKit document view for each active visible document surface.
Keep inactive document tabs as lightweight state. Prototype renderer reuse or release alongside native Mac tab behavior.
Keep file access, tab and sidebar state, navigation policy, durable reading state, settings, and lifecycle in native code.
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
| Complete history and reading-state recovery | Paged history access, restart restoration, crash recovery, and cache eviction without history loss. |
| Multiple tabs and local previews | Active-tab responsiveness, bounded inactive resources, preview cancellation, and unchanged visit history. |
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
4. Prototype rendering, large-document indexing, reading-state recovery, tabs, and local previews against representative and adversarial fixtures.
5. Measure fidelity, startup, switching, distant navigation, combined memory, idle CPU, table clarity, and platform keyboard behavior.
6. Select the rendering architecture and freeze performance thresholds from that evidence.
7. Implement the Mac viewer through failing tests, including window modes, native input, printing, persistent history, preferences, and file lifecycle.
8. Adapt the shared renderer and document logic to iPad and iPhone, and record any feature differences.

Mobile layout should adapt navigation rather than duplicate the desktop sidebar at a narrow width.
On iPad, retain the sidebar when space permits. On iPhone, show the four sidebar sections in a sheet or separate view.
Adapt document tabs separately from sidebar sections. Follow each platform's keyboard and document-navigation conventions.
Validate file-provider access, touch actions, accessibility, and memory on physical devices.
Mobile remains part of the product direction. A reduced feature set must be explicit rather than silently omitted.

## Unresolved decisions

- Minimum macOS, iOS, and iPadOS versions, plus Apple silicon and Intel support.
- Reference hardware, numerical performance limits, and maximum supported document sizes.
- Persistence engine, cache budgets, file-identity fallbacks, and precise checkpoint recovery guarantees.
- Mobile document-tab presentation and detailed bounds for link previews and individual complex objects.
- Exact math delimiters, caption syntax, footnote behavior, and supported emoji shortcode set.
- Confirmation of remote-image defaults and any additional embedded content types.
- Distribution method and release scope for the secondary mobile targets.

The first native implementation and renderer exist. Tests and acceptance limits are recorded in monomark.status.md.

## Artifact copying, appearance, and document comments

Provide icon-only copy actions with descriptive hover text and accessible names on tables, diagrams, equations, code, and images.
Copy table data as CSV, TSV, or pipe-separated values, with correct quoting for embedded separators and line breaks.
Copy diagram definitions, raw LaTeX, and literal code without converting source into rendered text.
Offer PNG for rendered diagrams, equations, and images. Bound image dimensions and keep the complete artifact in the image.
Provide explicit System, Light, and Dark modes for native controls and rendered content.
Hide HTML comments, including copyright metadata, while preserving comment syntax inside code fences.

The owner also authorized a subsequent annotations stage. Highlights, comments, and reading notes remain app-local unless explicitly exported.
Place comments and highlights in a right sidebar, with a second tab for plain-text or Markdown notes.
Export replaces a marked, auto-generated section. Ordinary reading and annotation edits do not modify the Markdown file.
Use “Export Notes and Annotations to This File” instead of Save. Provide Export a Copy as a distinct action.

## Palette customization

The owner requested configurable default colors for headings, captions, equations, callouts, table headers,
and table backgrounds, including alternate row and column colors.
Provide a palette with sensible light and dark presets, with System selecting the matching default appearance.
Preserve contrast and allow a reset to defaults. Keep reader overrides distinct from author-defined diagram colors.
Implemented through native named-swatch selectors with separate light/dark overrides and per-mode reset.
Presets include Default, Neutral, Ocean, and Forest. Text resolves to at least 4.5:1 contrast against selected surfaces.
Selections persist per document and can become application defaults. Reader colors do not rewrite diagram author colors.


## Reading controls from 14 November 2026

The left Files tree marks the open file and reveals its folder ancestors. The title bar shows the full copyable path.
Annotation panels provide Expand All, Collapse All, quote navigation, and search of quotations and comments.
New annotations start expanded. Reading notes provide separate search with previous and next matches.
Mac Find commands target notes when the notes editor or its search field has focus.
Typography selectors include installed system fonts. About includes version, build, revision, and copyright details.
Offline Help explains local storage, autosave, recovery, and explicit Markdown export.

Paper size choices are System, A4, US Letter, and US Legal. Document settings and application defaults retain the choice.
Pages shows separate estimated paper boxes. Pageless keeps continuous reading. Both show approximate page progress.
Pages preserves whole blocks and expands a sheet when an object exceeds one page. Print pagination can differ.
The renderer keeps the mounted document bounded in both modes. Paper changes do not modify global printer settings.


## Folder workspaces

Every opened folder is a workspace. A native sidebar menu switches recent workspaces and remembers each folder's last document.
Keep document tabs independent, so documents from several workspaces can remain open together.
Retain per-file reading positions, settings, notes, and annotations in their existing stores.
An empty workspace clears the prior document and disables note editing until a document opens.
If the last document is missing, select an available Markdown file or show the Files tree.
The recent menu shows up to 40 workspaces. Older records remain stored and become recent when their folder opens again.
Forget This Workspace removes only workspace metadata. It does not delete files or reading notes.
Use native granted bookmarks for folder access. A stored path does not grant access.
