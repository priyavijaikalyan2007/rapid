// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c3da374b-a58c-4d94-bb20-e588543d04ac
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Identify whether preparation used the on-device model or fixed profile guidance.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// Prevents template guidance from appearing to be model-generated preparation.
public enum PreparationSource: Sendable, Equatable
{
    case onDevice
    case profileGuidance(PreparationFallbackReason)
}
