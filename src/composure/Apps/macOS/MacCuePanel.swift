// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000105
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import AppKit
import ComposureCore
import Observation
import SwiftUI

/// Observes only visibility state. SwiftUI observes cue text inside an existing non-activating panel.
@MainActor
final class MacCuePanel
{
    private let session: LiveSessionCoordinator
    private var panel: NonActivatingCuePanel?

    init(session: LiveSessionCoordinator)
    {
        self.session = session
        observe()
    }

    private func observe()
    {
        withObservationTracking
        {
            updateVisibility()
        }
        onChange:
        { [weak self] in
            Task
            { @MainActor in
                self?.observe()
            }
        }
    }

    private func updateVisibility()
    {
        let shouldShow = session.state == .listening || session.state == .stopping ||
            session.state == .stopUnconfirmed
        if shouldShow
        {
            if panel == nil
            {
                makePanel()
            }
            panel?.orderFrontRegardless()
        }
        else
        {
            panel?.orderOut(nil)
            panel?.close()
            panel = nil
        }
    }

    private func makePanel()
    {
        let panel = NonActivatingCuePanel(
            contentRect: NSRect(x: 0, y: 0, width: 372, height: 180),
            styleMask: [.titled, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Composure coach"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(rootView: MacCuePanelView(session: session))
        if let visible = NSScreen.main?.visibleFrame
        {
            panel.setFrameTopLeftPoint(NSPoint(x: visible.midX - panel.frame.width / 2, y: visible.maxY - 24))
        }
        self.panel = panel
    }
}
