// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 222183e2-fecd-47d3-97bc-52ec510a34e7
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Expose local model availability through a closed, testable state vocabulary.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

/// Describes the local model only. This never checks or starts audio capture.
public enum ModelReadiness: String, Sendable, Equatable, CaseIterable
{
    case available
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case otherUnavailable

    public var explanation: String
    {
        switch self
        {
        case .available: return "The on-device model is ready."
        case .appleIntelligenceNotEnabled: return "Apple Intelligence is turned off. Profile guidance remains available."
        case .deviceNotEligible: return "This device cannot use the on-device model. Profile guidance remains available."
        case .modelNotReady: return "The system model is not ready yet. Profile guidance remains available."
        case .otherUnavailable: return "The on-device model is unavailable. Profile guidance remains available."
        }
    }
}
