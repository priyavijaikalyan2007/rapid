// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 92412d9b-cc50-44c5-9930-7c011476f609
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Inject one on-device service and keep Debug UI tests independent of model assets.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import ComposureCore
import ComposureModels
import Foundation

/// One service per app bounds model concurrency across all windows. Each window owns its editable state.
@MainActor
enum PreparationComposition
{
    static func makeService() -> PreparationService
    {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-test-preferences") && arguments.contains("--ui-test-model-unavailable")
        {
            return PreparationService(model: UnavailablePreparationModel())
        }
        #endif
        return PreparationService(model: AppleFoundationCoachingModel())
    }

    static func makeCoordinator(service: PreparationService) -> PreparationCoordinator
    {
        PreparationCoordinator(service: service, logger: ApplicationDiagnostics.makeLogger())
    }
}
