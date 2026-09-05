# CropPrint App Store media

This directory contains the App Store screenshots and previews for CropPrint.

Run this command from the CropPrint directory:

```bash
./scripts/capture-app-store-media.sh all
```

The script creates these media sets:

- `iPhone`: 1284 × 2778 screenshots and an 886 × 1920 preview
- `iPad`: 2064 × 2752 screenshots and a 1200 × 1600 preview
- `macOS`: 2560 × 1600 screenshots and a 1920 × 1080 preview

The previews are H.264 screen recordings. App Store Connect accepts previews from 15 through 30 seconds.

The source photograph is an original, generated image. It contains no person, private information, logo, or third-party asset.

The application enables its sample state only in Debug builds. Release builds ignore all screenshot launch arguments.

macOS can request Screen Recording and Accessibility permission during the first capture. Grant both permissions to Terminal, then run the command again.
