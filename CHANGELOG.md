<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: c2ac0b0d-fd32-4bf6-b1a8-610f3553042d
Created: 2026
-->

<!-- AGENT: Records user-visible repository and application changes from this setup onward. -->

# Changelog

## 18 November 2026

### Fixed

- Prevented deleted MonoMark history from returning through queued writes and stopped older checkpoints from rewinding positions.
- Preserved MonoMark notes, preferences, and identity across atomic replacement followed by rename.
- Restored saved tab snapshots and released inactive renderers when tab selection changes without a key-window event.

## 17 November 2026

### Changed

- Set MonoMark native and renderer release metadata to 1.0.0, with a numeric build and separate source revision.

### Added

- Added MonoMark Mac App Store listing drafts, reviewer examples, local archive/export tooling, and release metadata checks.
- Added a generated MonoMark Mac application icon and all required icon sizes.
- Added MonoMark optional file and numbered-section reference links, new-tab navigation, and a bounded shared folder index.
- Added MonoMark reload controls, a command-line launcher, source-line references, and inline or selective reading-data exports.

### Fixed

- Reattached MonoMark highlights across external block changes and kept navigation/export references current without guessing among duplicate quotes.

- Prevented older MonoMark PNG requests from replacing a later text copy or dismissing a newer artifact copy.

- Bounded MonoMark large-table layout and preserved whole-grid Copy. Kept print content until native completion and rejected oversized jobs explicitly.

- Preserved MonoMark selections and Copy across unloaded content, including full-index Select All and bounded quote anchors.
- Enabled sandboxed MonoMark WebKit startup and bounded automatic renderer recovery.
- Recovered MonoMark per-file reading state after atomic replacement and prevented duplicate history entries.
- Bundled MonoMark privacy declarations for local preferences and file metadata on all Apple targets.
- Preserved MonoMark heading highlights, table alignment after jumps, path copying, monospace code, and distinct exported comments.

## 15 November 2026

### Added

- Added MonoMark folder workspaces, a shared recent-folder switcher, remembered documents, and empty-workspace handling.
- Added MonoMark light/dark reader palettes, named swatches, presets, per-mode reset, and text contrast checks.

### Fixed

- Included MonoMark license text in offline bundles and removed obsolete renderer assets during rebuilds.
- Waited for image decoding before PNG capture and rejected stale copy completions after document changes.
- Blocked note editing without an open document and cleared note undo state across document changes.
- Kept new documents on application defaults instead of inheriting the previous file's appearance.

## 14 November 2026

### Added

- Added MonoMark app-local highlights, quote comments, reading notes, a right inspector, and explicit generated-section export.
- Added the MonoMark native reader, offline renderer, reading history, document navigation, artifact copying, and appearance settings.
- Added MonoMark paper size preferences, estimated page progress, and bounded Pages/Pageless viewing.
- Added MonoMark annotation panel controls, annotation and note search, installed fonts, version details, and offline Help.

### Fixed

- Improved MonoMark annotation jumps, active file rows, copyable title paths, settings actions, and code token styling.

## 13 November 2026

### Added

- Recorded MonoMark viewer requirements and a proposed design. Application implementation remains planned.
- Defined MonoMark single-display full screen, window switching, keyboard shortcuts, printing, scrolling, and panning requirements.
- Refined MonoMark reading-state storage, full history, large documents, document tabs, local previews, and table styles.

### Changed

- Replaced speculative MonoMark shortcut mappings with Pages and platform conventions, including Escape and document-boundary behavior.

## 6 November 2026

### Added

- Added finite-output automatic detector evaluation and frozen timed conversations. Both iterations failed the original coaching-quality gate.

## 5 November 2026

### Added

- Added optional evidence-first Composure model evaluation and a publisher-backed shortlist. Both prototype policies failed the quality gate.
- Recorded pinned Ministral and Granite comparisons and a tested tokenizer correction. Neither model passed the automatic-coaching quality gate.

## 3 November 2026

### Added

- Added an optional offline local-model benchmark with pinned artifacts, strict replies, shared invented fixtures, and Core cue replay.
- Recorded Apple, Gemma, and Qwen comparisons. No candidate passed the adoption gate, so the application's model remains unchanged.

### Changed

- Limited Composure V1 to macOS and deferred mobile build and release gates while retaining existing source.
- Set an M3/M4 MacBook Air with 16 GB unified memory as Composure's performance reference.

## 1 November 2026

### Fixed

- Preserved short meaningful speech while continuing to skip filler-only input.
- Added content-free Debug diagnostics that clear on Stop.
- Expanded live quality checks across conversation topics and added a progressing conversation regression.

## 30 October 2026

### Added

- Added explicit Mac live coaching with selected-application and microphone audio, temporary speech context, and a floating native cue panel.
- Added sparse on-device situation classification, profile-based wording, bounded model work, and independent cue validation.
- Added Mac UI journeys for explicit Start, Stop, navigation cleanup, and synthetic cue display.

