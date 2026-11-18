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
