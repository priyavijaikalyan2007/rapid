<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: bf8b5361-8d37-4cba-bc3a-23cd5947e490 -->
<!-- AGENT: MonoMark local release checks, evidence, and unresolved gates. -->

# MonoMark release checks

The owner authorized release checks on 17 November 2026. Local checks and an unsigned trial package are in scope.
The owner first selected the Mac App Store, then requested both App Store and downloadable builds.
Both routes can share source, sandbox behavior, and features. They require separate signing and distribution checks.
Uploads and publication remain separate release actions.

## Reading-state recovery plan

External atomic replacement changes filesystem identity. The current history lookup uses only identity.
An existing path can then lose preferences and position or acquire duplicate history rows.
Keep identity as the first lookup, then recover the latest metadata for the authorized document path.
The path fallback grants no access. The caller resolves access before lookup.

Modify Core/HistoryStore.swift, Shared/ReaderSession.swift, and Tests/HistoryStoreTests.swift.
Extend `state(id:path:)` with an optional path. Keep existing callers compatible.
Record one latest row per path in a SQLite transaction. Reject older checkpoints before deleting duplicates.
Test replacement, path recovery, renamed files, stale windows, reopen, and unrelated paths before implementation.
No pattern required - the existing store and simple query helpers suffice.

## Common checks

- Verify all unsigned platform builds and regression tests.
- Verify native content Copy, comment Paste, Notes Paste, navigation, and artifact copies.
- Audit runtime dependencies and packaged resources, license, privacy manifest, architecture, and source revision.
- Measure synthetic parser costs without claiming native or reference-device performance acceptance.
- Keep unexecuted device, display, provider, and signed-distribution gates open.

## Privacy manifest plan and source basis

Add Shared/PrivacyInfo.xcprivacy to both native targets' resource phases.
Add test/test_monomark_release.py to verify declaration values and actual target membership.
Tests first reproduced the absent manifest and missing membership for both targets.
Declare app-only preferences (CA92.1), user-selected file metadata (3B52.1), and app-owned file metadata (C617.1).
Declare no tracking domains or developer data collection. Files and reading data remain local.
No pattern required - a shared resource and bundle contract checks suffice.

