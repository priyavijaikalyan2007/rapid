<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: c5273a13-2b97-42df-a766-705a0c5059bd -->
<!-- AGENT: Remaining physical and interactive checks for the exact Mac release candidate. -->

# MonoMark manual Mac release checks

The requested Mac feature set is implemented. These checks require access that the current automated host does not provide.
Use the exact signed candidate recorded in monomark.release-candidate.json. Record its version, build, and source revision.
Use copies of the public AppStore/Fixtures documents. Do not use private source documents for destructive export tests.
Do not mark an unchecked item complete from a compilation result or an app-owned fixture test.

## User-selected files and providers

1. Copy the synthetic examples into a local folder outside the app container.
2. Open that folder through File > Open Folder.
3. Open each document from Files.
4. Add a comment and a reading note.
5. Quit MonoMark.
6. Open MonoMark again.
7. Confirm that the document, reading position, comment, and note return without a new grant.
8. Repeat the open and reopen steps from a downloaded iCloud Drive or other file-provider folder.
9. Export reading data to a copy.
10. Confirm that the copy contains the chosen data and the source remains unchanged.
11. Export reading data into the synthetic source.
12. If a write-grant panel appears, cancel it.
13. Confirm that cancellation leaves the source unchanged.
14. Repeat the export and allow the write grant.
15. Confirm that the generated section appears once and preserves the original source content.

Record provider name, downloaded/offline state, grant prompts, and outcome under #11 and #24.
Read-only filesystem permissions can still prevent an export after a sandbox grant. Confirm that the app reports that failure.

## VoiceOver and keyboard access

1. Enable VoiceOver through macOS Accessibility settings.
2. Navigate Files, Contents, Links, History, and the right inspector.
3. Confirm that controls have useful names and the active file is distinguishable.
4. Read the document's headings, table headers, code, image alternatives, and artifact actions.
5. Open a comment and edit it through the keyboard.
6. Paste text into the comment and Notes.
7. Use Find, Open, Print, Zoom, and standard document navigation commands.
8. Confirm that focus stays visible and returns after each dialog closes.
9. Restore the previous VoiceOver setting.

Record results under #28. Programmatic document-focus and semantic checks already pass. They do not establish VoiceOver acceptance.

## Multiple physical displays

1. Open two independent MonoMark windows.
2. Put one window on each display.
3. Enter single-display presentation in one window.
4. Confirm that the other display and window remain usable.
5. Press Escape.
6. Confirm that the original window frame returns.
7. Repeat the presentation check on the second display.
8. Disconnect that display during presentation.
9. Confirm that the document remains reachable on the remaining display.

Record display arrangement and results under #28. Test the minimum supported macOS and Intel runtime when that hardware is available. One-display presentation, Escape, and independent-window preservation already pass.

## Reference hardware and store account

Run scripts/monomark_native_profile.py on the selected slower Mac and attach its JSON to #14.
Keep app-only counters separate from the conservative total that includes every WebKit helper.
Record calibrated energy and repeated-switch behavior separately. The 64 GiB M5 Pro is development evidence.

Check the Outcrop App Store record, name availability, Free pricing, manual release mode, privacy answers, and export compliance.
Copy the authorized CropPrint review contact directly in App Store Connect. Keep contact details outside source.
Review the four actual-window screenshots before uploading. Match the final listing to the documented source, object, image, and print limits.
Upload, App Review submission, notarization submission, and publication remain separate authorized release actions.
