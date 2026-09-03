# Rapid applications

This repository contains small applications under `src`. Each application owns its source, tests, build scripts, and documentation.

## Repository structure

```text
rapid/
├── build.sh
├── clean.sh
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
└── src/
    ├── cropprint/
        ├── build.sh
        ├── clean.sh
        ├── CropPrint/
        ├── CropPrintMobile/
        ├── CropPrintTests/
        ├── CropPrint.xcodeproj/
        ├── RemoteCatalog/
        ├── scripts/
        └── README.md
    └── web/
        ├── build.sh
        ├── clean.sh
        ├── deploy.sh
        ├── site/
        ├── site.config.json
        ├── wrangler.jsonc
        └── README.md
```

Add each future application as `src/<app-name>`. Give each application an executable `build.sh` and `clean.sh` script.

## Repository scripts

Run repository scripts from the repository root.

### Build all applications

```sh
./build.sh
```

The root script calls each `src/<app-name>/build.sh` script. It stops when an application build fails.

Pass a supported build mode to every application:

```sh
./build.sh test
./build.sh macos
./build.sh ios
```

Build only the public website:

```sh
./build.sh web
```

CropPrint supports `all`, `test`, `macos`, and `ios`. The default mode is `all`.

The website supports `all`, `web`, and `test`. It skips `macos` and `ios` builds.

The full CropPrint build performs these tasks:

1. Run the macOS unit tests.
2. Create a universal unsigned macOS package.
3. Build the iPhone simulator application.
4. Build the unsigned iPhone device application.

Build outputs go under `src/cropprint/build`. Git ignores this directory.

Each build reads `src/cropprint/VERSION`. CropPrint currently uses semantic version `1.0.0`.

The build adds the Git SHA and numeric build number to both applications. A local build from changed files adds `-dirty`.

Change the semantic version with this command:

```sh
./src/cropprint/scripts/set-version.sh 1.1.0
```

The About page shows the semantic version, Git SHA, and build number. This information identifies the source for a reported bug.

### Clean all applications

```sh
./clean.sh
```

The root script calls each application cleanup script. CropPrint removes build outputs, derived data, Xcode user data, Swift caches, and macOS metadata.

The cleanup script does not remove source files, project settings, documentation, or remote catalog definitions.

## Public website

The static public website lives under `src/web`. It contains the application catalog, support page, privacy policy, and terms.

The catalog uses each application's actual icon. Edit `src/web/site.config.json` to add an application or change public details.

Build and validate the website:

```sh
./src/web/build.sh web
```

Preview the website through Cloudflare Wrangler:

```sh
cd src/web
npm install
./preview.sh
```

Run a deployment check:

```sh
cd src/web
./deploy.sh --dry-run
```

See [`src/web/README.md`](src/web/README.md) for deployment, custom-domain, and Cloudflare Workers Builds instructions.

## CropPrint scripts

Run these commands from `src/cropprint`.

Create a normal unsigned development package:

```sh
./build.sh macos
```

Create App Store archives without uploading them:

```sh
./scripts/archive-app-store.sh all
```

Use `macos` or `ios` instead of `all` to archive one platform. Set `BUILD_NUMBER` to override the Xcode project build number.

Upload existing archives to App Store Connect:

```sh
CONFIRM_APP_STORE_UPLOAD=YES ./scripts/upload-app-store.sh all
```

Archive and upload in one operation:

```sh
CONFIRM_APP_STORE_UPLOAD=YES \
./scripts/publish-app-store.sh all
```

An upload sends a build to App Store Connect. It does not submit the build for App Review or release the application.

The upload script records the last uploaded SHA under `src/cropprint/.publish-state`. The cleanup script preserves this ignored local state.

The upload script refuses a repeated upload by default.

Set `FORCE_APP_STORE_UPLOAD=YES` only when you must upload the same commit again.

## Apple signing setup

See [`PUBLISHING.md`](PUBLISHING.md) for the complete physical-device, TestFlight, App Store, and direct macOS release process.

Complete these tasks before you use the App Store scripts:

1. Join the Apple Developer Program.
2. Accept the current agreements in App Store Connect.
3. Add your Apple account in Xcode Settings.
4. Select your development team for both CropPrint targets.
5. Register the macOS and iOS bundle identifiers.
6. Create the application record in App Store Connect.
7. Add application icons, screenshots, privacy details, and store metadata.
8. Test the final archives before upload.

Xcode can manage signing through the account in Xcode Settings. The scripts pass `-allowProvisioningUpdates` for automatic signing.

For unattended builds, set all three App Store Connect API key variables:

```sh
export APP_STORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_ABC123.p8
export APP_STORE_CONNECT_API_KEY_ID=ABC123
export APP_STORE_CONNECT_API_ISSUER_ID=00000000-0000-0000-0000-000000000000
```

Do not store the private key or credentials in this repository. The `.gitignore` file excludes common signing files and local environment files.

## GitHub Actions publishing

The Build workflow creates versioned builds for every push to `main` and for pull requests.

The App Store workflow reacts only to CropPrint source, project, or `VERSION` changes on `main`. Unrelated changes do not publish CropPrint.

Changes to the workflow file start a test-only validation run. They do not publish CropPrint without an application source change.

The publishing job remains disabled until you create the repository variable `ENABLE_APP_STORE_PUBLISH` with value `true`.

You can start the App Store workflow manually with `publish` disabled. This mode tests CropPrint without signing or uploading an archive.

Set `publish` during a manual run only when you intend to upload both applications.

The public Team ID is stored in `config/apple-developer.env`. Configure these encrypted GitHub secrets before publishing:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`

The workflow tests CropPrint before it archives and uploads both platforms. Each uploaded application contains its semantic version and source Git SHA.

## Mac App Store requirement

Apple requires App Sandbox for Mac App Store applications. The CropPrint macOS target enables App Sandbox for Debug and Release builds.

CropPrint allows user-selected file access and outgoing network connections. It stores security-scoped bookmarks for recent photos.

Before the first store release, test file access and remote resources in a signed archive. Include external drives and iCloud Drive in these tests.

## App Store privacy and product pages

The macOS and iOS targets use `us.outcrop.apps.cropprint`. Create one App Store Connect record for both platforms.

Both targets include `src/cropprint/Shared/PrivacyInfo.xcprivacy`. The manifest declares no tracking, no collected data, and the app-only `UserDefaults` reason.

App Store copy, review notes, privacy answers, and the screenshot plan are in `src/cropprint/AppStore/metadata.md`.

The Cloudflare website under `src/web` provides the public privacy and support addresses for Outcrop Inc.

Use `https://outcrop.us/privacy/` and `https://outcrop.us/support/` for the App Store product page.

## Apple references

- [Distributing applications with Xcode](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Creating an App Store Connect application record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- [Uploading builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)

## Application documentation

See [`src/cropprint/README.md`](src/cropprint/README.md) for CropPrint features, local development, packaging, and privacy details.
