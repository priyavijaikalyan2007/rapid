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
