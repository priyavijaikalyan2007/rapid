# CropPrint App Review response

Use this response for the App Review information request for version 1.0.0, build 12.

Attach these physical-device recordings before you send the response:

- `CropPrint-iPhone-physical-device.mov`
- `CropPrint-iPad-physical-device.mov`
- `CropPrint-macOS-physical-device.mov`

Each recording must start with launching CropPrint. Record each device on the latest stable operating system that the device supports.

Copy the following response into the App Review message:

```text
Hello App Review,

CropPrint version 1.0.0, build 12, is complete and ready for review. We tested the submitted build on physical Apple devices. The attached recordings start with app launch and show the normal workflow on iPhone, iPad, and Mac.

1. Screen recordings

The attached physical-device recordings show photo selection, preset selection, crop movement and resizing, export, and print-sheet creation. CropPrint has no account, registration, login, account deletion, shared user-generated content, purchase, subscription, or paid-feature flow.

2. Purpose and target audience

CropPrint is a public consumer photo utility for individuals and families. It prepares existing photos for standard prints, passport or identity applications, social media, and screen backgrounds. It replaces manual aspect-ratio calculations with a fixed-ratio crop rectangle and exact-size export presets. It is not limited to a business, school, employer, or other organization.

3. Setup and access instructions

No setup, account, login, credentials, purchase, or subscription is required. Reviewers can use any nonprivate photo on the test device. A public sample is available here:

https://raw.githubusercontent.com/priyavijaikalyan2007/rapid/main/src/cropprint/AppStore/Media/Source/sample-landscape.png

On iPhone or iPad, select Choose Photo. Select a category and crop size. Move or resize the crop rectangle. Select Crop and Save to Photos.

To test a print sheet, select Passport and ID. Select a physical preset, such as United States Passport. Select Create Print Sheet. Choose the paper settings and create the sheet.

On macOS, use File > Open Photo or drag an image into the window. Select a crop size. Move or resize the rectangle. Select Crop and Save. The app writes a new file beside the source and does not change the source.

4. External services, tools, and platforms

Core photo processing runs locally through Apple platform frameworks. The app does not upload photos or crop settings.

The app uses the Apple system photo picker and Photos library on iPhone and iPad. It uses the Apple file picker and App Sandbox on macOS.

CropPrint does not use authentication, payment processors, advertising networks, analytics services, cloud storage, server-side photo processing, or external artificial-intelligence services.

Remote Resources is optional and is not required for core functionality. When requested by the user, it connects to GitHub and raw.githubusercontent.com. Built-in entries download open-source Google Fonts and their Open Font License files from the official Google Fonts repository. The app shows the related licenses and attributions.

5. Regional differences

CropPrint provides the same features in all regions. Country and region names identify passport crop dimensions. These presets are available worldwide and do not guarantee acceptance by any government.

6. Regulated industries and protected material

CropPrint is not a government service, identity-verification service, medical product, financial product, or other regulated service. Passport presets are geometry aids for users. Users must confirm the current requirements of the relevant authority.

The app does not include protected third-party content. Optional fonts use open-source licenses. CropPrint itself uses the MIT License. No authorization credentials or regulatory documents are required.
```

Add the information from `metadata.md` to the Notes field for both platform versions. Apple limits the Notes field to 4,000 bytes.

Do not claim that physical-device testing passed until every attached recording and test uses the submitted build.
