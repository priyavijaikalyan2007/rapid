// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a110b4c5-3a17-4ea1-9b40-ed625189e6ec
// Created: 2026
// COMPONENT: First-run introduction content
// PURPOSE: Keep the four privacy and profile steps consistent on all supported devices.
// RELATES: OnboardingView
// FLOW: Current step -> native heading and disclosure -> next or previous step.

/// Describes current capabilities without requesting audio or model access.
enum OnboardingStep: Int, CaseIterable
{
    case introduction
    case privacy
    case listening
    case profile

    var next: Self?
    {
        Self(rawValue: rawValue + 1)
    }

    var previous: Self?
    {
        Self(rawValue: rawValue - 1)
    }

    var title: String
    {
        switch self
        {
        case .introduction: return "Welcome to Composure"
        case .privacy: return "Private by design"
        case .listening: return "You control listening"
        case .profile: return "How should I coach you?"
        }
    }

    var detail: String
    {
        switch self
        {
        case .introduction:
            return "Choose the communication habits that matter to you. You can change these choices in Settings."
        case .privacy:
            return "Composure does not intentionally save or upload conversation audio or transcripts. " +
                "Only your coaching choices and app preferences are saved."
        case .listening:
            return "Future live coaching will require Start and show a listening indicator and Stop control. " +
                "Follow your organization's rules and participant-notice requirements."
        case .profile:
            return "Choose how much each habit matters to you. These choices do not produce a score."
        }
    }

    var symbol: String
    {
        switch self
        {
        case .introduction: return "text.bubble"
        case .privacy: return "lock.shield"
        case .listening: return "hand.raised"
        case .profile: return "slider.horizontal.3"
        }
    }
}
