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
import unittest


APPLE = Path(__file__).resolve().parents[1] / "src/app/monomark/apple"


class MonoMarkReleaseTests(unittest.TestCase):
    """Verify authored release resources, without claiming signed-build acceptance."""

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
