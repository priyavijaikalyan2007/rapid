// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7f450f24-61fd-40b8-acee-bc9a29b90058
// Created: 2026
// COMPONENT: Application navigation
// PURPOSE: Keep native navigation labels consistent across platform shells.
// RELATES: MacRootView, MobileRootView, FeaturePlaceholder
// FLOW: Native selection -> section -> visible feature surface.

/// Identifies the four top-level product areas without storing meeting content.
enum AppSection: String, CaseIterable, Identifiable
{
    case home = "Home"
    case prepare = "Prepare"
    case live = "Live Coach"
    case settings = "Settings"

    var id: Self
    {
        self
    }

    /// Uses native symbols alongside text, so navigation never depends on icons alone.
    var symbol: String
    {
        switch self
        {
        case .home: return "house"
        case .prepare: return "text.bubble"
        case .live: return "waveform"
        case .settings: return "gearshape"
        }
    }

    /// Makes unavailable behavior explicit in this development foundation.
    var detail: String
    {
        switch self
        {
        case .home:
            return "Private coaching for deliberate conversations. Preparation and live coaching are not available yet."
        case .prepare:
            return "Conversation preparation is not available in this build."
        case .live:
            return "Live coaching is not available in this build. Composure is not listening."
        case .settings:
            return "Coaching preferences and on-device readiness checks are not available in this build."
        }
    }
}
