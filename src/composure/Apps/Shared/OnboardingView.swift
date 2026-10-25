// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b810b8ce-6667-4f26-b7b9-ff868d8f29da
// Created: 2026
// COMPONENT: Privacy and profile onboarding
// PURPOSE: Explain current privacy behavior and save the user's initial coaching choices explicitly.
// RELATES: OnboardingStep, ProfileFields, PreferencesCoordinator
// FLOW: Introduction -> privacy -> listening disclosure -> profile -> successful preference save.

import ComposureCore
import SwiftUI

/// Back navigation retains the shared draft. Finish does not dismiss a failed save.
struct OnboardingView: View
{
    @Bindable var coordinator: PreferencesCoordinator
    @State private var step: OnboardingStep = .introduction
    @AccessibilityFocusState private var isHeadingFocused: Bool

    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)
            Form
            {
                introductionSection
                if step == .profile
                {
                    ProfileFields(profile: $coordinator.draft.profile)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 720)
            footer
        }
        .navigationTitle("Composure")
        .onChange(of: step)
        {
            isHeadingFocused = true
        }
    }

    private var introductionSection: some View
    {
        Section
        {
            VStack(alignment: .leading, spacing: 16)
            {
                Image(systemName: step.symbol).font(.largeTitle).accessibilityHidden(true)
                Text(step.title)
                    .font(.title).bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isHeadingFocused)
                Text(step.detail)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical)
        }
    }

    private var footer: some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            PreferenceSaveStatusView(coordinator: coordinator)
            HStack
            {
                if let previous = step.previous
                {
                    Button("Back")
                    {
                        step = previous
                    }.accessibilityIdentifier("onboarding.back")
                }
                Spacer()
                if let next = step.next
                {
                    Button("Continue")
                    {
                        step = next
                    }
                    .accessibilityIdentifier("onboarding.next")
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                else
                {
                    Button("Finish setup")
                    {
                        coordinator.completeOnboarding()
                    }
                    .accessibilityIdentifier("onboarding.finish")
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding()
        .frame(maxWidth: 720)
    }
}
