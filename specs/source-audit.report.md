<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: cec02070-7ed0-48b8-bb9b-c67ad4c4df5b
Created: 2026
-->

<!-- AGENT: Records source-audit changes, direct verification evidence, and remaining validation limits. -->

# Source compliance audit

The audit reviewed every original tracked file under src/ and every source file added for the audit.
The baseline was commit 4996852. Work began on 23 October 2026 and completed on 24 October 2026.
The final [inventory](source-audit.inventory.md) records each file's disposition.
The [plan](source-audit.plan.md) records the scope and verification gates.

The changes preserve the native product scope, local photo processing, and existing website ownership.
No push, deployment, archive upload, App Review submission, or public release occurred.

## Native source changes

Swift types now use files named for their responsibilities. Related extensions use Type+Concern.swift names.
Models, rendering services, platform views, and debug media helpers have explicit ownership.
The Xcode project preserves app memberships and gives tests only their required production sources.
Executable Swift functions and methods contain at most 30 nonblank, noncomment code lines in the audit scan.
Declarative view properties remain separate from this method-size measurement.

The source uses four spaces, Allman braces, a versioned formatter configuration, SPDX notices, and navigation markers.
Comments describe domain responsibilities, units, normalized coordinates, cancellation, and significant validation boundaries.
Local OSLog events contain operation outcomes without photo content, paths, resource names, or catalog addresses.
The native privacy manifest and entitlements retain the existing local-processing and optional-download model.

New input checks reject files above 200 MB and images above 80 million pixels before full native decoding.
The system photo picker now transfers a file. Metadata checks run before the app buffers its compressed bytes.
Chunked reads retain the byte limit even if the file changes after its initial metadata check.
Structured picker tasks cancel stale imports and show a recovery action when transfer fails.
Bitmap allocation checks finite dimensions before integer conversion.
Crop rectangles are clipped to image bounds, and layout checks reject invalid insets, gutters, and excessive copy counts.
One pixel-budget definition now serves input and print-sheet allocation checks.

Optional downloads use ephemeral URLSession state, request and resource timeouts, and streamed byte limits.
Catalogs have a 1 MB limit, and individual resources have a 25 MB limit.
Only HTTPS addresses without embedded credentials are accepted. Redirects receive the same check before following.
Catalog validation limits entries, metadata length, identifiers, file types, duplicate keys, and accepted licenses.
Catalog refreshes are serialized, and at most four resource downloads run at once.
Downloaded frame dimensions are checked before native decompression.

Photo preview cancellation now reaches the detached processing task.
Superseded requests cannot publish stale results. Cached person masks remain local and are released on reset.
An explicit sRGB color space now makes exported palette and custom colors match their native previews.
Regression tests exposed and confirmed that color-space fix.

Exports stage complete files beside their destinations and publish through exclusive local renames.
Existing source and output files remain intact when a destination already exists.
A failed file group attempts rollback only for files whose device and inode still match the recorded outputs.
This operation is not a crash-atomic transaction across PDF and JPEG paths.
Unsupported filesystems fail safely instead of replacing existing destinations.

Expected failures now give a concrete recovery action.
Print-sheet exports retain the existing PDF-only fallback when raster output exceeds the pixel budget.

## Scripts, website, and documents

Component scripts reject invalid modes and extra arguments before builds, cleanup, credentials, or publishing actions.
Uploads verify that the archived app matches the clean source SHA, version, and build number.
Media tools validate dimensions, source/output separation, and existing destinations before export.
Capture scripts stage completed previews before replacing the requested review media.
No media capture or upload script ran against the tracked media during this audit.

Website configuration rejects executable URL schemes, embedded credentials, traversal paths, invalid dates, and duplicate destinations.
Copied icons must resolve inside the repository. Text and attributes remain escaped before template expansion.
Browser theme code uses const and let and tolerates unavailable browser storage.
Preview and deploy commands use the installed Wrangler executable without an implicit package download.
The dependency audit initially reported four high-severity advisories.
A later registry check also identified newly listed Undici advisories. A pinned Undici 7.30.1 override resolves those findings.
The final installed dependency set reported zero vulnerabilities.
Wrangler is locked at 4.152.0. ESLint 10.13.0 and its style plugin are exact development dependencies. No actual Worker deployment or deployment preview ran.

