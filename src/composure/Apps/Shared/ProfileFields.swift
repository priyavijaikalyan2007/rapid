// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 3c68121a-30e4-4a19-874d-7533c9b16c4c
// Created: 2026
// COMPONENT: Native coaching profile fields
// PURPOSE: Reuse the same bounded controls in onboarding and settings.
// RELATES: CoachingProfile, OnboardingView, CoachingSettingsView
// FLOW: Native picker or toggle -> typed profile draft -> explicit save.

import ComposureCore
import SwiftUI

/// Only fixed choices can enter this form. There are no meeting-text input fields.
struct ProfileFields: View
{
    @Binding var profile: CoachingProfile

    var body: some View
    {
        Section
        {
            ForEach(CoachingFocus.allCases, id: \.self)
            { focus in
                importancePicker(for: focus)
            }
        }
        header: {
            Text("Coaching focus")
        }
        footer: {
            Text("Choose Not relevant, Sometimes, Important, or Major focus for each habit.")
        }

        Section
        {
            Toggle("Be especially restrained in executive conversations", isOn: $profile.executiveRestraint)
                .accessibilityIdentifier("profile.executiveRestraint")
                .help("Prefer concise answers and curiosity in executive conversations.")
        }
        header: {
            Text("Executive conversations")
        }

        Section
        {
            Picker("Cue frequency", selection: $profile.cueFrequency)
            {
                ForEach(CueFrequency.allCases, id: \.self)
                {
                    Text($0.rawValue).tag($0)
                }
            }
            .help("Choose how often you prefer coaching cues. Every setting favors silence when a cue is not useful.")
            Picker("Cue detail", selection: $profile.cueVerbosity)
            {
                ForEach(CueVerbosity.allCases, id: \.self)
                {
                    Text($0.rawValue).tag($0)
                }
            }
            .help("Both options keep live coaching instructions brief.")
        }
        header: {
            Text("Cue preferences")
        }
        footer: {
            Text("Live coaching is not available in this version.")
        }
    }

    /// The binding updates only the selected enum dimension and retains the rest of the draft.
    private func importancePicker(for focus: CoachingFocus) -> some View
    {
        Picker(focus.rawValue, selection: Binding(
            get: {
                profile[focus]
            },
            set: {
                profile[focus] = $0
            }
        ))
        {
            ForEach(FocusImportance.allCases, id: \.self)
            {
                Text($0.label).tag($0)
            }
        }
        .help("Choose how important this focus is to you. This is a preference, not a score.")
        .accessibilityHint("Choose the importance of this coaching focus.")
    }
}
