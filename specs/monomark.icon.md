<!-- SPDX-FileCopyrightText: 2026 Outcrop Inc -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- File GUID: f1c6f5c0-02a7-470e-8530-5c9edcb4691a -->
<!-- AGENT: MonoMark icon provenance and asset verification. -->

# MonoMark Mac icon

The owner requested an AI-generated icon on 17 November 2026. GitHub #66 tracks this work.
The built-in image generation tool produced a transparent PNG. No external reference image was supplied.
The selected icon uses an ivory Markdown mark on a graphite rounded tile.
System `sips` downsampling creates the ten Mac icon slots from the generated 1254-pixel square.
The largest stored icon is 1024 pixels. The source assets remain inside the repository.

The catalog is `src/app/monomark/apple/Mac/Assets.xcassets/AppIcon.appiconset/`.
Xcode compiles AppIcon.icns and Assets.car. Both Mac configurations select AppIcon.
Release tests check every slot, PNG dimensions, resource membership, and build-setting selection.
The secondary iOS/iPadOS icon remains outside this Mac release task.

## Generation prompt

```text
Use case: logo-brand. Asset type: production macOS application icon for MonoMark, a fast monospace Markdown reader. Create one icon only, 1024 by 1024 pixels. A restrained native Mac icon: a graphite rounded-square tile with gently rounded corners, subtle premium paper-like depth and a thin soft edge highlight. Center a large crisp ivory monospaced capital M, with a small downward arrow integrated beside it to suggest Markdown. Keep the symbol bold, geometric, readable at 16 pixels, and optically centered. No app name, no other letters, no tiny details, no surrounding objects, no mockup, no watermark. Tile occupies about 88 percent of the square canvas, transparent outer margin and fully opaque interior. Straight-on orthographic view. Deliver actual transparent pixels outside the rounded tile.
```
