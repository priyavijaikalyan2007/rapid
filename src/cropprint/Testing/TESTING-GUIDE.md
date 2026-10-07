# CropPrint physical-device testing guide

This guide covers App Review evidence for build 12 and full regression testing for later builds.

## Keep the two test tracks separate

Apple is reviewing version 1.0.0, build 12, from Git commit `b9e9fcf40db53f4ef72d1bff979ffdb1ee34dac5`.

Use the TestFlight build 12 application for every App Review recording. Do not record a local development build as build-12 evidence.

Later source builds contain photo adjustments, background replacement, angle correction, and passport head guides. Test those features separately.

## Device matrix

Complete one row for each test session.

| Platform | Physical device | Operating system | Installed source | Result |
| --- | --- | --- | --- | --- |
| iPhone | iPhone 12 mini | Latest supported stable version | TestFlight build 12 | Pending |
| iPad | Record the model | Latest supported stable version | TestFlight build 12 | Pending |
| macOS | MacBook Pro | Latest supported stable version | TestFlight build 12 | Pending |

## Prepare each device

1. Install the latest stable operating-system update.
2. Install CropPrint build 12 through TestFlight.
3. Import the sample images from `SampleImages`.
4. Disable notifications with a Focus mode.
5. Remove private widgets from the visible Home Screen.
6. Set the display to its normal resolution.
7. Open CropPrint.
8. Open About CropPrint.
9. Confirm version 1.0.0 and build 12.
10. Confirm the displayed Git SHA starts with `b9e9fcf`.
11. Close CropPrint before recording.

Stop if the About page shows a different build. Apple requested evidence from the submitted build.

## Record the iPhone workflow

Use one continuous recording. Keep the device in portrait orientation.

1. Start Screen Recording from Control Center.
2. Return to the Home Screen.
3. Launch CropPrint.
4. Open About CropPrint.
5. Show version 1.0.0 and build 12.
6. Close the About page.
7. Select Choose Photo.
8. Open `08-mountain-lake-wide.jpg`.
9. Select the Print category.
10. Select the 4x6 crop size.
11. Select Landscape orientation.
12. Move the crop rectangle away from the center.
13. Resize the crop rectangle from one corner.
14. Confirm that the rectangle keeps its ratio.
15. Capture screenshot 01.
16. Select Crop and Save to Photos.
17. Show the successful save message.
18. Open `16-woman-portrait.jpg`.
19. Select the Passport and ID category.
20. Select United States Passport.
21. Position the face inside the square crop.
22. Capture screenshot 03.
23. Select Create Print Sheet.
24. Select 4x6 paper.
25. Select 300 PPI image resolution.
26. Select 300 DPI printer resolution.
27. Enable cutting guides.
28. Show the copy count and live size information.
29. Capture screenshot 04.
30. Create the print sheet.
31. Show the successful save message.
32. Stop Screen Recording.

Name the recording `CropPrint-iPhone-physical-device.mov`.

## Record the iPad workflow

Use one continuous recording. Begin in portrait orientation.

1. Start Screen Recording from Control Center.
2. Return to the Home Screen.
3. Launch CropPrint.
4. Open About CropPrint.
5. Show version 1.0.0 and build 12.
6. Close the About page.
7. Select Choose Photo.
8. Open `06-family-with-pets-landscape.jpg`.
9. Select the Print category.
10. Select the 5x7 crop size.
11. Move the crop rectangle across the group.
12. Resize the crop rectangle from one corner.
13. Rotate the iPad to landscape orientation.
14. Confirm that the two-column layout remains usable.
15. Open Decorate from the More menu.
16. Enter `Autumn Together` in the text field.
17. Select a built-in font.
18. Select a visible text color.
19. Select a frame style.
20. Capture screenshot 02.
21. Close the decoration controls.
22. Move the text layer on the photo.
23. Rotate the text layer with its handle.
24. Select Crop and Save to Photos.
25. Show the successful save message.
26. Stop Screen Recording.

Name the recording `CropPrint-iPad-physical-device.mov`.

## Record the macOS workflow

Record the full display. Close windows that contain private information.

