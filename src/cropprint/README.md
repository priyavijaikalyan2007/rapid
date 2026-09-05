# CropPrint

CropPrint is a private photo-cropping app for macOS, iPhone, and iPad. It does not use login, analytics, advertising, or data collection.

Both applications use `us.outcrop.apps.cropprint` for one multi-platform App Store listing. Both products include the shared privacy manifest under `Shared`.

The About page shows the semantic version, Git SHA, and numeric build number. Repository builds read the semantic version from `VERSION`.

The app keeps the crop rectangle at the selected ratio. You can move or resize the rectangle to choose the composition. CropPrint saves a new image beside the original and never changes the original file.

## Features

- Open a photo from the File menu, a Finder **Open With** action, or drag and drop.
- Reopen one of the ten most recent photos from the File menu.
- Resize from any corner without changing the selected aspect ratio.
- Select common print sizes from 4x6 through 24x36.
- Create Instagram Story, portrait, and square images at exact output dimensions.
- Create wallpapers for recent iPhones and common MacBook display sizes.
- Crop photos to common passport and identity-photo dimensions.
- Show preset-specific head and chin guides for passport photos.
- Replace portrait backgrounds locally for passport and Instagram presets.
- Adjust exposure, contrast, highlights, shadows, saturation, hue, sharpness, and angle.
- Create monitor wallpapers from VGA through 8K UHD.
- Tile passport or general-print crops onto physical print sheets.
- Show hover tooltips for every macOS toolbar icon.
- Provide built-in Help from the toolbar and Help menu.
- Select portrait or landscape orientation.
- Record the paper size in the output name and check whether the photo fits the paper.
- Add an optional 0.25-inch white margin inside the selected print size.
- Export JPEG, PNG, TIFF, or HEIC without stretching the image on macOS.
- Choose from Photos and save back to Photos on iPhone and iPad.
- Preserve the original base name and add all selected settings.
- Download approved fonts and frame assets from a curated HTTPS catalog.
- Show the creator, source, and exact license for each remote resource.
- Cache downloaded resources for offline use.
- Provide About and Attributions pages on macOS, iPhone, and iPad.
- Add one styled text layer to the cropped image.
- Control the text font, size, color, opacity, rotation, and position.
- Add classic, double, rounded, film, or Polaroid-style frames.
- Control the frame color, width, and opacity.
- Apply downloaded transparent frame images from the remote catalog.

An example output name is `family-8x10-landscape-letter-margin.jpg`.

Digital presets resize the crop to the exact destination resolution. Print presets preserve the available source pixels. CropPrint applies text and frames after resizing.

The macOS app keeps decoration controls in the right sidebar. The iOS app shows them in a movable bottom sheet.

The iPad layout places the photo canvas and controls side by side when regular horizontal space is available.

The text layer appears directly on the photo. Drag the text box to move it. Use its handles to change width, scale, or rotation.

Font and style changes appear immediately. Choose a preset color swatch or use the system color picker for a custom color.

## Requirements

- macOS 14 or later
- iOS or iPadOS 17 or later
- Xcode 16 or later

## Build and run in Xcode

1. Open `CropPrint.xcodeproj` in Xcode.
2. Select the `CropPrint` scheme.
3. Select **My Mac** as the run destination.
4. Press **Command-R**.

If Xcode asks for a development team, select your personal team. The app does not require a paid account for local use.

To run the iPhone or iPad app:

1. Select the `CropPrint Mobile` scheme.
2. Select an iPhone or iPad simulator, or select a connected device.
3. Select your team under **Signing & Capabilities** for a physical device.
4. Press **Command-R**.

The iOS version uses the system photo picker. It requests permission only when it saves the result to Photos.

## Crop presets

The digital presets include these output sizes:

- Instagram Story: 1080x1920
- Instagram Portrait: 1080x1350
- Instagram Square: 1080x1080
- iPhone 14 Pro: 1179x2556
- iPhone 17 Pro: 1206x2622
- iPhone 16e home and lock screens: 1170x2532
- MacBook Air 13-inch: 2560x1664
- MacBook Air 15-inch: 2880x1864
- MacBook Pro 13-inch: 2560x1600
- MacBook Pro 14-inch: 3024x1964
- MacBook Pro 16-inch: 3456x2234

Passport and identity presets include these dimensions:

- India, Europe, United Kingdom, Japan, and South Korea: 35x45 mm
- United States: 51x51 mm
- Canada: 50x70 mm
- China: 33x48 mm
- Australia: 35x45 mm, which is the minimum accepted outer size
- Singapore digital submission: 400x514 pixels
- New Zealand digital submission: 900x1200 pixels

Passport presets include translucent bands for the recommended crown and chin positions. Each preset links to current official guidance.

