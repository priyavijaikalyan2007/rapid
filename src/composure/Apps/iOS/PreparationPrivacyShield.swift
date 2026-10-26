// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4170287a-db41-4516-9d4e-a1010520f0bc
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Install a native scene privacy cover outside the sensitive preparation screen.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import SwiftUI
import UIKit

/// The native view observes scene deactivation synchronously before the system captures a snapshot.
struct PreparationPrivacyShield: UIViewRepresentable
{
    let onDeactivate: @MainActor () -> Void
    func makeUIView(context _: Context) -> PreparationPrivacyShieldView
    {
        PreparationPrivacyShieldView(onDeactivate: onDeactivate)
    }

    func updateUIView(_: PreparationPrivacyShieldView, context _: Context)
    {
    }
}
