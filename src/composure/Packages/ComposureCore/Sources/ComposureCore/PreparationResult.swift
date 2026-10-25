// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f84f5e9c-34f2-4276-8239-84b83dc0aa27
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Pair validated coaching text with its generation source.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// A memory-only result with explicit provenance. No persistence conformance is provided.
public struct PreparationResult: Sendable, Equatable
{
    public let preparation: MeetingPreparation
    public let source: PreparationSource
    public init(preparation: MeetingPreparation, source: PreparationSource)
    {
        self.preparation = preparation
        self.source = source
    }
}
