#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# File GUID: b930134b-0836-475b-9670-620bd29ed6b9
# COMPONENT: MonoMark release resource contracts
# PURPOSE: Catch missing privacy declarations and resource membership before packaging.

import json
from pathlib import Path
import plistlib
import subprocess
import struct
import unittest


APPLE = Path(__file__).resolve().parents[1] / "src/app/monomark/apple"


class MonoMarkReleaseTests(unittest.TestCase):
    """Verify authored release resources, without claiming signed-build acceptance."""

    def mobile_configuration(self):
        """Read target membership from the real Xcode project rather than matching source text."""
        project = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(APPLE / "MonoMark.xcodeproj/project.pbxproj")],
            capture_output=True, text=True, check=True,
        )
        objects = json.loads(project.stdout)["objects"]
        target = next(value for value in objects.values()
                      if value.get("isa") == "PBXNativeTarget" and value.get("name") == "MonoMarkMobile")
        return objects, target

    def test_mobile_uses_the_existing_store_identity_and_outcrop_team(self):
        objects, target = self.mobile_configuration()
        for ref in objects[target["buildConfigurationList"]]["buildConfigurations"]:
            settings = objects[ref]["buildSettings"]
            self.assertEqual(settings["PRODUCT_BUNDLE_IDENTIFIER"], "us.outcrop.MonoMark")
            self.assertEqual(settings.get("DEVELOPMENT_TEAM"), "4JD5A6Q2HL")
            self.assertEqual(settings["TARGETED_DEVICE_FAMILY"], "1,2")

    def test_mobile_test_fixture_is_debug_only(self):
        objects, target = self.mobile_configuration()
        for ref in objects[target["buildConfigurationList"]]["buildConfigurations"]:
            config = objects[ref]
            conditions = config["buildSettings"].get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "")
            self.assertEqual("DEBUG" in conditions.split(), config["name"] == "Debug")

    def test_mobile_icon_has_the_required_opaque_dimensions(self):
        catalog = APPLE / "Mobile/Assets.xcassets/AppIcon.appiconset"
        images = json.loads((catalog / "Contents.json").read_text())["images"]
        entry = next(item for item in images if item.get("idiom") == "universal"
                     and item.get("platform") == "ios" and item.get("size") == "1024x1024")
        image = (catalog / entry["filename"]).read_bytes()
        self.assertEqual(struct.unpack(">II", image[16:24]), (1024, 1024))
        self.assertEqual(image[25], 2, "The App Store artwork must be RGB without an alpha channel")

    def test_mobile_target_bundles_and_selects_its_own_icon_catalog(self):
        objects, target = self.mobile_configuration()
        for ref in objects[target["buildConfigurationList"]]["buildConfigurations"]:
            self.assertEqual(objects[ref]["buildSettings"].get("ASSETCATALOG_COMPILER_APPICON_NAME"), "AppIcon")
        resources = [objects[ref] for ref in target["buildPhases"]
                     if objects[ref]["isa"] == "PBXResourcesBuildPhase"]
        paths = [objects[objects[file]["fileRef"]]["path"]
                 for phase in resources for file in phase["files"]]
        self.assertIn("Mobile/Assets.xcassets", paths)

    def test_mobile_archive_dry_run_is_ios_only_and_does_not_upload(self):
        result = subprocess.run(
            [str(APPLE.parent / "tools/archive-mobile-app-store"), "--dry-run"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("generic/platform=iOS", result.stdout)
        self.assertIn("MonoMarkMobile", result.stdout)
        self.assertIn("Monoleaf-iOS.xcarchive", result.stdout)
        self.assertIn("No upload or App Review submission", result.stdout)
        self.assertNotIn("generic/platform=macOS", result.stdout)

    def test_mobile_archive_rejects_invalid_arguments_before_signing(self):
        result = subprocess.run(
            [str(APPLE.parent / "tools/archive-mobile-app-store"), "--upload"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_all_native_products_target_version_one_with_numeric_builds(self):
        project = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(APPLE / "MonoMark.xcodeproj/project.pbxproj")],
            capture_output=True, text=True, check=True,
        )
        objects = json.loads(project.stdout)["objects"]
        for target_name in ["MonoMark", "MonoMarkMobile"]:
            target = next(x for x in objects.values() if x.get("isa") == "PBXNativeTarget"
                          and x.get("name") == target_name)
            for ref in objects[target["buildConfigurationList"]]["buildConfigurations"]:
                settings = objects[ref]["buildSettings"]
                self.assertEqual(settings["MARKETING_VERSION"], "1.0.0")
                self.assertRegex(settings["CURRENT_PROJECT_VERSION"], r"^[1-9][0-9]*$")
        mobile = plistlib.loads((APPLE / "Mobile/Info.plist").read_bytes())
        self.assertEqual(mobile["CFBundleShortVersionString"], "$(MARKETING_VERSION)")
        self.assertEqual(mobile["CFBundleVersion"], "$(CURRENT_PROJECT_VERSION)")

    def test_listing_and_renderer_match_version_one(self):
        draft = json.loads((APPLE.parent / "AppStore/metadata.json").read_text())
        renderer = json.loads((APPLE.parent / "renderer/package.json").read_text())
        self.assertEqual([draft["version"], renderer["version"]], ["1.0.0", "1.0.0"])

    def test_store_name_matches_both_native_products_and_renderer(self):
        draft = json.loads((APPLE.parent / "AppStore/metadata.json").read_text())
        project = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(APPLE / "MonoMark.xcodeproj/project.pbxproj")],
            capture_output=True, text=True, check=True,
        )
        objects = json.loads(project.stdout)["objects"]
        names = [draft["name"]]
        for platform in ["Mac", "Mobile"]:
            info = plistlib.loads((APPLE / platform / "Info.plist").read_bytes())
            names.extend([info["CFBundleDisplayName"], info["CFBundleName"]])
        for target_name in ["MonoMark", "MonoMarkMobile"]:
            target = next(x for x in objects.values() if x.get("isa") == "PBXNativeTarget"
                          and x.get("name") == target_name)
            for ref in objects[target["buildConfigurationList"]]["buildConfigurations"]:
                names.append(objects[ref]["buildSettings"]["PRODUCT_NAME"])

        self.assertEqual(set(names), {"Monoleaf"})

    def test_renderer_document_title_uses_store_name(self):
        shell = (APPLE.parent / "renderer/index.html").read_text()

        self.assertIn("<title>Monoleaf document</title>", shell)

    def test_mac_release_metadata_uses_build_settings(self):
        info = plistlib.loads((APPLE / "Mac/Info.plist").read_bytes())
        self.assertEqual(info["CFBundleShortVersionString"], "$(MARKETING_VERSION)")
        self.assertEqual(info["CFBundleVersion"], "$(CURRENT_PROJECT_VERSION)")
        self.assertEqual(info["LSApplicationCategoryType"], "public.app-category.productivity")
        self.assertIs(info["ITSAppUsesNonExemptEncryption"], False)

    def test_mobile_declares_no_nonexempt_encryption(self):
        info = plistlib.loads((APPLE / "Mobile/Info.plist").read_bytes())

        self.assertIs(info.get("ITSAppUsesNonExemptEncryption"), False)

    def test_app_store_export_stays_local(self):
        options = plistlib.loads((APPLE.parent / "AppStore/ExportOptions.plist").read_bytes())
        self.assertEqual(options["method"], "app-store-connect")
        self.assertEqual(options["destination"], "export")
        self.assertIs(options["manageAppVersionAndBuildNumber"], False)

    def test_store_draft_respects_field_limits_and_supported_platform(self):
        draft = json.loads((APPLE.parent / "AppStore/metadata.json").read_text())
        limits = {"name": 30, "subtitle": 30, "keywords": 100, "description": 4000, "promotionalText": 170}
        for field, limit in limits.items():
            self.assertTrue(0 < len(draft[field]) <= limit, field)
        self.assertEqual(draft["platforms"], ["macOS"])
        self.assertEqual(draft["bundleIdentifier"], "us.outcrop.MonoMark")
        self.assertEqual(draft["privacy"]["dataCollected"], False)

    def test_mac_sandbox_supports_webkit_without_remote_content(self):
        entitlements = plistlib.loads((APPLE / "Mac/MonoMark.entitlements").read_bytes())
        self.assertIs(entitlements.get("com.apple.security.network.client"), True)
        shell = (APPLE.parent / "renderer/index.html").read_text()
        self.assertIn("connect-src monomark:;", shell)
        self.assertIn("script-src monomark:;", shell)
        self.assertIn("img-src monomark: data:;", shell)

    def test_mac_icon_has_every_required_pixel_size(self):
        catalog = APPLE / "Mac/Assets.xcassets/AppIcon.appiconset"
        entries = json.loads((catalog / "Contents.json").read_text())["images"]
        slots = {(entry["size"], entry["scale"]) for entry in entries}
        expected = {(f"{size}x{size}", f"{scale}x")
                    for size in [16, 32, 128, 256, 512] for scale in [1, 2]}
        self.assertEqual(slots, expected)
        for entry in entries:
            data = (catalog / entry["filename"]).read_bytes()
            pixels = int(entry["size"].split("x")[0]) * int(entry["scale"][0])
            self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
            self.assertEqual(struct.unpack(">II", data[16:24]), (pixels, pixels))

    def test_mac_target_selects_the_icon_catalog(self):
        project = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(APPLE / "MonoMark.xcodeproj/project.pbxproj")],
            capture_output=True, text=True, check=True,
        )
        objects = json.loads(project.stdout)["objects"]
        target = next(x for x in objects.values() if x.get("isa") == "PBXNativeTarget"
                      and x.get("name") == "MonoMark")
        configs = objects[target["buildConfigurationList"]]["buildConfigurations"]
        for config in configs:
            self.assertEqual(objects[config]["buildSettings"].get("ASSETCATALOG_COMPILER_APPICON_NAME"), "AppIcon")
        resources = [objects[ref] for ref in target["buildPhases"]
                     if objects[ref]["isa"] == "PBXResourcesBuildPhase"]
        paths = [objects[objects[file]["fileRef"]]["path"]
                 for phase in resources for file in phase["files"]]
        self.assertIn("Mac/Assets.xcassets", paths)

    def test_privacy_manifest_matches_local_preferences_and_files(self):
        manifest = plistlib.loads((APPLE / "Shared/PrivacyInfo.xcprivacy").read_bytes())
        reasons = {
            entry["NSPrivacyAccessedAPIType"]: set(entry["NSPrivacyAccessedAPITypeReasons"])
            for entry in manifest["NSPrivacyAccessedAPITypes"]
        }
        self.assertEqual(reasons, {
            "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
            "NSPrivacyAccessedAPICategoryFileTimestamp": {"3B52.1", "C617.1"},
        })
        self.assertIs(manifest["NSPrivacyTracking"], False)
        self.assertEqual(manifest["NSPrivacyCollectedDataTypes"], [])
        self.assertEqual(manifest["NSPrivacyTrackingDomains"], [])

    def test_both_native_targets_bundle_the_privacy_manifest(self):
        result = subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(APPLE / "MonoMark.xcodeproj/project.pbxproj")],
            capture_output=True, text=True, check=True,
        )
        objects = json.loads(result.stdout)["objects"]
        for target in ("MonoMark", "MonoMarkMobile"):
            with self.subTest(target=target):
                config = next(x for x in objects.values() if x.get("isa") == "PBXNativeTarget"
                              and x.get("name") == target)
                resources = [objects[ref] for ref in config["buildPhases"]
                             if objects[ref]["isa"] == "PBXResourcesBuildPhase"]
                paths = [objects[objects[file]["fileRef"]]["path"]
                         for phase in resources for file in phase["files"]]
                self.assertIn("Shared/PrivacyInfo.xcprivacy", paths)


if __name__ == "__main__":
    unittest.main()