The Cloudflare static-asset configuration was checked against the
[official routing guidance](https://developers.cloudflare.com/workers/static-assets/routing/static-site-generation/).
The existing external theme and website-only analytics remain explicit project choices.
External theme behavior and production website rendering were not verified during this source audit.

Documentation now has source notices and navigation context. Long prose was reflowed, and affected wording was clarified.
Embedded Swift examples follow the source layout. Composure remains a planned product without an app target.
The local App Review response draft now states GPL-3.0-or-later. This does not edit a previously submitted review message.

Strict JSON, asset catalogs, VERSION files, protocol files, and binary media retain valid formats.
The scoped src/REUSE.toml follows the [REUSE specification](https://reuse.software/spec/) for files without embedded notices.
Required third-party notices and standard license wording remain intact.
All 73 binary files retain their baseline hashes. Image thumbnails and video metadata were inspected.
The metadata scan found no GPS or location metadata. This check does not establish ownership beyond the repository's recorded provenance.

## Repeatable checks for future edits

The source includes .editorconfig, .swiftformat, and the website ESLint configuration.
Run ./scripts/check-source-style.sh for read-only SwiftFormat, ShellCheck, and shfmt checks.
Run npm run lint --prefix src/web for JavaScript checks. Installed tools are required. Validation does not download tools.
CONTRIBUTING.md records installation and validation commands.
The build workflow now installs these tools explicitly and checks conventions before it builds the products.
The source-style command has regression tests for scope, paths containing spaces, invalid arguments, and failure propagation.
The hosted workflow was reviewed locally but has not run against these changes.

## Verified results

| Check | Result |
| --- | --- |
| Repository profile | configure.sh --check passed |
| Repository tests | 12 Python checks and 26 Bats checks passed |
| Native regression suite | 79 passed, zero failed, zero skipped |
| Website tests | 23 passed |
| Generated website | Six HTML pages and local references validated |
| Native products | Universal macOS package, iOS simulator, and iOS device builds passed |
| Package integrity | ZIP check passed, and the macOS binary contains arm64 and x86_64 |
| Signing status | The linker emitted an ad hoc signature without a TeamIdentifier. No Developer ID or distribution signature exists |
| Device family metadata | Build script confirmed iPhone and iPad support |
| Shell analysis | ShellCheck 0.11.0 passed for all component shell scripts |
| Source layout | SwiftFormat lint, shfmt comparison, and JavaScript brace checks passed |
| Structured files | JSON, TOML, plist, entitlement, privacy manifest, XML, and scheme parsing passed |
| Media helpers | Both Swift tools compiled. Invalid argument and same-path checks passed |
| Whitespace | git diff --check passed |

The full build used CROPPRINT_CODE_COVERAGE=YES ./build.sh.
The development products carry working-tree provenance based on commit 4996852. They are not release archives.
The native result bundle reports 79 tests and no failures.
Shared production files in the isolated test target reached 84.27% line coverage, or 1,521 of 1,805 executable lines.
That exceeds the 80% minimum and remains below the 90% target in the shared test guide.
The complete test bundle reports 90.67%, but that number includes test code and is not production-code coverage.
The app target reports 21.23%. Most view and document interactions have no automated UI coverage.

The original baseline test target reported 70.5%, including UI source that then shared model files.
The final test target excludes those view implementations after the source split.
These target percentages are not a direct before/after measure of the same denominator.
The coverage reports remain in ignored local/ alongside the inventory hashes and media review evidence.

## Verification limits and ownership

The maintainer still owns physical-device permission checks, Photos saves, printer dimensions, and accessibility interaction tests.
No claim of signed-release readiness follows from the unsigned builds.
No physical iPhone or iPad flow, signed archive, upload, or current App Store state was verified.
Live remote-resource requests and adversarial filesystem concurrency were not integration-tested.
The tests cover the bounded-stream policy and exclusive file-publication behavior directly.

The preview helper still compiles against supported AVMutableVideoComposition APIs that the current SDK marks deprecated.
The maintainer should migrate that helper when a dedicated video-render regression can verify output size, timing, and orientation.
This warning applies to the developer media tool, not the shipping app targets.

The audit establishes reviewed source and measured checks. It does not prove the absence of every defect.
Use the component testing guides before a release, especially after future changes to native permissions or platform SDKs.

## Later website release update

Commit c6799c5 completed this source audit before the separate website publication update.
The later [website release plan](website-release.plan.md) records its source changes and 32 passing website tests.
The native audit measurements above remain the results for the completed source-audit build.
