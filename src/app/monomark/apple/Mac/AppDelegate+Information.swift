// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 07fb9c7a-3367-41d4-bc34-3aa4fbba72ac
// COMPONENT: Mac information windows
// PURPOSE: Provide native reusable About and Help windows following CropPrint conventions.
import AppKit
import SwiftUI

extension AppDelegate
{
    @objc func showAbout(_ sender: Any?)
    {
        information("About Monoleaf", content: ReaderAboutView(showsDone: false))
    }

    @objc func showHelp(_ sender: Any?)
    {
        information("Monoleaf Help", content: ReaderHelpView(showsDone: false))
    }

    private func information<Content: View>(_ title: String, content: Content)
    {
        if let controller = informationWindows[title]
        {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 140, y: 140, width: 620, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = NSHostingController(rootView: content)
        let controller = NSWindowController(window: window)
        informationWindows[title] = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
