// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 251435d5-6131-44c8-ac9c-ddc7a8ec5dfa
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Keep full-screen presentation scoped to one native window and one display.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import AppKit

/// Screen-limited presentation avoids changing Spaces or covering other displays.
final class ReaderWindow: NSWindow
{
    var togglePresentation: (() -> Void)?
    var dismissTemporary: (() -> Bool)?
    override var canBecomeKey: Bool
    {
        true
    }

    override var canBecomeMain: Bool
    {
        true
    }

    override func toggleFullScreen(_ sender: Any?)
    {
        togglePresentation?()
    }

    override func cancelOperation(_ sender: Any?)
    {
        if dismissTemporary?() == true
        {
            return
        }
        if styleMask.contains(.borderless) && !styleMask.contains(.titled)
        {
            togglePresentation?()
        }
    }
}
