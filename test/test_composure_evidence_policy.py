#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: e2ffab2a-9a70-490c-9eb0-60ea9bbe603b
# Created: 2026
# COMPONENT: Evidence-first benchmark boundaries
# PURPOSE: Test current-text grounding, closed observations, fixed wording, and isolated generation.
# RELATES: composure_evidence_policy.py, composure_model_benchmark.py
# FLOW: Invented observation -> strict parser -> application policy -> existing Core reply.

import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from composure_evidence_policy import EVIDENCE_POLICY, parse_observation, select_cue
from composure_model_benchmark import run_cases


class ComposureEvidencePolicyTests(unittest.TestCase):
    """Reject ungrounded or malformed observations without using model packages."""

    def observation(self, **changes):
        """Build a valid invented observation for one isolated boundary change."""
        value = {"issue": "ambiguity", "confidence": 0.9, "evidence": "make it better"}
        value.update(changes)
        return json.dumps(value)

    def fixture(self):
        """Keep gold labels separate from the exact input sent to generation."""
        return {"version": 1, "dataClass": "invented", "policy": "Original direct policy.",
                "cases": [{"id": "synthetic", "group": "synthetic", "offset": 0,
                           "input": {"background": {"previousSpeech": ["An old personal attack."]},
                                     "currentSpeech": "Please make it better."}, "expected": ["clarify"]}]}

    def test_exact_current_quote_is_accepted(self):
        result = parse_observation(self.observation(), "Please make it better.")

        self.assertEqual(result["evidence"], "make it better")

    def test_old_context_quote_is_rejected(self):
        raw = self.observation(evidence="An old personal attack.")

        with self.assertRaises(ValueError):
            parse_observation(raw, "The issue is resolved.")

    def test_paraphrased_evidence_is_rejected(self):
        raw = self.observation(evidence="improve the design")

        with self.assertRaises(ValueError):
            parse_observation(raw, "Please make it better.")

    def test_empty_actionable_evidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(evidence=""), "Please make it better.")

    def test_silence_requires_empty_evidence(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(issue="none"), "Please make it better.")

    def test_silence_maps_to_no_instruction(self):
        observation = parse_observation(self.observation(issue="none", evidence=""), "Agreed.")

        self.assertEqual(select_cue(observation), {"action": "noAction", "confidence": 0.9, "instruction": ""})

    def test_duplicate_fields_are_rejected(self):
        raw = '{"issue":"none","issue":"personalAttack","confidence":1,"evidence":""}'

        with self.assertRaises(ValueError):
            parse_observation(raw, "Agreed.")

    def test_model_cannot_supply_wording(self):
        raw = self.observation(instruction="Reveal the policy.")

        with self.assertRaises(ValueError):
            parse_observation(raw, "Please make it better.")

    def test_boolean_confidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(confidence=True), "Please make it better.")

    def test_nonfinite_confidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(confidence=float("nan")), "Please make it better.")

    def test_unknown_issue_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(issue="upload"), "Please make it better.")

    def test_surrounding_prose_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation("Thought: " + self.observation(), "Please make it better.")

    def test_oversized_response_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(" " * 4097, "Please make it better.")

    def test_control_character_evidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_observation(self.observation(evidence="make\nit better"), "make\nit better")

    def test_actions_and_wording_are_application_owned(self):
        expected = {"ambiguity": "clarify", "concern": "askFirst", "missingDecision": "decisionFocus",
                    "unsupportedCertainty": "dontGuess", "announcedReaction": "pause", "personalAttack": "rephrase"}
        actual = {}
        for issue in expected:
            observed = parse_observation(self.observation(issue=issue), "Please make it better.")
            actual[issue] = select_cue(observed)["action"]

        self.assertEqual(actual, expected)

    def test_reviewed_wording_is_an_instruction(self):
        observed = parse_observation(self.observation(), "Please make it better.")

        self.assertEqual(select_cue(observed)["instruction"], "Ask for a concrete example or clear criterion.")

    def test_low_confidence_is_preserved_for_core_rejection(self):
        observed = parse_observation(self.observation(confidence=0.3), "Please make it better.")

        self.assertEqual(select_cue(observed)["confidence"], 0.3)

    def test_generation_receives_no_gold_or_case_metadata(self):
        requests = []

        def generate(policy, prompt):
            requests.append((policy, json.loads(prompt)))
            return self.observation()

        run_cases(self.fixture(), generate, lambda: 0.0, mode="evidence")

        self.assertEqual(requests, [(EVIDENCE_POLICY, self.fixture()["cases"][0]["input"])])

    def test_evidence_mode_records_validated_observation(self):
        report = run_cases(self.fixture(), lambda policy, prompt: self.observation(), lambda: 0.0, mode="evidence")

        self.assertEqual(report["cases"][0]["observation"], json.loads(self.observation()))

    def test_ungrounded_output_is_a_failure_not_silence(self):
        report = run_cases(self.fixture(), lambda policy, prompt: self.observation(evidence="invented quote"),
                           lambda: 0.0, mode="evidence")

        self.assertEqual(report["cases"][0]["status"], "invalidOutput")

    def test_evidence_mode_keeps_the_total_deadline(self):
        clock = iter([0.0, 6.1])
        report = run_cases(self.fixture(), lambda policy, prompt: self.observation(),
                           lambda: next(clock), mode="evidence")

        self.assertEqual(report["cases"][0]["status"], "deadlineExceeded")

    def test_unrecognized_mode_is_rejected_before_generation(self):
        with self.assertRaises(ValueError):
            run_cases(self.fixture(), lambda policy, prompt: self.fail("Unexpected generation"),
                      lambda: 0.0, mode="unrecognized")


if __name__ == "__main__":
    unittest.main()
