// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: dfd883b2-9633-4e7e-858e-da790b855e2a
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Render all five validated coaching sections with explicit model or template provenance.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import ComposureCore
import SwiftUI

/// Dynamic model strings are rendered verbatim. They cannot become links, Markdown, or actions.
struct PreparationResultView: View
{
    let result: PreparationResult

    var body: some View
    {
        Section("Preparation source")
        {
            switch result.source
            {
            case .onDevice:
                Text("On-device preparation")
                Text("Review these suggestions and choose what fits your conversation.").foregroundStyle(.secondary)
            case .profileGuidance(let reason):
                Text("Profile guidance")
                Text(reason.explanation).foregroundStyle(.secondary)
                Text("These fixed suggestions use your profile. They do not interpret the conversation topic.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        Section("Objective")
        {
            Text(verbatim: result.preparation.objective)
        }
        items("Watch For", values: result.preparation.watchFor)
        items("Questions to Ask", values: result.preparation.questionsToAsk)
        Section("If Challenged")
        {
            Text(verbatim: result.preparation.ifChallenged)
        }
        items("Keep in Mind", values: result.preparation.keepInMind)
    }

    private func items(_ title: String, values: [String]) -> some View
    {
        Section(title)
        {
            ForEach(values.indices, id: \.self)
            { index in
                Text(verbatim: values[index])
            }
        }
    }
}
