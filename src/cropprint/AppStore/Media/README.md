<!--
SPDX-FileCopyrightText: 2026 Vijai Kalyan
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: d3ea6141-7817-4740-a42a-18d9280ca07e
Created: 2026
COMPONENT: README
PURPOSE: Records the README project specification.
RELATES: PROJECT.md, instructions/WORKFLOW.md
FLOW: Authored source -> component validation -> local result.
-->

<!-- AGENT: Records the README project specification. -->

# CropPrint App Store media

Use the generated photos under `../../Testing/SampleImages` when new screenshots need repeatable, nonprivate
source images.

This directory contains the App Store screenshots and previews for CropPrint.

Run this command from the CropPrint directory:

```bash
./scripts/capture-app-store-media.sh all
```

The script creates these media sets for new captures:

- `iPhone`: 1206 × 2622 screenshots and an 886 × 1920 preview
- `iPad`: 2064 × 2752 screenshots and a 1200 × 1600 preview
- `macOS`: 2560 × 1600 screenshots and a 1920 × 1080 preview

The committed iPhone screenshots use the previously accepted 1284 × 2778 size. Do not replace accepted
build-12 media only because Apple changed its required device class.

The previews are H.264 screen recordings. App Store Connect accepts previews from 15 through 30 seconds.

The source photograph is an original, generated image. It contains no person, private information, logo, or
third-party asset.

The application enables its sample state only in Debug builds. Release builds ignore all screenshot launch
arguments.

macOS can request Screen Recording and Accessibility permission during the first capture. Grant both
permissions to Terminal, then run the command again.
