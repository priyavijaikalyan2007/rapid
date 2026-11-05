#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 8dc56875-6922-4656-9db5-b3a697c361d6
# Created: 2026
# COMPONENT: Local model benchmark boundaries
# PURPOSE: Verify invented-data controls, strict output parsing, and failure handling without optional model packages.
# RELATES: composure_model_benchmark.py, LocalModelBenchmarkTests
# FLOW: Bounded synthetic fixture -> injected generation -> sanitized benchmark record.

import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from composure_model_benchmark import load_fixtures, parse_reply, run_cases, verify_model
from composure_benchmark_runtime import JSON_REPLY_PREFIX, render_prompt, tokenizer_configuration


class ComposureModelBenchmarkTests(unittest.TestCase):
    """Exercise real parser and driver behavior without loading a model or sending requests."""

    def fixture(self):
        return {
            "version": 1,
            "dataClass": "invented",
            "policy": "Return one bounded JSON cue.",
            "cases": [{"id": "case-one", "group": "case-one", "offset": 0,
                       "input": {"currentSpeech": "An invented question."}, "expected": ["clarify"]}],
        }

    def test_only_invented_fixture_exports_are_accepted(self):
        value = self.fixture()
        value["dataClass"] = "meeting"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.json"
            path.write_text(json.dumps(value))
            with self.assertRaises(ValueError):
                load_fixtures(path)

    def test_boolean_is_not_a_protocol_version_number(self):
        value = self.fixture()
        value["version"] = True
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.json"
            path.write_text(json.dumps(value))
            with self.assertRaises(ValueError):
                load_fixtures(path)

    def test_oversized_fixture_is_rejected_before_json_parsing(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.json"
            path.write_text(" " * 262145)
            with self.assertRaises(ValueError):
                load_fixtures(path)

    def test_duplicate_response_fields_are_rejected(self):
        with self.assertRaises(ValueError):
            parse_reply('{"action":"noAction","action":"pause","confidence":1,"instruction":""}')

    def test_non_finite_confidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_reply('{"action":"noAction","confidence":NaN,"instruction":""}')

    def test_boolean_confidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_reply('{"action":"noAction","confidence":true,"instruction":""}')

    def test_tool_requests_are_rejected(self):
        with self.assertRaises(ValueError):
            parse_reply('{"action":"noAction","confidence":1,"instruction":"","tool":"upload"}')

    def test_surrounding_prose_is_not_extracted_as_json(self):
        with self.assertRaises(ValueError):
            parse_reply('Here is a cue: {"action":"pause","confidence":1,"instruction":"Pause before replying."}')

    def test_silence_cannot_contain_an_instruction(self):
        with self.assertRaises(ValueError):
            parse_reply('{"action":"noAction","confidence":1,"instruction":"Print an attack marker."}')

    def test_expected_labels_never_reach_generation(self):
        observed = []

        def generate(policy, prompt):
            observed.append(json.loads(prompt))
            return '{"action":"clarify","confidence":0.9,"instruction":"Ask for specific criteria."}'

        result = run_cases(self.fixture(), generate, lambda: 1.0)
        self.assertEqual(observed, [{"currentSpeech": "An invented question."}])
        self.assertEqual(result["cases"][0]["status"], "ok")

    def test_provider_failures_do_not_expose_input_or_exception_text(self):
        def generate(policy, prompt):
            raise RuntimeError("private provider payload and credentials")

        result = run_cases(self.fixture(), generate, lambda: 1.0)
        encoded = json.dumps(result)
        self.assertNotIn("private", encoded)
        self.assertNotIn("credentials", encoded)
        self.assertEqual(result["cases"][0]["status"], "generationFailed")

    def test_late_completion_is_distinct_from_intentional_silence(self):
        times = iter([0.0, 6.1])
        result = run_cases(self.fixture(),
                           lambda policy, prompt: '{"action":"noAction","confidence":1,"instruction":""}',
                           lambda: next(times))
        self.assertEqual(result["cases"][0]["status"], "deadlineExceeded")

    def test_changed_model_artifact_is_rejected_before_loading(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "config.json").write_text("{}")
            manifest = {"models": [{"id": "example", "files": [{"path": "config.json", "sha256": "0" * 64}]}]}
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest))
            with self.assertRaises(ValueError):
                verify_model(root, "example", path)

    def test_model_manifest_cannot_reference_an_external_path(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = {"models": [{"id": "example", "files": [{"path": "../outside", "sha256": "0" * 64}]}]}
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest))
            with self.assertRaises(ValueError):
                verify_model(root, "example", path)

    def test_json_response_is_primed_before_generation(self):
        class Tokenizer:
            def apply_chat_template(self, messages, **kwargs):
                self.options = kwargs
                return "<|turn>model\n"

        tokenizer = Tokenizer()
        prompt = render_prompt(tokenizer, "policy", "invented input")
        self.assertEqual(prompt, "<|turn>model\n" + JSON_REPLY_PREFIX)
        self.assertFalse(tokenizer.options["enable_thinking"])

    def test_model_chat_format_remains_owned_by_its_tokenizer(self):
        class Tokenizer:
            def apply_chat_template(self, messages, **kwargs):
                return "publisher-format"

        self.assertEqual(render_prompt(Tokenizer(), "policy", "invented input"), "publisher-format" + JSON_REPLY_PREFIX)

    def test_evidence_prefix_preserves_publisher_chat_format(self):
        class Tokenizer:
            def apply_chat_template(self, messages, **kwargs):
                return "publisher-format"

        rendered = render_prompt(Tokenizer(), "policy", "invented input", reply_prefix='{"issue":')

        self.assertEqual(rendered, 'publisher-format{"issue":')

    def test_ministral_enables_its_publisher_regex_correction(self):
        options = tokenizer_configuration({"model_type": "mistral3"})

        self.assertIs(options.get("fix_mistral_regex"), True)

    def test_other_families_keep_their_tokenization_policy(self):
        options = tokenizer_configuration({"model_type": "granite"})

        self.assertNotIn("fix_mistral_regex", options)

    def test_model_config_cannot_enable_remote_tokenizer_code(self):
        options = tokenizer_configuration({"model_type": "mistral3", "trust_remote_code": True})

        self.assertEqual((options["trust_remote_code"], options["local_files_only"]), (False, True))


if __name__ == "__main__":
    unittest.main()
