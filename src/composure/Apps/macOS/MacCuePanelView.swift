// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b47d9bf0-09c2-4c54-b39d-000000000104
// Created: 2026
// COMPONENT: Native Mac live coaching
// PURPOSE: Present explicit listening controls and one brief cue without transcript display or persistence.
// RELATES: MacLiveCoachComposition, LiveSessionCoordinator, MacCuePanel
// FLOW: Explicit Start -> selected audio -> private coaching -> floating cue -> Stop and clear.

import ComposureCore
import SwiftUI

/// Native glanceable content. Generated instructions use plain text and never become markup.
struct MacCuePanelView: View
{
    @Bindable var session: LiveSessionCoordinator

    var body: some View
    {
        VStack(alignment: .leading, spacing: 12)
        {
            HStack
            {
                Label(
                    session.state == .listening ? "Composure — Listening" : "Composure — " + session.state.rawValue,
                    systemImage: "waveform"
                )
                .font(.subheadline)
                Spacer()
                Button("Stop")
                {
                    Task
                    {
                        await session.stop()
                    }
                }
                .accessibilityIdentifier("live.panel.stop")
                .disabled(!session.canStop || session.state == .stopping)
            }
            if let cue = session.cue
            {
                Text(verbatim: cue.kind.headline).font(.headline)
                Text(verbatim: cue.instruction).font(.body).fixedSize(horizontal: false, vertical: true)
            }
            else if let error = session.error
            {
                Text(verbatim: error.errorDescription ?? "").font(.callout)
            }
            else
            {
                Text(session.isCoachingAvailable ? "A cue appears when an action could help." :
                    "Coaching is temporarily unavailable. Listening continues.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}
