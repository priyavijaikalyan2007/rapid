# CropPrint App Store metadata

Use one App Store Connect record for iOS and macOS. Both targets use `us.outcrop.apps.cropprint`.

Do not create a separate iPad platform or app record. The iOS binary supports both iPhone and iPad device families.

## Apple identifier configuration

- Apple Developer Team ID: `4JD5A6Q2HL`
- Explicit App ID: `us.outcrop.apps.cropprint`
- Platforms: iOS, iPadOS, and macOS
- Bundle prefix for Outcrop consumer apps: `us.outcrop.apps`
- Future Knobby enterprise prefix: `us.outcrop.knobbyio`
- Future Lyfbits enterprise prefix: `us.outcrop.lyfbits`

Use these selections when you register the CropPrint App ID:

- Capabilities: None
- App Services: None
- Capability Requests: None

Apple enables In-App Purchase by default for an explicit App ID. Leave that default unchanged, but do not configure an In-App Purchase product.

CropPrint does not use Sign in with Apple, iCloud, push notifications, App Groups, Apple Pay, Associated Domains, or Keychain Sharing.

Local photo adjustments use Apple Core Image and Vision. These frameworks require no App ID capability or additional entitlement.

The App ID page does not configure the following local permissions. The Xcode project contains them where required.

### macOS target capabilities

- App Sandbox: Enabled
- User Selected Files: Read/Write
- Outgoing Connections (Client): Enabled
- App-scoped security bookmarks: Enabled in the entitlements file
- Hardened Runtime: Enabled in the build settings

### iPhone and iPad target capabilities

- Supported device families: iPhone and iPad
- iPhone orientations: Portrait
- iPad orientations: Portrait, Portrait Upside Down, Landscape Left, and Landscape Right
- App ID capabilities: None
- Photos access: Add only, declared through `NSPhotoLibraryAddUsageDescription`
- Outgoing HTTPS access: No App ID capability required

Do not enable a capability for possible future use. Enable a new capability only when the application source requires it.

## Shared information

- Name: CropPrint
- Subtitle: Exact photo crops and sheets
- Primary category: Photo & Video
- Secondary category: Utilities
- SKU: cropprint-2026
- Privacy policy URL: https://outcrop.us/privacy/
- Support URL: https://outcrop.us/support/
- Source URL: https://github.com/priyavijaikalyan2007/rapid
- Copyright: 2026 Outcrop Inc
- Price: Free

## Keywords

```text
photo,passport,ID,sheet,wallpaper,resize,aspect ratio,4x6,5x7,social media,frame,text
```

## Description

CropPrint helps people prepare personal photos for standard prints, passport or identity applications, social media, and screen backgrounds. It removes manual aspect-ratio calculations and never stretches the image.

Choose a photo and select a preset. Move or resize the fixed-ratio crop rectangle until it contains the area that you want. CropPrint exports only that area and keeps the source photo unchanged.

Built-in presets include:

• Common print sizes from 4x6 through 24x36
• Passport and identity-photo sizes for several countries and regions
• Instagram Story, portrait, and square formats
• iPhone and MacBook wallpaper sizes
• Common monitor resolutions from VGA through 8K

Create print sheets that place multiple passport or identity photos at the selected physical size. Choose the paper size, printer resolution, margins, and cutting guides.

Add a movable text layer or a photo frame and preview the result on the image. Change the text font, style, color, opacity, size, position, and rotation.

Use live size details and a ruler-calibrated true-size preview to inspect expected print dimensions before export.

CropPrint is designed for individuals, families, photographers, travelers, students, and anyone preparing personal photos. It is a public consumer utility. It is not limited to a business, school, employer, or other organization.

Passport presets set the crop's outer dimensions only. Rules can change. Confirm current government requirements before submitting a photo.

CropPrint processes photos on the device. It has no account, advertising, analytics, tracking, paid content, or subscription. The optional resource library downloads licensed fonts and frames only when you request them.

CropPrint is open-source software.

## Promotional text

Crop personal photos without distortion. Use print, passport, social, and wallpaper presets, then create exact-size photo sheets with cut marks.

## Review notes

Use the following notes for version 1.0.0, build 12. Add the same relevant text to each platform's App Review Information section.

CropPrint is a public consumer photo utility for individuals and families. It prepares existing photos for prints, passport or identity applications, social media, and screen backgrounds. It replaces manual aspect-ratio calculations with a fixed-ratio crop rectangle and exact-size export presets.

No setup, account, login, registration, demo credentials, purchase, subscription, or paid content is required. The app contains no shared user-generated content. Reviewers can use any nonprivate photo already on the test device. A sample file is available at:

```text
https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/cropprint/AppStore/Media/Source/sample-landscape.png
```

On iPhone or iPad, select Choose Photo and choose an image through the system photo picker. Select a category and crop size. Move or resize the crop rectangle. Select Crop and Save to Photos. The app requests add-only Photos access when it saves the result.

To test a passport print sheet, select Passport and ID. Select a physical preset, such as United States Passport. Select Create Print Sheet. Choose the paper, resolution, margins, and cut-mark options. Digital-only passport presets do not offer print sheets because they have no physical dimensions.

On macOS, use File > Open Photo or drag an image into the window. Select a crop size, move or resize the rectangle, and select Crop and Save. The app saves a new file beside the source. It never changes the source file. The app uses user-selected file access under App Sandbox.

Core photo processing runs locally through Apple platform frameworks. The app does not upload photos or crop settings.

The app does not use authentication, payment processors, advertising networks, analytics services, cloud storage, server-side processing, or external artificial-intelligence services.

Remote Resources is optional and is not required for core functionality. When the reviewer requests a download, the app connects to GitHub and `raw.githubusercontent.com`. Built-in entries download open-source Google Fonts and their Open Font License files from the official Google Fonts repository. The app shows licenses and attributions.

The app provides the same features in all regions. Country and region names identify passport crop dimensions. These presets are available worldwide and do not guarantee acceptance by any government.

CropPrint is not a government service, identity-verification service, medical product, financial product, or other regulated service. It does not include protected third-party content. Optional fonts use open-source licenses. CropPrint itself uses the MIT License.

A physical-device recording is attached to the corresponding App Review message. The recording starts with app launch and shows the normal workflow. There are no account, deletion, shared-content, or paid-feature flows to demonstrate.

## App privacy answers

- Tracking: No
- Data collection: No data collected by the developer
- Advertising: No
- Analytics: No
- Third-party SDKs: None

Confirm these answers again before each submission. Update them if the application or remote-resource service changes.

## Export compliance

CropPrint does not implement encryption. It uses Apple networking frameworks for HTTPS resource downloads. Both targets set `ITSAppUsesNonExemptEncryption` to `false`.

## Screenshot plan

Capture real application screens without private photos:

1. Crop rectangle on a landscape photo
2. Print-size and orientation controls
3. Text decoration controls and live preview
4. Passport-photo preset
5. Passport print-sheet layout
6. Remote licensed-resource library

Create separate screenshot sets for iPhone, iPad, and macOS. Use the exact sizes that App Store Connect requests.

The iPad screenshots must show the adaptive two-column layout in a regular-width window.

## Age rating assumptions

CropPrint contains no built-in objectionable content, social features, purchases, gambling, unrestricted web browsing, or user accounts. Users can open their own photos.
