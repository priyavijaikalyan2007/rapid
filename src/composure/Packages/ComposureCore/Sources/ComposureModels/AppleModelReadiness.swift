// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3f0eacbd-7da7-4b80-81e0-d52d2f1c36c6
// Created: 2026
// COMPONENT: On-device preparation adapter
// PURPOSE: Translate native model availability into stable application states.
// RELATES: CoachingModel, PreparationService
// FLOW: Bounded user prompt -> fresh on-device session -> independently validated preparation.

import ComposureCore
import FoundationModels

/// Unknown future reasons remain unavailable. Availability never enables a cloud provider.
enum AppleModelReadiness
{
    static func map(_ availability: SystemLanguageModel.Availability) -> ModelReadiness
    {
        switch availability
        {
        case .available: return .available
        case .unavailable(.appleIntelligenceNotEnabled): return .appleIntelligenceNotEnabled
        case .unavailable(.deviceNotEligible): return .deviceNotEligible
        case .unavailable(.modelNotReady): return .modelNotReady
        @unknown default: return .otherUnavailable
        }
    }
}
