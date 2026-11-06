# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 4a0c4677-069d-4fe2-931e-b3ab7ad0c8cd
# Created: 2026
# COMPONENT: Constrained detector contracts
# PURPOSE: Test finite outputs, current evidence references, token boundaries, and isolated inference inputs.
# RELATES: composure_detector_policy.py, composure_token_choices.py
# FLOW: Invented input -> span catalog -> constrained response -> independently validated observation.

import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from composure_detector_policy import (
    DETECTOR_POLICY, allowed_detections, constrained_generation, current_spans, detection_input, parse_detection,
)
from composure_model_benchmark import run_cases
from composure_token_choices import TokenChoices


class ComposureDetectorTests(unittest.TestCase):
    """Keep hard output constraints independent from unproven semantic accuracy."""

    def test_current_spans_preserve_exact_text(self):
        self.assertEqual(current_spans('  First concern. Next concern?  '), ['First concern.', 'Next concern?'])

    def test_catalog_never_contains_old_speech(self):
        value = detection_input({'background': {'previousSpeech': ['OLDER_MARKER']}, 'currentSpeech': 'CURRENT_MARKER'})

        self.assertEqual(value['currentSpans'], ['CURRENT_MARKER'])

    def test_missing_current_speech_is_rejected(self):
        with self.assertRaises(ValueError):
            detection_input({'background': {}})

    def test_oversized_span_is_rejected_without_truncation(self):
        with self.assertRaises(ValueError):
            current_spans('a' * 513)

    def test_excessive_span_count_is_rejected(self):
        with self.assertRaises(ValueError):
            current_spans('A. ' * 9)

    def test_detection_resolves_a_current_span(self):
        observation = parse_detection('{"issue":"ambiguity","span":1,"confidence":0.9}', ['First.', 'Second.'])

        self.assertEqual(observation, {'issue': 'ambiguity', 'evidence': 'Second.', 'confidence': 0.9, 'span': 1})

    def test_none_requires_null_span(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"none","span":0,"confidence":0.9}', ['First.'])

    def test_action_requires_existing_span(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"ambiguity","span":2,"confidence":0.9}', ['First.'])

    def test_boolean_is_not_a_span_index(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"ambiguity","span":true,"confidence":0.9}', ['First.'])

    def test_duplicate_detection_fields_are_rejected(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"none","issue":"none","span":null,"confidence":0.9}', ['First.'])

    def test_non_catalog_confidence_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"ambiguity","span":0,"confidence":0.87}', ['First.'])

    def test_model_cannot_supply_its_own_quote(self):
        with self.assertRaises(ValueError):
            parse_detection('{"issue":"ambiguity","span":0,"confidence":0.9,"evidence":"invented"}', ['First.'])

    def test_catalog_contains_only_supported_complete_outputs(self):
        choices = allowed_detections(['First.'])
        observations = [parse_detection(text, ['First.']) for text in choices]

        self.assertEqual({item['issue'] for item in observations}, {'none', 'ambiguity', 'missingDecision',
                                                                 'unsupportedCertainty'})

    def test_low_confidence_is_not_promoted(self):
        observed = parse_detection('{"issue":"ambiguity","span":0,"confidence":0.5}', ['First.'])

        self.assertEqual(observed['confidence'], 0.5)

    def test_adapter_sends_catalog_separately_from_prompt(self):
        requests = []

        def generate(policy, prompt, *, allowed_replies):
            requests.append((policy, json.loads(prompt), allowed_replies))
            return '{"issue":"none","span":null,"confidence":0.9}'

        prompt = json.dumps(detection_input({'currentSpeech': 'Current.'}))
        constrained_generation(generate)(DETECTOR_POLICY, prompt)

        self.assertEqual(requests, [(DETECTOR_POLICY, json.loads(prompt), allowed_detections(['Current.']))])

    def test_driver_keeps_expected_actions_out_of_generation(self):
        requests = []
        fixtures = {'version': 1, 'dataClass': 'invented', 'policy': 'Old policy', 'cases': [
            {'id': 'PRIVATE_CASE_ID', 'group': 'private', 'offset': 0,
             'input': {'currentSpeech': 'Current.'}, 'expected': ['clarify']}]}

        def generate(policy, prompt):
            requests.append((policy, json.loads(prompt)))
            return '{"issue":"ambiguity","span":0,"confidence":0.9}'

        run_cases(fixtures, generate, lambda: 0, mode='constrained')

        self.assertEqual(requests, [(DETECTOR_POLICY, {'currentSpeech': 'Current.', 'currentSpans': ['Current.']})])

    def test_driver_records_the_complete_detection_for_audit(self):
        raw = '{"issue":"none","span":null,"confidence":0.9}'
        fixtures = {'version': 1, 'dataClass': 'invented', 'policy': 'Old policy', 'cases': [
            {'id': 'case', 'group': 'case', 'offset': 0, 'input': {'currentSpeech': 'Current.'}, 'expected': []}]}
        report = run_cases(fixtures, lambda policy, prompt: raw, lambda: 0, mode='constrained')

        self.assertEqual(report['cases'][0]['rawDetection'], raw)

    def test_trie_allows_only_valid_next_tokens(self):
        choices = TokenChoices([[1, 2], [1, 3]], [9])

        self.assertEqual(choices.allowed([1]), [2, 3])

    def test_end_token_is_available_only_after_completion(self):
        choices = TokenChoices([[1, 2]], [9])

        self.assertEqual((choices.allowed([]), choices.allowed([1, 2])), ([1], [9]))

    def test_invalid_prefix_stops_instead_of_repairing(self):
        choices = TokenChoices([[1, 2]], [9])

        with self.assertRaises(ValueError):
            choices.allowed([1, 3])

    def test_finished_choice_absorbs_end_token_lookahead(self):
        choices = TokenChoices([[1, 2]], [9])

        self.assertEqual(choices.allowed([1, 2, 9]), [9])

    def test_boolean_cannot_masquerade_as_an_end_token(self):
        choices = TokenChoices([[2]], [1])

        with self.assertRaises(ValueError):
            choices.allowed([2, True])

    def test_end_token_lookahead_validates_every_token_type(self):
        choices = TokenChoices([[2]], [1])

        with self.assertRaises(ValueError):
            choices.allowed([2, 1, True])

    def test_excessive_catalog_is_rejected(self):
        with self.assertRaises(ValueError):
            TokenChoices([[index] for index in range(193)], [999])

    def test_end_token_cannot_appear_inside_a_choice(self):
        with self.assertRaises(ValueError):
            TokenChoices([[1, 9, 2]], [9])


if __name__ == '__main__':
    unittest.main()
