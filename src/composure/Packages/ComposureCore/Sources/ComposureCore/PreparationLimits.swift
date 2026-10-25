// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4d5c275b-e135-43b1-999a-2dbb9d0e10db
// Created: 2026
// COMPONENT: Transient conversation preparation
// PURPOSE: Centralize byte, token, output, and time limits before external framework work.
// RELATES: PreparationService, CoachingProfile
// FLOW: Bounded input -> private preparation -> validated plain-text guidance.

import Foundation

/// Central limits apply before model work and independently after generation.
public enum PreparationLimits
{
    public static let topicBytes = 2048
    public static let optionalFieldBytes = 1024
    public static let totalInputBytes = 4096
    public static let outputItemBytes = 280
    public static let totalOutputBytes = 4096
    public static let outputTokens = 768
    public static let contextTokens = 4096
    public static let inputTokens = 2816
    public static let contextReserveTokens = 512
    public static let timeout: Duration = .seconds(20)

    /// Permit normal line breaks and tabs, but reject invisible control instructions.
    static func containsDisallowedControls(_ text: String) -> Bool
    {
        let allowed = CharacterSet(charactersIn: "\n\r\t")
        return text.unicodeScalars.contains
        {
            CharacterSet.controlCharacters.contains($0) && !allowed.contains($0)
        }
    }
}
