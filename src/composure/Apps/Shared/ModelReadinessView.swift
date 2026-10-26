// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 04ea95e0-1178-47e9-a587-e9e4a813083b
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Display truthful on-device availability and an explicit refresh action.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import ComposureCore
import SwiftUI

/// The service supplies stable states. This view does not inspect hardware or invoke generation.
struct ModelReadinessView: View
{
    let service: PreparationService
    @State private var status: ModelReadiness?
    @State private var isChecking = false

    var body: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            Text(status?.explanation ?? "Checking the on-device model…")
                .accessibilityIdentifier("prepare.readiness")
            Button("Check model readiness")
            {
                Task
                {
                    await refresh()
                }
            }
            .disabled(isChecking)
        }
        .task
        {
            await refresh()
        }
    }

    private func refresh() async
    {
        isChecking = true
        defer { isChecking = false }
        let updated = await service.readiness()
        guard !Task.isCancelled
        else
        {
            return
        }
        status = updated
    }
}