Reason definitions were checked against [Apple's required-reason API documentation](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
The [distribution guide](https://developer.apple.com/macos/distribution) describes both channels.
Direct builds need [Developer ID signing and notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Signed sandbox finding

A local Developer ID QA copy used the app sandbox and hardened runtime. Signature verification passed.
Its first run failed to start WebKit helpers. System logs specifically reported missing network permission.
The Mac entitlement now permits WebKit's outgoing client helper. The renderer still accepts bundled resources only.
The release contract checks the entitlement alongside the strict script, connection, and image content policies.
The same signed synthetic review harness then exited successfully. Its container report could not be read because
the host denied access. This result establishes the harness outcome, not full signed-provider acceptance.

The failure also exposed unlimited renderer restarts. A tested recovery policy now permits two retries in 60 seconds.
Further failures stop automatic retries and offer Refresh. Explicit Refresh resets the budget and reloads the reader.
The unsigned platform builds and Core recovery tests verify the new policy. Native failure/retry UI acceptance remains open.

## Distribution gates

The local keychain contains Apple Distribution and Developer ID identities for Outcrop.
The isolated QA signature uses no secure timestamp and is not a distributable download.
MonoMark still needs its team/provisioning setup, an App Store record, screenshots, listing metadata, and verified public
support/privacy pages. No store record, agreement, credential, upload, notarization submission, or release was changed.
The new Mac icon is documented in [the icon brief](monomark.icon.md).

Large-document native resource budgets, cross-viewport selection, large-table printing, provider grants, obscured PNG
capture, multiple displays, and physical mobile acceptance remain open in the linked tracker.
The 10 MiB synthetic Node benchmark indexed 30,979 blocks in 527 ms and found its final search target in 14 ms.
Node RSS reached about 258 MiB. These figures come from the 64 GiB development host and exclude native/WebKit memory.
They do not satisfy the native performance release gate.

## Trial package checkpoint

The refreshed unsigned trial ZIP uses committed source a37978c1e9f2 and includes the compiled Mac icon and privacy manifest.
It supports macOS 15 or later on Apple silicon and Intel. The archive contains 5,957,866 bytes.
ZIP integrity, exact renderer resources, license, launcher executable permission, architecture, and revision checks pass.
The [package record](monomark.package.json) contains its SHA-256 checksum.
The [final artifact test](monomark.final-artifact-smoke.json) verifies actual equation, image, and diagram PNG pixels
through an isolated pasteboard. It also verifies cancellation after document replacement and unchanged fixture source.
This package has no distribution signature or notarization and remains a local trial artifact.


## Bounded tables and native print acceptance

The [current native evidence](monomark.table-print-smoke.json) verifies bounded viewing of 20,000 rows and exact whole-table clipboard text. A 240-row fixture prints to 12 PDF pages. PDF text contains every row. First, middle, and final pages were rendered and inspected. The source stays unchanged, and the reading view returns afterward. Physical printer and arbitrary paper acceptance remains separate.

A synchronous test without panels first produced an excessive temporary PDF. WebKit computes print page ranges asynchronously. The native test and application now retain the print DOM until AppKit's completion callback. This follows Apple's [print operation contract](https://developer.apple.com/documentation/appkit/nsprintoperation) and the asynchronous pagination behavior in [WebKit's printing view](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/mac/WKPrintingView.mm). The failed temporary PDF was removed.

Print jobs reject more than 5,000 blocks, 16 MiB of rendered HTML, or 100,000 rendered elements. Individual blocks retain the 1 MiB rendered-object limit. Unsupported jobs report their limit rather than print incomplete content. Worker replies carry generation tokens, and cancelled jobs cannot replace the current document.


## External-edit and automation checkpoint

The [native reattachment report](monomark.reattachment-smoke.json) verifies full-index quote recovery past 600 inserted paragraphs. Navigation and export use the current section and line. Duplicate and deleted quotes remain unattached. This closes #20, including ambiguity across unloaded blocks. The original saved anchor remains unchanged. Recovery reuses canonical worker text and caps its quote cache at 256 entries.

The native/browser automation host was retried and remains unavailable. The native pipe failed to start, and the browser host returned unavailable. This prevents interactive acceptance and store screenshots through the supported automation surface. Provider grants, accessibility/focus, physical displays/devices, reference-machine resource budgets, and signed distribution remain separate open gates. Existing signed archive/export evidence still concerns the earlier 0.1.0 build. It does not establish a signed 1.0.0 release.


## Lifecycle checkpoint on 18 November

The [native lifecycle report](monomark.lifecycle-smoke.json) passes tab restoration, renderer release/reactivation, Find focus, duplicate filenames, reload choices, rename/deletion recovery, and workspaces. Regression fixes preserve drafts after replacement/rename and prevent stale history writes after deletion. The new history migration preserves old records and rejects future schemas. Current Core coverage is 94.43%, with 136 Core and 137 renderer tests passing. Signed provider grants, physical displays, performance budgets, appearance/accessibility, and distribution checks remain separate.


## Native diagnostics and performance checkpoint on 18 November

The [native performance report](monomark.native-performance.json) records actual WebKit workloads on the 64 GiB M5 Pro. Both mixed 1 MiB and 10 MiB documents render math, Mermaid, syntax highlighting, and a local image. Full-index search and distant navigation pass. Source hashes remain unchanged. The sampler keeps the main process separate from an explicit main-plus-all-WebKit upper bound. Other applications contribute to that upper bound. These development-host results do not establish slower-machine or calibrated energy acceptance.

The 1 MiB workload reached a captured frame in about 0.2 seconds. The 10 MiB workload took about 1.2 seconds. The main process peaked at about 92 MB and 130 MB, respectively. These app-only figures exclude WebKit. Idle main-process CPU measured 0–0.4% of one core across five-second samples. The report retains complete timings, combined upper bounds, and sampling limits. A process-exit counter regression and stream-phase regression were corrected before accepting the sampler result.

The new `--smoke-test -` output keeps images in app-owned temporary storage and sends JSON through stdout. The [signed artifact report](monomark.signed-artifact-smoke.json) passes visible/hidden PNG pixels, clipboard round trips, copy ordering, and source preservation. It uses a separate sandboxed Developer ID QA copy without a secure timestamp. The combined signed review still needs investigation. It must not be counted as passing from artifact-only evidence.

The 1.0.0 build 84 archive from clean revision be10919 passes signature and matching-symbol checks. After the owner signed into Xcode, local export reached Apple's membership service. Apple now requires acceptance of the latest Program License Agreement before it can create the missing Mac App Store profile. No upload, notarization submission, or App Review submission occurred.

The development-signed UI app and runner now share Outcrop's Team ID. The former mismatch is no longer the observed blocker. The runner stalls before main during app-sandbox initialization, so no UI cases executed. The supported native/browser automation host was retried and remains unavailable. Real provider panels, VoiceOver, store screenshots, physical multi-display cases, and slower-machine resource acceptance remain open. Current passing suites contain 138 Core and 138 renderer tests. Repository checks and source style checks pass.


## Signed distribution and presentation checkpoint

The signed combined review and signed lifecycle checks now pass. The [review report](monomark.signed-review-smoke.json) covers annotations, exports, implicit links, long selections, large tables, and PDF output. The [lifecycle report](monomark.signed-lifecycle-smoke.json) covers tabs, reload, source replacement, rename/deletion recovery, workspaces, and Find focus. Real external file/provider grants remain separate.

Both local distribution routes succeed for the clean 1.0.0 build 84 preflight. The [distribution record](monomark.distribution-preflight.json) records its source revision, package checksum, architectures, and signing checks. The App Store installer uses Outcrop's installer certificate. The downloadable app uses Developer ID, hardened runtime, and a secure timestamp. It is not notarized. Neither route was uploaded or submitted. The final candidate must include the next verified diagnostics checkpoint.

The [presentation report](monomark.presentation-smoke.json) passes native Light/Dark chrome, rich Markdown colors, System-mode propagation through app-local AppKit appearance changes, mode retention after reload, enlarged type, document landmarks, named/focusable artifact actions, and reversible single-display presentation. Native captures are actual 2560 × 1600 RGB compositor images of the test app's own window. The earlier view-cache capture omitted compositor effects and falsely showed dark file labels. All proposed UI workarounds were removed. The supported currentProcess capture requires no general Screen Recording grant.

Four actual-window screenshot drafts now show reading, rich content in Dark mode, comments, and Notes using synthetic documents. Source bytes remain unchanged. The runtime dependency audit reports zero known vulnerabilities. The unsupported in-process SwiftUI accessibility probe does not establish VoiceOver acceptance. The [manual release checks](monomark.manual-release-checks.md) retain real provider dialogs, VoiceOver, physical multi-display behavior, reference-machine resources, and final store-account review. Physical mobile checks remain outside the first Mac submission.
