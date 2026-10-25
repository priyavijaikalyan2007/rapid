<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: c2ac0b0d-fd32-4bf6-b1a8-610f3553042d
Created: 2026
-->

<!-- AGENT: Records user-visible repository and application changes from this setup onward. -->

# Changelog

## 25 October 2026

### Added

- Added Composure privacy onboarding and native profile settings with explicit Save, Discard, and confirmed reset actions.
- Added native iPhone/iPad UI tests for onboarding navigation and preference restoration after relaunch.

### Fixed

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
