<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
File GUID: 374eafd6-fc7c-42eb-8460-90774c0d976d
Created: 2026
-->

<!-- AGENT: iPhone/iPad completion plan, source boundaries and release evidence. -->

# Monoleaf mobile completion — 23 November 2026

The owner requested: "ok forget Linux. Let us finish iPhone & iOS."
Continue the existing iPhone and iPad scope. Linux is excluded.
Preserve the submitted macOS 1.0.0 build 111 and its archived artifacts.
Preserve the unrelated owner-edited Mac UI-test scheme.

## Observed baseline

The existing iOS and Simulator Release builds pass before changes.
The shared viewer already provides rich rendering, annotations, notes, settings and export-copy controls.
The mobile target lacks an iOS icon and uses a different bundle identifier from the selected store record.
Its toolbar contains too many persistent controls for narrow phones.
Only the initial tab receives the open-new-tab callback. Reusing one SwiftUI view identity across sessions
also leaves the existing webview/coordinator bound to the previous tab.
An existing iPhone and iPad are paired and available. Their private identifiers are kept out of source.
No physical-device acceptance is inferred from pairing.

## Work sequence

1. Add failing release-resource and command-boundary checks.
2. Align the mobile bundle/team, add the current iOS icon, and provide a local-only mobile archive/export command.
3. Add mobile tab and session lifecycle regressions before fixes.
4. Keep navigation callbacks valid for every tab and bind each webview to the correct session.
5. Adapt toolbars, find controls and inspectors to phone/tablet layouts using native controls.
6. Add an isolated mobile UI-test scheme and synthetic document launch support for native verification.
7. Exercise iPhone/iPad Simulator navigation, settings, copy, annotations, notes and export flows.
8. Test signed physical-device behavior where the paired devices permit it.
9. Build a clean signed mobile candidate and prepare mobile review metadata/screenshots.
10. Update #72 and child bugs/tasks with executed evidence. Keep unexecuted checks open.

App Store upload, App Review submission and public release remain separate actions.

## Files and interfaces

Release resources: apple/Mobile/Assets.xcassets, apple/MonoMark.xcodeproj/project.pbxproj,
AppStore/ExportOptions.plist, tools/archive-mobile-app-store and test/test_monomark_release.py.
Mobile UI: apple/Mobile/MobileReaderView.swift and new mobile-specific tab/toolbar helpers as needed.
Shared UI: apple/Shared/ReaderView.swift and ReaderWebView.swift, with iOS-only adaptations where possible.
Tests: apple/MobileUITests and its new shared scheme, plus Core tests for extracted state/lifecycle policies.
Documentation/evidence: AppStore/MOBILE-LISTING.md, specs/monoleaf.mobile-*.json,
specs/monomark.status.md, specs/monomark.issues.json, CONVERSATION.md and agentknowledge records.

Use a small observable mobile tab coordinator for session creation, selection and closure.
Keep document parsing/storage in the existing ReaderSession/Core services. Keep SwiftUI event handlers thin.
No new GoF pattern is required. The existing session/service separation and a mobile coordinator suffice.
Testing hooks must require explicit synthetic-test launch arguments and use isolated reading data.
Never inspect private documents or normal reading stores during automation.

## Acceptance boundaries

Validate code, signed archives, Simulator results, physical-device results and store delivery separately.
Use real file providers, touch selection, external keyboard, VoiceOver, rotation and iPad compact layouts
when available. Simulator compilation alone is not mobile acceptance.

## Native interaction findings

Keep each test document and its settings/notes in a stable, isolated store across relaunch.
ReaderSession accepts an optional storageDirectory alongside its existing defaults injection.
Normal application storage paths remain unchanged.

Attach the iOS inspector to the split detail column. Pin the phone Notes header above its scrollable content.
Group secondary commands into native submenus and remove phone-only fixed sheet heights.
Keep the existing Mac window sizes. Use 44-point artifact controls for touch and focusable equation controls.
Expose the app's Documents folder through Files so offline exports have a local destination.

Track the iPad inspector, touch controls and compact landscape fixes through #78, #79 and #80 under #8.
Distinguish an application regression from test timing or selector errors in the native evidence.

## New-tab fragment correction

Source review found that ReaderSession.navigate drops the fragment when it calls openNewTab.
Add a native regression through Links > Open in New Tab before changing this behavior.
Extend the callback to (URL, URL?, String?) and forward the fragment into ReaderSession.open.
Add optional fragment arguments to MobileReaderTabs.newTab and AppDelegate.createWindow.
Update ReaderWindowController, FolderRow and ReviewLinkSmoke call sites.
Keep file/folder access checks in LinkPolicy. No new pattern or service is required.
Use a long synthetic Linked.md fixture with a final heading to verify the actual scroll destination.

Native execution also reproduced a viewport defect after fragment forwarding was corrected.
Before a first render, WebKit can clamp the scroll offset. Request the destination range directly.
Preserve the visible block across range replacement and retain its prior offset through resize.
Keep the destination pending for two animation frames so a delayed native scroll update cannot request the old range.
Guard scheduled alignment by document epoch, mount sequence and destination identity.
Reset cached anchors when replacing or clearing a document.
Three renderer regressions failed first and pass after these corrections.
Temporary synthetic trace instrumentation was removed before final verification.
