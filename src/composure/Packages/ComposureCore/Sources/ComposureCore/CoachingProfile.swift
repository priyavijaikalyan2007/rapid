// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a45c2576-6b59-4a8e-86d8-f50b01d48edc
// Created: 2026
// COMPONENT: Coaching profile
// PURPOSE: Hold bounded user preferences without meeting content or inferred personal traits.
// RELATES: CoachingFocus, AppPreferences
// FLOW: User-selected choices -> typed profile -> persistence and future coaching input.

/// Stores stated preferences only. No score or behavioral diagnosis is derived here.
public struct CoachingProfile: Codable, Sendable, Equatable
{
    public var respondTooQuickly: FocusImportance = .notRelevant
    public var becomeDefensive: FocusImportance = .notRelevant
    public var overExplain: FocusImportance = .notRelevant
    public var interruptOthers: FocusImportance = .notRelevant
    public var stateOpinionsStrongly: FocusImportance = .notRelevant
    public var allowAgendaDrift: FocusImportance = .notRelevant
    public var speculateTooMuch: FocusImportance = .notRelevant
    public var needMoreCuriosity: FocusImportance = .notRelevant
    public var executiveRestraint = false
    public var cueFrequency: CueFrequency = .normal
    public var cueVerbosity: CueVerbosity = .veryShort

    /// Starts without assuming that any behavioral focus applies to the user.
    public init()
    {
    }

    /// Reads or edits one bounded focus without a free-form key or numerical weight.
    public subscript(focus: CoachingFocus) -> FocusImportance
    {
        get
        {
            switch focus
            {
            case .respondTooQuickly: return respondTooQuickly
            case .becomeDefensive: return becomeDefensive
            case .overExplain: return overExplain
            case .interruptOthers: return interruptOthers
            case .stateOpinionsStrongly: return stateOpinionsStrongly
            case .allowAgendaDrift: return allowAgendaDrift
            case .speculateTooMuch: return speculateTooMuch
            case .needMoreCuriosity: return needMoreCuriosity
            }
        }
        set
        {
            switch focus
            {
            case .respondTooQuickly: respondTooQuickly = newValue
            case .becomeDefensive: becomeDefensive = newValue
            case .overExplain: overExplain = newValue
            case .interruptOthers: interruptOthers = newValue
            case .stateOpinionsStrongly: stateOpinionsStrongly = newValue
            case .allowAgendaDrift: allowAgendaDrift = newValue
            case .speculateTooMuch: speculateTooMuch = newValue
            case .needMoreCuriosity: needMoreCuriosity = newValue
            }
        }
    }
}
