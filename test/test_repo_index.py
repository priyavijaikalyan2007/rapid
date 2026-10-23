#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 33f92143-e280-424b-ad94-347e508c8ad9
# Created: 2026
# AGENT: Verifies that repository search covers the actual project languages and excludes local data.

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from repo_index_lib import detect_language, normalise_excluded_dirs, normalise_extensions, should_index_path


class RepositoryIndexTests(unittest.TestCase):
    """Exercise project-specific search boundaries in the reused index helpers."""

    def test_swift_source_is_searchable(self):
        self.assertIn(".swift", normalise_extensions(None))

    def test_javascript_modules_are_searchable(self):
        self.assertIn(".mjs", normalise_extensions(None))

    def test_history_records_are_searchable(self):
        self.assertIn(".jsonl", normalise_extensions(None))

    def test_swift_is_identified_as_swift(self):
        self.assertEqual(detect_language(Path("PhotoDocument.swift")), "swift")

    def test_local_index_cannot_index_itself(self):
        self.assertFalse(should_index_path(Path("local/notes.md"), [".md"], normalise_excluded_dirs(None)))

    def test_credential_configuration_is_excluded(self):
        self.assertFalse(should_index_path(Path(".aws/config.json"), [".json"], normalise_excluded_dirs(None)))


if __name__ == "__main__":
    unittest.main()