The bands are visual aids. Check current head-size, background, expression, age, and submission rules before use.

Some authorities prohibit digital background replacement or other alterations. CropPrint warns users but does not determine compliance.

Monitor presets include VGA, SVGA, XGA, SXGA, UXGA, HD, Full HD, DCI 2K, QHD, and WQXGA.

They also include Ultrawide QHD, 4K UHD, DCI 4K, 5K, 6K, and 8K UHD. Monitor presets support landscape and portrait orientation.

## Print sheets

Select a physical print or passport preset. Then select **Create Print Sheet** from the toolbar or File menu.

The print-sheet panel supports these options:

- Any configured paper size, including 4x6, 5x7, Letter, and A4
- Portrait or landscape paper
- JPEG image resolutions from 72 through 1,200 pixels per inch
- Printer resolutions from 300 through 4,800 dots per inch
- Automatic tiling with safe edge spacing
- Optional cutting guides
- A calibrated true-size preview and live physical-size information

The macOS app saves a JPEG and PDF beside the source photo. The iOS app saves the JPEG sheet to Photos.

The PDF stores the physical paper dimensions. Print it at **Actual Size** or **100 percent**.

Disable **Fit to Page**, automatic cropping, and borderless enlargement. These printer options can change the physical passport-photo dimensions.

Large raster sheets can require excessive memory. The macOS app creates PDF-only output when the JPEG exceeds the safe limit.

On iPhone and iPad, select lower image PPI or smaller paper when the JPEG exceeds the safe limit.

Printer DPI and image PPI measure different items. Printer DPI does not change the PDF paper size or the printed photo size.

The true-size preview uses a saved display calibration. Match its one-inch line to a physical ruler before you judge print size.

The display dimensions come from Apple technical specifications. Instagram presets use Meta-supported ratios and a 1080-pixel output width.

If command-line builds select only the Command Line Tools, run this command once:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## Create an unsigned package

Run this command from the `src/cropprint` directory:

```sh
./scripts/package-unsigned.sh
```

The script creates `build/CropPrint-unsigned.zip`. This universal build supports Apple silicon and Intel Macs.

macOS can block an unsigned app that another person downloads. The recipient can right-click the app and select **Open**. Use a signed release for a normal public download.

## Publish a signed app

Apple requires a paid Apple Developer Program membership for Developer ID signing and notarization. Notarization lets users open a downloaded app without a security workaround.

The `Signed release` GitHub Actions workflow runs when you push a tag such as `v1.0.0`. Add these encrypted repository secrets first:

- `BUILD_CERTIFICATE_BASE64`: A base64-encoded Developer ID Application certificate in PKCS #12 format.
- `P12_PASSWORD`: The export password for that certificate.
- `KEYCHAIN_PASSWORD`: A temporary password chosen for the GitHub Actions keychain.
- `APPLE_ID`: The Apple ID for notarization.
- `APP_SPECIFIC_PASSWORD`: An app-specific password for that Apple ID.
The public Apple Developer Team ID comes from `../../config/apple-developer.env`.

Then create and push a release tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions builds, signs, notarizes, and publishes `CropPrint.zip` on the GitHub release.

## Privacy

CropPrint reads only the photo that you select. It writes only the exported photo.

Photo adjustments, angle correction, and person segmentation run on the device through Apple Core Image and Vision.

The app contacts a server only when you refresh or download remote resources. The server receives normal request data, such as your Internet Protocol address. CropPrint does not send photos, crop settings, analytics, or personal data.

## Remote resource catalog

Open **CropPrint > Remote Resources** on macOS. On iPhone or iPad, open the toolbar menu and select **Remote Resources**.

Leave the catalog address empty to use the built-in Google Fonts list. Enter an HTTPS address to load your own catalog. CropPrint accepts these licenses:

- SIL Open Font License 1.1
- Apache License 2.0
- Ubuntu Font License 1.0
- Creative Commons CC0 1.0
- Creative Commons Attribution 4.0
- Creative Commons Attribution-ShareAlike 4.0
- MIT License

CropPrint rejects incomplete attribution data and unsupported file types. The frame list excludes licenses that prohibit modifications.

Host a catalog as a static JSON file on GitHub Pages, Cloudflare Pages, or another HTTPS site. Start with [`RemoteCatalog/catalog.example.json`](RemoteCatalog/catalog.example.json).

Each resource needs a stable identifier, title, kind, creator, source address, download address, exact license, and license address. The `kind` value must be `font` or `frame`.

The built-in fonts come from the official Google Fonts repository. CropPrint downloads the font files and registers them only for the current app process.

## License

This project uses the MIT License. See `LICENSE`.
