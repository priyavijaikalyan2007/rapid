// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f4fecbc0-552e-4022-bcd7-80f861363afa
// Created: 2026
// COMPONENT: Native readiness setup
// PURPOSE: Present passive device status and explicitly requested speech setup through native controls.
// RELATES: ReadinessCoordinator, CoachingSettingsView
// FLOW: Settings status -> explicit setup action -> shared readiness updates.

import ComposureCore
import ComposureModels
import Foundation

/// One coordinator serializes setup across all windows. Debug fixtures cannot use the real provider.
@MainActor
enum ReadinessComposition
{
    static func makeCoordinator() -> ReadinessCoordinator
    {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-test-preferences") &&
            (arguments.contains("--ui-test-readiness") || arguments.contains("--ui-test-live"))
        {
            return ReadinessCoordinator(provider: UITestReadinessProvider(
                failsFirstSetup: arguments
                    .contains("--ui-test-setup-failure"),
                readyForLive: arguments.contains("--ui-test-live")
            ))
        }
        #endif
        return ReadinessCoordinator(provider: AppleReadinessService(), logger: ApplicationDiagnostics.makeLogger())
    }
}
