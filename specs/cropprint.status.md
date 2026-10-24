<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 93326dde-e370-43dd-8024-c22c5671f4c0
Created: 2026
-->

<!-- AGENT: Records CropPrint implementation evidence and release verification limits. -->

# CropPrint status

Reviewed on 23 October 2026.

CropPrint has macOS, iPhone, and iPad source, shared processing services, and unit tests.
The source version is 1.0.0. Build numbers derive from Git history and can change after a commit.
The current application includes crop presets, print sheets, decorations, local photo adjustments, and optional licensed resource downloads.

The macOS test command passed on 23 October 2026 after sandbox access was granted.
The first sandboxed attempt failed because Xcode test services and distributed notifications were blocked.
This result does not verify physical-device permissions, print dimensions, signed archives, or App Store status.

The full unsigned build also passed on 23 October 2026.
The build produced the macOS ZIP, iOS simulator application, and iOS device application.
The build script verified that the device application supports iPhone and iPad.
The ZIP integrity check passed, and the macOS executable contains arm64 and x86_64 architectures.
The development package is unsigned. The code-signature check confirmed that no signature is present.
The About view and local App Store metadata now state GPL-3.0-or-later.
This source update did not change the license text on an existing App Store submission.

The App Review guide describes historical build 12 and contains pending device rows.
Verify the currently submitted build directly in App Store Connect before preparing review evidence.
Follow [PUBLISHING.md](../PUBLISHING.md) for the release gates.
No archive, upload, App Review submission, or public release occurred during this setup task.

## Source audit on 24 October 2026

The source audit completed on 24 October 2026. All original source files and added files have review outcomes.
The complete unsigned build passed, including both mobile variants and universal macOS packaging.
The native suite passed 79 tests. Shared production-code line coverage is 84.27%, above the 80% minimum.
The full app target has 21.23% coverage, so UI and device verification remain separate work.
See the [audit report](source-audit.report.md) for safety changes, evidence, and remaining checks.
