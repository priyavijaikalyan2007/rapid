# Publishing CropPrint

This guide describes how to publish CropPrint for macOS and iPhone. Complete the steps in order because later steps depend on earlier account and signing work.

## Current release setup

The repository already includes these release controls:

- Both applications use the bundle identifier `us.outcrop.apps.cropprint`.
- The Apple Developer Team ID is stored in `config/apple-developer.env`.
- The applications can use one multi-platform App Store Connect record.
- Both products include `src/cropprint/Shared/PrivacyInfo.xcprivacy`.
- The privacy manifest declares no tracking and no developer data collection.
- The privacy manifest declares the app-only `UserDefaults` reason `CA92.1`.
- Both products declare that they do not use nonexempt encryption.
- The macOS target uses App Sandbox.
- Build information includes the semantic version, build number, and source Git SHA.
- Upload scripts reject dirty source trees and repeated uploads.

The repository build verifies the macOS application, iPhone simulator application, and iPhone device application.

## Distribution model

Use one App Store Connect record for the macOS and iOS versions. Both targets use the same bundle identifier for this purpose.

Use these initial values:

- Application name: CropPrint
- Bundle identifier: `us.outcrop.apps.cropprint`
- SKU: `cropprint-2026`
- Platforms: iOS and macOS
- Price: Free
- Primary category: Photo & Video
- Secondary category: Utilities

The complete proposed listing appears in `src/cropprint/AppStore/metadata.md`.

## Apple account preparation

Complete these actions through your Apple accounts:

1. Join the Apple Developer Program.
2. Wait for Apple to activate the membership.
3. Accept the current agreements in App Store Connect.
4. Add your Apple account in Xcode Settings.
5. Confirm that Xcode shows your developer team.

Do not store an Apple password, private key, signing certificate, or provisioning profile in this repository.

## Xcode signing setup

Configure each application target:

1. Open `src/cropprint/CropPrint.xcodeproj`.
2. Select the `CropPrint` macOS target.
3. Open **Signing & Capabilities**.
4. Enable **Automatically manage signing**.
5. Select your developer team.
6. Confirm the bundle identifier is `us.outcrop.apps.cropprint`.
7. Repeat these steps for the `CropPrint Mobile` target.

The macOS target must retain these sandbox permissions:

- User-selected file read and write access
- App-scoped security bookmarks
- Outgoing network connections

The iPhone target requires add-only Photos access when it saves an image.

## Physical-device testing

Test the iPhone application on at least one physical iPhone before TestFlight.

1. Connect the iPhone to the Mac.
2. Trust the Mac when the iPhone requests confirmation.
3. Enable Developer Mode on the iPhone.
4. Select the `CropPrint Mobile` scheme.
5. Select the connected iPhone as the run destination.
6. Press **Command-R**.

Test these behaviors:

- Open portrait and landscape photos.
- Open JPEG, PNG, and HEIC photos.
- Move and resize the crop rectangle.
- Confirm that the crop keeps its aspect ratio.
- Save a crop to Photos.
- Deny Photos permission and confirm the error message.
- Create physical passport print sheets.
- Add, move, resize, and rotate text.
- Download a remote font and frame.
- Process a large photo without excessive memory use.
- Test light and dark appearance.
- Test larger accessibility text sizes.

Test the signed macOS application with files from these locations:

- Pictures
- Downloads
- iCloud Drive
- An external drive

Also test Open Recent, drag and drop, Finder Open With, exports, print sheets, remote resources, and Reveal in Finder.

## Privacy and support pages

The public website is under `src/web`. It contains the application catalog, privacy policy, terms, and support page.

The publisher is Outcrop Inc, a Washington company. The website uses `admin@outcrop.us` for legal and support contact.

Use these addresses after the custom domains are active:

- `https://outcrop.us/privacy/`
- `https://outcrop.us/support/`

The `www.outcrop.us` hostname serves the same website. Use the root-domain addresses for the App Store product page.

Publish the website after you add the domain to Cloudflare:

1. Add `outcrop.us` to the Cloudflare account.
2. Confirm that no conflicting records use the two website hostnames.
3. Configure the Cloudflare GitHub secrets.
4. Enable the website publishing repository variable.
5. Push the website changes to `main`.
6. Open both public addresses.
7. Confirm that each page loads without authentication.

Apple requires a public privacy policy address. Do not submit the application while this address returns an error.

## App Store Connect record

Create the record before you upload the first archive:

1. Open App Store Connect.
2. Select **Apps**.
3. Select the add button.
4. Select **New App**.
5. Select iOS and macOS.
6. Enter the name, language, bundle identifier, and SKU.
7. Create the record.

Add the information from `src/cropprint/AppStore/metadata.md`. Confirm all text before submission.

Complete these required sections:

- Application description
- Keywords and categories
- Support address
- Privacy policy address
- Age rating
- Availability and price
- Copyright
- App privacy answers
- Review contact information
- Review notes

The current privacy answers are:

- Tracking: No
- Data collected by the developer: No
- Advertising: No
- Analytics: No
- Third-party software development kits: None

Review these answers before each release. Change them if the application or remote-resource service changes.

## Screenshots

Use nonprivate photos in all screenshots. Capture separate screenshot sets for iPhone and macOS.