### Fixed

- Bound live suggestions to current speech and reject label-only instructions.
- Allow distinct advice sharing a headline while preserving repeat controls and profile frequency caps.
- Add bounded live decision counters and fixed behavioral priority for pause and rephrase actions.
- Made the Mac meeting objective field visibly editable before Start and explained why setup stays locked during coaching.
- Strengthened Mac UI coverage to verify objective text before Start and editing again after Stop.
- Kept canceled source selection quiet and blocked restart when native audio Stop remains unconfirmed.
- Treated low-confidence output as silence and separated situation classification from profile priorities to reduce repeated generic cues.

## 29 October 2026

### Fixed

- Added speech setup and refresh directly beside the Mac audio-check controls when speech assets block Start.
- Clarified that the development check reports capture and recognition counts without coaching feedback, including Chrome selection guidance.

### Added

- Added an explicit Debug Mac audio check for separate microphone and selected-app streams through two speech analyzers.
- Added bounded PCM conversion, common-clock timing, missing-stream deadlines, and cancellation-safe cleanup.
- Kept microphone usage text and audio-input access limited to Debug builds. Release capture behavior remains unchanged.

## 28 October 2026

### Added

- Added passive Composure device-readiness checks and explicit speech-asset setup in native Settings.
- Added shared setup progress, controlled errors, retry, and recovery when Apple completes a download later.
- Added isolated phone and iPad setup journeys without real downloads or capture permissions.

## 27 October 2026

### Fixed

- Replaced Composure's finite Prepare phrase bank with bounded, role-aware generation after the owner reported repetitive advice.
- Preserved explicit manager and recipient roles, added outcome-uncertainty guidance, and removed literal duplicate suggestions.
- Added paired role regressions and separated relevance checks from functional and injection checks.

## 25 October 2026

### Added

- Added bounded, memory-only Composure preparation contracts, profile guidance, and a separate on-device model adapter.
- Added native Composure Prepare screens, model readiness, reviewed model-selected guidance, and explicit Clear and Cancel actions.
- Added mobile preparation shielding and lifecycle tests for background clearing and empty preparation after relaunch.
- Added Composure privacy onboarding and native profile settings with explicit Save, Discard, and confirmed reset actions.
- Added native iPhone/iPad UI tests for onboarding navigation and preference restoration after relaunch.

### Fixed

- Constrained Composure preparation output after live injection tests exposed attack text in free-form model responses.
- Prevented Composure profile reset from saving unrelated draft preferences.

## 24 October 2026

### Fixed

- Aligned Composure Debug app and package architectures for Xcode's My Mac destination and added that build check.
- Pinned the CI formatter to the verified SwiftFormat 0.64.1 release and selected a macOS 26 host for Composure tests.
- Bounded photo decoding, catalog metadata, resource downloads, crop geometry, and raster allocation before expensive native work.
- Preserved existing files through exclusive export publication and safe preview-media staging.
- Propagated edit cancellation and aligned exported decoration colors with native sRGB previews.
- Added recovery actions to expected errors and validated exact archive provenance before upload.
- Rejected unsafe website addresses and output paths and updated vulnerable development-tool dependencies.
- Required an explicit deployment mode in the component website helper, matching the root command.

### Changed

- Limited Composure Mac application builds to Apple silicon in both Debug and Release configurations.
- Marked CropPrint as available and added its App Store download action to the home and product pages.
- Split native types into named files and applied source layout, useful comments, navigation markers, and license notices.
- Preserved binary media and strict data formats under scoped REUSE annotations.
- Reviewed source documentation and updated knowledge anchors and component status records.

### Added

- Added bounded Composure profile models, versioned app-only preferences, and save/recovery tests.
- Added the Composure Mac and iPhone/iPad foundation, shared lifecycle and safe-logging tests, and component build commands.
- Recorded the Composure review and confirmed privacy, platform, timing, and remote-capture requirements.
- Added source-audit inventory and evidence, 79 native regression tests in total, and 23 website tests in total.
- Added component shell boundary and source-style checks to the root repository test suite.
- Added checked-in editor defaults and JavaScript lint rules, with convention checks in the build workflow.

## 23 October 2026

### Added

- Added repository checks, local development and packaging entry points, and explicit website deployment routing.
- Added source-backed agent knowledge, component status records, and an ignored local repository search index.
- Added maintainer contribution rules, a conduct policy, and a private vulnerability reporting policy.

### Changed

- Separated native application, website, documentation, and tool scopes through configure.sh.
- Applied GPL-3.0-or-later to project-owned material and updated CropPrint's displayed license and local store metadata.
- Directed website security contacts to private GitHub reporting and admin+security@outcrop.us.
- Added repository checks to the existing build workflow and corrected Composure specification links.
