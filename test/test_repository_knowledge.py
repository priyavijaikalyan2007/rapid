#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc, WA, USA.
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: c897fc11-7199-4953-90fb-677153ee77d9
# Created: 2026
# AGENT: Checks evidence links and stable identifiers in the bootstrapped knowledge files.

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class RepositoryKnowledgeTests(unittest.TestCase):
    """Keep navigation records useful without claiming product behavior was tested."""

    def read_records(self, filename):
        """Parse the documented JSON-compatible subset of YAML without executing tags."""
        return json.loads((ROOT / "agentknowledge" / filename).read_text())

    def test_concepts_have_unique_pascal_case_names(self):
        records = self.read_records("concepts.yaml")
        names = [record["name"] for record in records]
        self.assertEqual(len(names), len(set(names)))
        for name in names:
            self.assertRegex(name, r"^[A-Z][A-Za-z0-9]+$")

    def test_concept_anchors_exist_inside_repository(self):
        for record in self.read_records("concepts.yaml"):
            anchor = (ROOT / record["anchor_file"]).resolve()
            self.assertTrue(anchor.is_relative_to(ROOT) and anchor.is_file(), str(anchor))

    def test_related_concepts_resolve(self):
        records = self.read_records("concepts.yaml")
        names = {record["name"] for record in records}
        for record in records:
            self.assertTrue(set(record["related"]).issubset(names), record["name"])

    def test_entity_files_exist_and_tables_do_not_imply_a_database(self):
        for record in self.read_records("entities.yaml"):
            self.assertTrue((ROOT / record["file"]).is_file(), record["file"])
            self.assertIsNone(record["table"])

    def test_decisions_include_existing_evidence_files(self):
        for record in self.read_records("decisions.yaml"):
            self.assertRegex(record["id"], r"^ADR-\d{3}$")
            for filename in record["files"]:
                self.assertTrue((ROOT / filename).is_file(), filename)

    def test_history_is_json_lines_with_a_final_newline(self):
        text = (ROOT / "agentknowledge/history.jsonl").read_text()
        self.assertTrue(text.endswith("\n"))
        for line in text.splitlines():
            self.assertTrue({"date", "task", "files", "summary"}.issubset(json.loads(line)))


if __name__ == "__main__":
    unittest.main()
