# CropPrint App Store publishing checklist

This checklist tracks the first CropPrint release.

## Current release

- Version: `1.0.0`
- Build: `12`
- Git commit: Read the exact SHA from the archive or About page.
- Apple Developer Team: `4JD5A6Q2HL`
- Bundle identifier: `us.outcrop.apps.cropprint`
- Platforms: macOS, iPhone, and iPad
- Release method: Manual release after Apple approval

## Current status

- [x] Join the Apple Developer Program.
- [x] Register the application identifier.
- [x] Create the multi-platform App Store Connect record.
- [x] Configure automatic signing for both targets.
- [x] Register Shreya's iPhone with the Outcrop Inc team.
- [x] Test the application on Shreya's physical iPhone 12 mini.
- [x] Test the iPhone and iPad layouts in Simulator.
- [x] Run the automated tests.
- [ ] Recreate the macOS archive with its matching dSYM.
- [ ] Recreate the iOS and iPadOS archive as build `12`.
- [ ] Validate both archives in Xcode Organizer.
- [ ] Upload both archives to App Store Connect.
- [ ] Test the uploaded build through TestFlight.
- [ ] Complete the iOS App Store page.
- [ ] Complete the macOS App Store page.
- [ ] Submit both platform versions for review.
- [ ] Release the approved version manually.

## 1. Validate the archives

Validate both archives before any upload.

### macOS

1. Open `build/AppStore/CropPrint-macOS.xcarchive`.
2. Wait for Xcode Organizer to open.
3. Select the CropPrint macOS archive.
4. Select **Validate App**.
5. Select the Outcrop Inc distribution identity.
6. Keep automatic signing enabled.
7. Continue through the validation screens.
8. Save any warning or error text.
9. Mark the macOS archive complete below.

- [ ] The macOS archive passes validation.

### iPhone and iPad

1. Open `build/AppStore/CropPrint-iOS.xcarchive`.
2. Wait for Xcode Organizer to open.
3. Select the CropPrint Mobile archive.
4. Select **Validate App**.
5. Select the Outcrop Inc distribution identity.
6. Keep automatic signing enabled.
7. Continue through the validation screens.
8. Save any warning or error text.
9. Mark the iOS archive complete below.

- [ ] The iPhone and iPad archive passes validation.

Stop before upload if either validation reports an error.

## 2. Upload the archives

Use the script after both validations succeed.

Run this command from `src/cropprint`:

```sh
CONFIRM_APP_STORE_UPLOAD=YES ./scripts/upload-app-store.sh all
```

The command uploads both existing archives. It does not submit either application for review.

- [ ] The macOS upload succeeds.
- [ ] The iOS and iPadOS upload succeeds.
- [ ] App Store Connect shows both builds.

If Apple rejects build `12`, fix the issue and create a new commit. The next build must use a larger number.

## 3. Wait for Apple processing

1. Open the CropPrint record in App Store Connect.
2. Open the build section for iOS.
3. Wait until build `12` finishes processing.
4. Open the build section for macOS.
5. Wait until build `12` finishes processing.
6. Answer any export-compliance questions.
7. Confirm that Apple reports no processing error.

- [ ] The iOS build finishes processing.
- [ ] The macOS build finishes processing.
- [ ] Export compliance is complete.

CropPrint sets `ITSAppUsesNonExemptEncryption` to `false` for both platforms.

## 4. Test through TestFlight

### iPhone and iPad

1. Open **TestFlight** in App Store Connect.
2. Create an internal testing group.
3. Add build `12` to the group.
4. Add the household testers.
5. Install CropPrint through the TestFlight application.
6. Repeat the release tests.

### macOS

1. Add the macOS build to an internal TestFlight group.
2. Install the Mac build through TestFlight.
3. Test file access under App Sandbox.
4. Test Pictures, Downloads, iCloud Drive, and an external drive.

- [ ] The TestFlight iPhone test passes.
- [ ] The TestFlight iPad test passes.
- [ ] The TestFlight macOS test passes.
- [ ] The About page shows version `1.0.0`, build `12`, and the archive Git SHA.

## 5. Complete the product pages

Use `AppStore/metadata.md` for the prepared text and answers.

Complete these fields for iOS and macOS:

- [ ] Application description
- [ ] Promotional text
- [ ] Keywords
- [ ] Primary and secondary categories
- [ ] Support URL: `https://outcrop.us/support/`
- [ ] Privacy URL: `https://outcrop.us/privacy/`
- [ ] Copyright: `2026 Outcrop Inc`
- [ ] Price: Free
- [ ] Availability
- [ ] Age rating
- [ ] Content-rights declaration
- [ ] App privacy answers
- [ ] Review contact information
- [ ] Review notes

The private review contact can use an Outcrop email address. Apple does not publish that contact.

Use these privacy answers unless the application behavior changes:

- Tracking: No
- Data collected by the developer: No
- Advertising: No
- Analytics: No
- Third-party software development kits: None

## 6. Upload screenshots

Use photos that contain no private information.

Upload separate screenshot sets for:

- [ ] iPhone
- [ ] iPad
- [ ] macOS

Show these workflows:

1. A crop rectangle on a photo.
2. The category and crop-size controls.
3. The text controls and live preview.
4. A physical passport-photo preset.
5. A passport print sheet.
6. The true-size preview.
7. The licensed remote-resource library.

Use only the screenshot dimensions that App Store Connect requests.

## 7. Attach the builds

1. Open the iOS version page.
2. Select build `12`.
3. Save the iOS version page.
4. Open the macOS version page.
5. Select build `12`.
6. Save the macOS version page.

- [ ] Build `12` is attached to the iOS version.
- [ ] Build `12` is attached to the macOS version.

## 8. Submit for review

1. Resolve every App Store Connect warning.
2. Review the product-page text.
3. Review the screenshots.
4. Review the privacy answers.
5. Review the App Review notes.
6. Select **Add for Review**.
7. Confirm that both platforms are included.
8. Submit the review.

- [ ] The iOS version is waiting for review.
- [ ] The macOS version is waiting for review.

## 9. Release after approval

1. Read any messages from App Review.
2. Resolve any rejection before creating another build.
3. Inspect the approved product pages.
4. Release version `1.0.0` manually.
5. Verify the public App Store pages.
6. Install the public version on one iPhone.
7. Install the public version on one iPad.
8. Install the public version on one Mac.

- [ ] CropPrint is available for iPhone and iPad.
- [ ] CropPrint is available for macOS.
- [ ] The public application matches build `12`.

## Later automation

Keep automatic App Store uploads disabled until the first local upload succeeds.

The GitHub workflow needs these encrypted secrets:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`

Set `ENABLE_APP_STORE_PUBLISH` to `true` only after the local release process works.

The durable reference guide remains at the repository root in `PUBLISHING.md`.
