// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c415cb7c-ad8c-4fd0-b970-e85e20d99371
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Launch the iOS and iPadOS document viewer.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import SwiftUI
import UniformTypeIdentifiers

/// The mobile target shares document logic and rendering while using native file pickers and adaptive navigation.
@main
struct MonoMarkMobile: App
{
    var body: some Scene
    {
        WindowGroup
        {
            MobileReaderView()
        }
    }
}