1. Press Shift-Command-5.
2. Select Record Entire Screen.
3. Start the recording.
4. Launch CropPrint from Applications.
5. Open About CropPrint.
6. Show version 1.0.0 and build 12.
7. Close the About window.
8. Select Open Photo.
9. Open `08-mountain-lake-wide.jpg`.
10. Select the 8x10 crop size.
11. Select Landscape orientation.
12. Move the crop rectangle.
13. Resize the crop rectangle from one corner.
14. Capture screenshot 01.
15. Add the text `Mountain Morning`.
16. Change the text font and color.
17. Move the text layer.
18. Rotate the text layer.
19. Capture screenshot 02.
20. Select Crop and Save.
21. Save the output in a temporary review folder.
22. Show the successful export message.
23. Open `16-woman-portrait.jpg`.
24. Select United States Passport.
25. Position the face inside the crop.
26. Capture screenshot 03.
27. Select Create Print Sheet.
28. Select Letter paper.
29. Enable cutting guides.
30. Show the copy count and size details.
31. Capture screenshot 04.
32. Create the sheet.
33. Stop the recording from the menu bar.

Name the recording `CropPrint-macOS-physical-device.mov`.

## Capture the product screenshots

Capture each screen without personal notifications, personal file names, or personal photos.

| Number | Screen | Sample and state |
| --- | --- | --- |
| 01 | Crop selection | `08-mountain-lake-wide.jpg`, 4x6 landscape, off-center crop |
| 02 | Text and frame | `06-family-with-pets-landscape.jpg`, visible text and frame controls |
| 03 | Passport preset | `16-woman-portrait.jpg`, United States Passport crop |
| 04 | Print sheet | United States Passport, 4x6 paper, cut guides, and size details |
| 05 | True-size preview | Calibrated preview with the dimension labels visible |
| 06 | Remote resources | Built-in Google Fonts entries with creator and license details |

Capture all six states on iPhone, iPad, and Mac. Use the same numbering on every platform.

Use these sizes for new product-page captures:

- iPhone: 1206 by 2622 pixels
- iPad: 2064 by 2752 pixels
- macOS: 2560 by 1600 pixels

Confirm the accepted sizes in App Store Connect before uploading replacements.

An iPhone 12 mini screenshot does not satisfy the current required Dynamic Island slot. Use it only as review evidence.

Use the existing Simulator capture process for exact product-page dimensions. Do not stretch a physical-device screenshot.

## Verify build-12 capabilities

### Launch and information

- [ ] The application launches without a crash.
- [ ] The About page shows the expected version, build, and Git SHA.
- [ ] Help explains the crop, decoration, print-sheet, and privacy workflows.
- [ ] Attributions show resource creators and licenses.
- [ ] The application works without an account.
- [ ] The core workflow works without a network connection.

### Photo loading

- [ ] iPhone loads a JPEG photo from Photos.
- [ ] iPhone loads the HEIC format-test photo.
- [ ] iPad loads a JPEG photo from Photos.
- [ ] iPad loads the HEIC format-test photo.
- [ ] Mac opens a JPEG file through Open Photo.
- [ ] Mac opens the repository PNG sample.
- [ ] Mac opens the HEIC format-test photo.
- [ ] Mac accepts a dropped image file.
- [ ] Mac accepts Finder Open With.
- [ ] Mac opens an item from Open Recent.
- [ ] Mac clears the Open Recent menu.

### Crop geometry and presets

- [ ] The centered crop uses the largest possible rectangle.
- [ ] Dragging inside the rectangle moves the crop.
- [ ] Dragging a corner resizes the crop.
- [ ] Resizing preserves the selected aspect ratio.
- [ ] The crop rectangle stays inside the image.
- [ ] Center Crop restores the largest centered rectangle.
- [ ] Portrait and landscape orientations produce different ratios.
- [ ] The saved crop matches the selected rectangle.
- [ ] The saved crop does not use the opposite image region.
- [ ] The Print category contains every documented print size.
- [ ] The Passport and ID category contains every documented preset.
- [ ] The Instagram category contains Story, portrait, and square presets.
- [ ] The iPhone wallpaper category contains every documented device preset.
- [ ] The MacBook wallpaper category contains every documented model preset.
- [ ] The Monitor wallpaper category contains VGA through 8K presets.

### Export behavior

- [ ] iPhone saves a cropped photo to Photos.
- [ ] iPad saves a cropped photo to Photos.
- [ ] Denied Photos access produces a useful error.
- [ ] Mac exports JPEG output.
- [ ] Mac exports PNG output.
- [ ] Mac exports TIFF output.
- [ ] Mac exports HEIC output.
- [ ] Mac saves output beside the source by default.
- [ ] Exported names include the selected preset details.
- [ ] Export never changes the source photo.
- [ ] Exported pixel dimensions match digital presets.

