# CropPrint App Store metadata

Use one App Store Connect record for iOS and macOS. Both targets use `us.outcrop.apps.cropprint`.

## Apple identifier configuration

- Apple Developer Team ID: `4JD5A6Q2HL`
- Explicit App ID: `us.outcrop.apps.cropprint`
- Platforms: iOS and macOS
- Bundle prefix for Outcrop consumer apps: `us.outcrop.apps`
- Future Knobby enterprise prefix: `us.outcrop.knobbyio`
- Future Lyfbits enterprise prefix: `us.outcrop.lyfbits`

Use these selections when you register the CropPrint App ID:

- Capabilities: None
- App Services: None
- Capability Requests: None

Apple enables In-App Purchase by default for an explicit App ID. Leave that default unchanged, but do not configure an In-App Purchase product.

CropPrint does not use Sign in with Apple, iCloud, push notifications, App Groups, Apple Pay, Associated Domains, or Keychain Sharing.

The App ID page does not configure the following local permissions. The Xcode project contains them where required.

### macOS target capabilities

- App Sandbox: Enabled
- User Selected Files: Read/Write
- Outgoing Connections (Client): Enabled
- App-scoped security bookmarks: Enabled in the entitlements file
- Hardened Runtime: Enabled in the build settings

### iPhone target capabilities

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
- Source URL: https://github.com/pvk2007/rapid
- Copyright: 2026
- Price: Free

## Keywords

```text
crop,photo,print,passport,sheet,frame,text,wallpaper,instagram,aspect ratio
```

## Description

CropPrint crops photos to exact aspect ratios without stretching the image.

Choose a standard print size, passport-photo size, social-media format, phone wallpaper, or monitor resolution. Move and resize the fixed-ratio crop area until it contains the part of the photo that you want.

Add a text layer or photo frame and see the result directly on the image. Change the font, style, color, opacity, size, position, and rotation.

Create print sheets that place multiple passport or identity photos at their correct physical size. Select the paper size, orientation, resolution, margins, and cutting guides.

CropPrint processes photos on your device. It has no account, advertising, analytics, or tracking. The optional resource library downloads licensed fonts and frames only when you request them.

CropPrint is open-source software.

## Promotional text

Crop photos for prints, passports, social media, and screens without distortion. Add text, frames, and exact-size print sheets.

## Review notes

CropPrint has no login or account.

On iPhone, select Choose Photo and choose an image through the system photo picker. Move or resize the crop rectangle. Select Crop and Save to Photos. The application requests add-only Photos access at that point.

To test a passport print sheet, select a physical Passport Print preset. Then select Create Print Sheet and choose the paper settings.

Remote Resources is optional. The built-in entries download open-source Google Fonts from the official Google Fonts repository on GitHub.

On macOS, use File > Open Photo or drag an image into the window. The application uses user-selected file access under App Sandbox.

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

Create separate screenshot sets for iPhone and macOS. Use the exact sizes that App Store Connect requests.

## Age rating assumptions

CropPrint contains no built-in objectionable content, social features, purchases, gambling, unrestricted web browsing, or user accounts. Users can open their own photos.