Show these main workflows:

1. A crop rectangle on a landscape photo.
2. Print-size and orientation controls.
3. Text controls with a live preview.
4. A physical passport-photo preset.
5. A passport print-sheet layout.
6. The licensed remote-resource library.

Use the exact screenshot sizes that App Store Connect requests. Do not add device frames or marketing claims unless they remain accurate.

## Version and build information

The semantic version is stored in `src/cropprint/VERSION`.

Change the version with this command:

```sh
./src/cropprint/scripts/set-version.sh 1.1.0
```

Each build includes:

- Semantic version
- Numeric build number
- Source Git SHA

The About page shows this information. Include it in every defect report.

The scripts derive the default build number from the Git commit count. Set `BUILD_NUMBER` only when App Store Connect requires a larger unused number.

## Local release verification

Run these commands from the repository root:

```sh
./clean.sh
./build.sh
```

The complete build must pass before archiving. It runs the tests and builds all supported products.

Check the current version:

```sh
src/cropprint/scripts/build-metadata.sh
```

The App Store scripts require a clean Git commit. They stop when the source tree contains changes or no Git commit exists.

## Create signed archives

Run this command from `src/cropprint`:

```sh
./scripts/archive-app-store.sh all
```

The script reads the Outcrop Inc Team ID from `config/apple-developer.env`.

Use one platform when necessary:

```sh
./scripts/archive-app-store.sh ios
./scripts/archive-app-store.sh macos
```

The archives appear under `src/cropprint/build/AppStore`.

Open each archive in Xcode Organizer. Validate the archive before upload.

## Upload to App Store Connect

Upload existing archives with this command:

```sh
CONFIRM_APP_STORE_UPLOAD=YES \
./scripts/upload-app-store.sh all
```

Archive and upload in one operation with this command:

```sh
CONFIRM_APP_STORE_UPLOAD=YES \
./scripts/publish-app-store.sh all
```

An upload does not submit the applications for App Review. It only sends the builds to App Store Connect.

The upload script records the last uploaded Git SHA. It refuses another upload from the same commit.

Use `FORCE_APP_STORE_UPLOAD=YES` only when Apple requires another upload from the same source commit. Always use a new build number.

## App Store Connect API key

Local interactive uploads can use the Apple account configured in Xcode.

For unattended uploads, create an App Store Connect API key. Set these variables:

```sh
export APP_STORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_ABC123.p8
export APP_STORE_CONNECT_API_KEY_ID=ABC123
export APP_STORE_CONNECT_API_ISSUER_ID=00000000-0000-0000-0000-000000000000
```

Store the private key outside the repository. Apple permits each private key file to be downloaded only once.

## TestFlight

After the upload finishes, wait for Apple to process the iOS build.

1. Open the CropPrint record in App Store Connect.
2. Open **TestFlight**.
3. Complete any export-compliance questions.
4. Create an internal testing group.
5. Add the processed build to the group.
6. Invite household testers.
7. Install the build through the TestFlight application.

TestFlight builds expire after 90 days. Upload a newer build when necessary.

Test the complete release workflow again through TestFlight. Confirm the version and Git SHA on the About page.

## Submit for App Review

Submit only after physical-device and TestFlight testing succeeds.

1. Select the processed build for each platform version.
2. Confirm the screenshots and product-page text.
3. Confirm the privacy answers.
4. Complete the review contact information.
5. Add the review notes.
6. Resolve all App Store Connect warnings.
7. Select **Add for Review**.
8. Submit the review.

Use manual release for the first version. This choice lets you inspect the approved product page before release.

## GitHub Actions publishing

The App Store workflow remains disabled until the repository variable `ENABLE_APP_STORE_PUBLISH` equals `true`.

Run the workflow manually with `publish` disabled to validate the workflow and application tests. This mode does not sign or upload applications.

Set `publish` during a manual run only when you intend to upload both applications.

Configure these encrypted GitHub secrets first:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`

Keep automatic publishing disabled until one local archive and TestFlight upload succeeds.

After you enable it, the workflow reacts only to CropPrint changes on `main`. It uploads builds but does not submit them for review.

A workflow-file change starts a test-only validation run. It does not publish CropPrint without an application source change.

## Release checklist

Before each release, confirm all of these items:

- The source tree has a clean Git commit.
- The semantic version is correct.
- The build number is larger than prior uploaded builds.
- The complete local build passes.
- The privacy manifest matches the source behavior.
- The App Store privacy answers match the source behavior.
- The privacy and support pages are public.
- The About page shows the expected version and Git SHA.
- Physical-device tests pass.
- macOS sandbox tests pass.
- TestFlight tests pass.
- Screenshots and descriptions match the current interface.
- Remote-resource licenses and attributions are accurate.
- App Store Connect shows no unresolved warnings.

## External distribution for macOS

The Mac App Store process is separate from direct macOS distribution.

For direct downloads, sign with a Developer ID Application certificate. Then notarize and staple the application before publishing it.

The tag-based `.github/workflows/release.yml` workflow prepares a signed and notarized macOS GitHub release. Configure its certificate and notarization secrets before you create a release tag.

Do not distribute the unsigned development package as a normal public release. Gatekeeper will warn users because the package lacks Developer ID signing and notarization.
