# SPDX-FileCopyrightText: 2026 Outcrop Inc
# SPDX-License-Identifier: GPL-3.0-or-later
# Repository: rapid
# File GUID: 86ea7bad-e98c-4899-a9e1-dad3b7794172
# Created: 2026
# COMPONENT: Finite output token boundary
# PURPOSE: Permit only complete approved token sequences during optional local inference.
# RELATES: composure_detector_policy.py, composure_benchmark_runtime.py
# FLOW: Approved JSON catalog -> bounded token trie -> per-request logits mask -> strict parser.

"""Constraints enforce output shape, not correct classifications or calibrated confidence."""


class TokenChoices:
    """A bounded immutable catalog with a fresh processor state for each model request."""

    def __init__(self, sequences: list[list[int]], end_tokens: list[int]) -> None:
        if not 1 <= len(sequences) <= 192 or not 1 <= len(end_tokens) <= 16:
            raise ValueError("Invalid token catalog size.")
        if any(type(token) is not int or token < 0 for token in end_tokens):
            raise ValueError("Invalid end token.")
        self._ends = sorted(set(end_tokens))
        self._root = {}
        for sequence in sequences:
            if not 1 <= len(sequence) <= 64 or any(
                type(token) is not int or token < 0 or token in self._ends for token in sequence
            ):
                raise ValueError("Invalid token choice.")
            node = self._root
            for token in sequence:
                node = node.setdefault(token, {})
            node[None] = {}

    def allowed(self, prefix: list[int]) -> list[int]:
        """Return valid continuations. Completed choices absorb end tokens for MLX's one-token lookahead."""
        node = self._root
        for index, token in enumerate(prefix):
            if type(token) is not int:
                raise ValueError("Invalid token prefix.")
            if token in self._ends and None in node and all(
                type(item) is int and item in self._ends for item in prefix[index:]
            ):
                return self._ends
            if token not in node:
                raise ValueError("Generation left the approved token catalog.")
            node = node[token]
        tokens = [token for token in node if token is not None]
        if None in node:
            tokens.extend(self._ends)
        return sorted(tokens)

    def processor(self, mx):
        """Create an MLX callback without importing the optional runtime in ordinary unit tests."""
        initial_length = None

        def constrain(tokens, logits):
            nonlocal initial_length
            if initial_length is None:
                initial_length = tokens.size
            allowed = self.allowed(tokens[initial_length:].tolist())
            masked = mx.full(logits.shape, -float('inf'), dtype=logits.dtype)
            indices = mx.array(allowed)
            masked[..., indices] = logits[..., indices]
            return masked

        return constrain
