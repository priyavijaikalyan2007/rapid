<!--
SPDX-FileCopyrightText: 2026 Vijai Kalyan
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 6e41eb86-f2bf-4394-9905-247177ff6a88
Created: 2026
COMPONENT: README
PURPOSE: Records the README project specification.
RELATES: PROJECT.md, instructions/WORKFLOW.md
FLOW: Authored source -> component validation -> local result.
-->

<!-- AGENT: Records the README project specification. -->

# CropPrint test assets

This directory contains generated sample photos for CropPrint quality assurance and App Store evidence.

The project owner supplied these images for testing. They do not show household photos or other private
content.

The sample photos are not compiled into either application. They remain separate from the shipping application
bundles.

## File formats

The main set contains 20 quality-85 JPEG files. These files preserve the original pixel dimensions while
reducing repository storage.

`SampleImages/22-format-test-portrait.heic` provides a HEIC input test. Use the existing
`AppStore/Media/Source/sample-landscape.png` file for PNG input tests.

The complete sample set uses about 33 MB. The original PNG files remain outside the repository in the project
owner's Downloads folder.

## Recommended samples

Use these files for repeatable tests:

| File | Main use |
| --- | --- |
| `08-mountain-lake-wide.jpg` | Standard print crops, wallpapers, text, and frames |
| `10-mountain-panorama-ultrawide.jpg` | Wide monitor presets and extreme crop ratios |
| `06-family-with-pets-landscape.jpg` | Group composition and general print sheets |
| `07-friends-at-campsite-landscape.jpg` | Dark-scene adjustments and group-person processing |
| `16-woman-portrait.jpg` | Passport crops, head guides, and background replacement |
| `18-man-portrait-square.jpg` | Square social-media crops and person processing |
| `20-man-portrait.jpg` | Portrait crops and angle adjustments |
| `22-format-test-portrait.heic` | HEIC input compatibility |

Use other numbered files to test different compositions and crop positions.

## Device preparation

1. AirDrop the `SampleImages` files to the iPhone.
2. Save the received images in Photos.
3. Create a Photos album named `CropPrint QA`.
4. Add every received test image to that album.
5. Repeat these steps on the iPad.
6. Keep the repository folder available on the Mac.

Do not use personal photos in App Store recordings, screenshots, or public defect reports.

Follow `TESTING-GUIDE.md` for the complete device, recording, screenshot, and regression process.
