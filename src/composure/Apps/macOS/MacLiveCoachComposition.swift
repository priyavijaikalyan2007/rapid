// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000106
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import ComposureCore
import ComposureModels
import Foundation

/// One app-owned capture session, cue panel, and model work slot serve every Mac window.
@MainActor
final class MacLiveCoachComposition
{
    let session: LiveSessionCoordinator
    let preparation: PreparationService
    private let panel: MacCuePanel

    init()
    {
        let model = AppleFoundationCoachingModel()
        preparation = PreparationService(model: model)
        var source: any LiveTranscriptionSource = MacMeetingAudioSource()
        var liveModel: any LiveCoachingModel = model
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-test-preferences") && arguments.contains("--ui-test-live")
        {
            source = UITestLiveSource()
            liveModel = UITestLiveModel()
        }
        #endif
        session = LiveSessionCoordinator(
            source: source,
            model: liveModel,
            clock: {
                MacMeetingAudioSource.now()
            },
            logger: ApplicationDiagnostics.makeLogger()
        )
        panel = MacCuePanel(session: session)
    }
}
