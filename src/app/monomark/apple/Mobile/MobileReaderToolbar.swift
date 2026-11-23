// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 3fc8d398-faf7-4b18-8d68-f6f2a6ea3380
// COMPONENT: Compact native reader actions
// PURPOSE: Keep primary controls reachable on phones and retain secondary commands in one native menu.
// FLOW: Toolbar or keyboard action -> existing reader session service.
import SwiftUI

struct MobileReaderToolbar: ToolbarContent
{
    @ObservedObject var session: ReaderSession
    var openFile: () -> Void
    var openFolder: () -> Void
    var exportCopy: () -> Void

    var body: some ToolbarContent
    {
        ToolbarItemGroup(placement: .topBarTrailing)
        {
            Button(action: openFile)
            {
                Label("Open File", systemImage: "doc.badge.plus")
            }.keyboardShortcut("o")
            Button
            {
                session.annotations.shown.toggle()
            } label: {
                Label("Notes and Annotations", systemImage: "sidebar.right")
            }.disabled(session.url == nil)
            Menu
            {
                Button("Open Folder", systemImage: "folder", action: openFolder)
                Button("Files and Contents", systemImage: "sidebar.left")
                {
                    session.showSidebar.toggle()
                }
                documentActions
                Button("Settings", systemImage: "textformat.size")
                {
                    session.showSettings = true
                }
            } label: {
                Label("Document Actions", systemImage: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder private var documentActions: some View
    {
        Section("Document")
        {
            Button("Find in Document", systemImage: "magnifyingglass")
            {
                session.showFind = true
            }.keyboardShortcut("f").disabled(session.url == nil)
            Button("Refresh", systemImage: "arrow.clockwise")
            {
                session.refresh()
            }.disabled(session.url == nil)
            Button("Copy Document Path", systemImage: "doc.on.doc")
            {
                if let url = session.url
                {
                    session.copy(url.path)
                }
            }.disabled(session.url == nil)
            Menu("Reading Layout", systemImage: "rectangle.split.1x2")
            {
                Button("Pageless")
                {
                    session.setLayout("pageless")
                }
                Button("Pages")
                {
                    session.setLayout("pages")
                }
            }
            Button("Back", systemImage: "chevron.left")
            {
                session.go(-1)
            }
            Button("Forward", systemImage: "chevron.right")
            {
                session.go(1)
            }
        }
        Section("Share")
        {
            Button("Export Reading Data…", systemImage: "square.and.arrow.up")
            {
                session.showExportOptions = true
            }.disabled(session.url == nil || !session.annotations.ready)
            Button("Export a Copy…", action: exportCopy)
                .disabled(session.url == nil || !session.annotations.ready)
            Button("Print…", systemImage: "printer")
            {
                session.command(["type": "print"])
            }.keyboardShortcut("p").disabled(session.url == nil)
        }
    }
}
