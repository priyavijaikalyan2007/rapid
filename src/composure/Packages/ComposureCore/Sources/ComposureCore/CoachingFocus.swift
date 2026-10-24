// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c6078aa9-58b1-4dc5-9416-b65dd6c9abcb
// Created: 2026
// COMPONENT: Coaching focus vocabulary
// PURPOSE: Name user-selected behaviors without psychological scores or participant analysis.
// RELATES: CoachingProfile
// FLOW: Profile choice -> bounded importance -> future coaching policy.

/// The fixed V1 behavioral dimensions. These labels are not free-form user input.
public enum CoachingFocus: String, CaseIterable, Sendable
{
    case respondTooQuickly = "I answer too quickly"
    case becomeDefensive = "I become defensive when challenged"
    case overExplain = "I over-explain"
    case interruptOthers = "I interrupt"
    case stateOpinionsStrongly = "I state opinions too strongly"
    case allowAgendaDrift = "I let discussions drift"
    case speculateTooMuch = "I speculate instead of acknowledging uncertainty"
    case needMoreCuriosity = "I should ask more questions"
}
