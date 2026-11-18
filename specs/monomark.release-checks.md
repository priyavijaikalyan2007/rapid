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