### Text and frames

- [ ] Text appears as a live layer over the photo.
- [ ] The text box moves through direct manipulation.
- [ ] The text box width handle works.
- [ ] The text scale handle works.
- [ ] The text rotation handle works.
- [ ] Built-in fonts display correctly.
- [ ] Each text style displays correctly.
- [ ] Static text colors display correctly.
- [ ] The custom color picker updates the text.
- [ ] Text opacity updates the preview.
- [ ] Each built-in frame style displays correctly.
- [ ] Frame width and opacity update the preview.
- [ ] Remove All Decorations restores the unmodified crop.
- [ ] Exported output includes the selected decorations.

### Remote resources

- [ ] The built-in catalog loads over HTTPS.
- [ ] Each entry shows its creator and license.
- [ ] A Google Font downloads successfully.
- [ ] The downloaded font appears in Decorate.
- [ ] An invalid catalog produces a useful error.
- [ ] Core crop and export features work when the catalog is unavailable.

### Print sheets and true size

- [ ] Each physical passport preset enables Create Print Sheet.
- [ ] Each digital-only passport preset disables Create Print Sheet.
- [ ] General physical print presets enable Create Print Sheet.
- [ ] Paper size changes the sheet dimensions.
- [ ] Paper orientation changes the sheet layout.
- [ ] Image PPI changes JPEG pixel dimensions.
- [ ] Printer DPI changes only the printer-grid information.
- [ ] Cutting guides appear when enabled.
- [ ] The displayed copy count matches the created sheet.
- [ ] The sheet places each photo at the selected physical size.
- [ ] True-size calibration saves after selection.
- [ ] The one-inch calibration line matches a physical ruler.
- [ ] macOS creates a JPEG sheet when memory limits permit.
- [ ] macOS creates a resolution-independent PDF sheet.
- [ ] iPhone saves the completed sheet to Photos.
- [ ] iPad saves the completed sheet to Photos.
- [ ] Oversized raster settings show the documented warning.

### Layout, accessibility, and resilience

- [ ] Light appearance remains readable.
- [ ] Dark appearance remains readable.
- [ ] Larger accessibility text remains usable.
- [ ] VoiceOver labels identify the main controls.
- [ ] iPad portrait layout remains usable.
- [ ] iPad landscape layout remains usable.
- [ ] iPad split-screen layout remains usable.
- [ ] A large sample image does not crash the application.
- [ ] Relaunching the application restores a usable initial state.
- [ ] Repeated exports do not corrupt later output.

## Verify later local-processing features

Do not include this section in build-12 App Review evidence.

- [ ] Exposure updates the live preview and export.
- [ ] Contrast updates the live preview and export.
- [ ] Highlights update the live preview and export.
- [ ] Shadows update the live preview and export.
- [ ] Saturation updates the live preview and export.
- [ ] Hue updates the live preview and export.
- [ ] Sharpness updates the live preview and export.
- [ ] Angle correction keeps the output rectangle filled.
- [ ] Reset restores every adjustment to its default.
- [ ] Passport background replacement works on `16-woman-portrait.jpg`.
- [ ] Social background replacement works on `18-man-portrait-square.jpg`.
- [ ] Hair edges remain acceptable after background replacement.
- [ ] Group photos do not produce misleading person masks.
- [ ] Pets do not replace the selected person mask.
- [ ] White, gray, and blue backgrounds export correctly.
- [ ] Leaving Passport or Instagram restores the original background.
- [ ] Passport head guides appear for supported presets.
- [ ] Passport head guides never appear in exported output.
- [ ] Each guide links to its named official source.
- [ ] The passport alteration warning remains visible.

## Record results

Create one result row for each device and build.

| Date | Device | Operating system | Version and build | Git SHA | Result | Issue link |
| --- | --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | Device model | OS version | 1.0.0 (12) | b9e9fcf | Pass or fail | GitHub issue or none |

Record failures through GitHub Issues. Do not attach private photos or device information that is not needed.

## Submit the App Review response

1. Confirm that all three build-12 recordings passed review.
2. Rename each recording as specified in this guide.
3. Attach the recordings to the App Review message.
4. Copy the response from `AppStore/APP-REVIEW-RESPONSE.md`.
5. Send the response through App Store Connect.
6. Paste the durable details into both platform Notes fields.
7. Resubmit the existing build.
