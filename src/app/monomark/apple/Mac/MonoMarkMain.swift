// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9fdfa970-25f7-43d8-8cd7-5b86a4a2e752
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Launch the native Mac document application.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import AppKit

/// AppKit owns Mac document windows and their standard responder behavior.
@main
struct MonoMarkMain
{
    @MainActor static func main()
    {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate)
        {
            app.run()
        }
    }
}
