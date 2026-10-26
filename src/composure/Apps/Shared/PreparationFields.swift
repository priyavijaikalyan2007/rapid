// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 33d87084-96ac-4efe-becb-3f173055b040
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Edit bounded sensitive text using native controls without autocorrection or automatic persistence.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import ComposureCore
import SwiftUI

/// Bindings reject oversized edits instead of silently truncating a conversation field.
struct PreparationFields: View
{
    @Bindable var coordinator: PreparationCoordinator
    var focus: FocusState<String?>.Binding
    @State private var limitMessage: String?

    var body: some View
    {
        Section("Conversation")
        {
            editor(
                "Conversation topic",
                text: $coordinator.topic,
                id: "prepare.topic",
                limit: PreparationLimits.topicBytes
            )
            editor(
                "Desired outcome (optional)",
                text: $coordinator.outcome,
                id: "prepare.outcome",
                limit: PreparationLimits.optionalFieldBytes
            )
            editor(
                "What could make this difficult? (optional)",
                text: $coordinator.concern,
                id: "prepare.concern",
                limit: PreparationLimits.optionalFieldBytes
            )
            Toggle("High-stakes or executive conversation", isOn: $coordinator.highStakes)
        }
        Section
        {
            Text("Topic: up to 2,048 UTF-8 bytes. Optional fields: up to 1,024 bytes each.")
                .font(.footnote).foregroundStyle(.secondary)
            if let limitMessage
            {
                Text(limitMessage).font(.callout)
            }
        }
    }

    private func editor(_ title: String, text: Binding<String>, id: String, limit: Int) -> some View
    {
        VStack(alignment: .leading, spacing: 6)
        {
            Text(title).font(.subheadline)
            TextEditor(text: bounded(text, limit: limit))
                .frame(minHeight: 64, maxHeight: 100)
                .focused(focus, equals: id)
                .accessibilityLabel(title)
                .accessibilityIdentifier(id)
                .autocorrectionDisabled()
                .writingToolsBehavior(.disabled)
                .privacySensitive()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .textContentType(nil)
                #endif
        }
    }

    private func bounded(_ text: Binding<String>, limit: Int) -> Binding<String>
    {
        Binding(get: {
            text.wrappedValue
        }, set: { updated in
            guard updated.utf8.count <= limit
            else
            {
                limitMessage = "This edit exceeds the text limit. Your previous text remains. Shorten the text and try again."
                return
            }
            limitMessage = nil
            text.wrappedValue = updated
        })
    }
}
