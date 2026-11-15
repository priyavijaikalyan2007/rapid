// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e9db7cef-c3b0-40c0-bcff-88adf3807706
// COMPONENT: Native workspace switcher
// PURPOSE: Expose recent folder workspaces without replacing document tabs or reading history.
import SwiftUI

struct WorkspaceMenu: View
{
    @ObservedObject var session: ReaderSession
    @ObservedObject private var library: WorkspaceLibrary
    var openFolder: () -> Void

    init(session: ReaderSession, openFolder: @escaping () -> Void)
    {
        self.session = session
        library = session.workspaces
        self.openFolder = openFolder
    }

    var body: some View
    {
        Menu
        {
            Button("Open Folder as Workspace…", action: openFolder)
            Divider()
            ForEach(library.records)
            { record in
                Button
                {
                    session.switchWorkspace(record)
                } label: {
                    Label(
                        record.title + " — " + record.folder.deletingLastPathComponent().path,
                        systemImage: DocumentPresentation
                            .isSelected(session.root, file: record.folder) ? "checkmark" : "folder"
                    )
                }
            }
            if let error = library.error
            {
                Text(error)
                Button("Retry Workspace List")
                {
                    Task
                    {
                        await library.refresh()
                    }
                }
            }
            if let current = library.records.first(where: { DocumentPresentation.isSelected(
                session.root,
                file: $0.folder
            ) })
            {
                Divider()
                Button("Forget This Workspace")
                {
                    Task
                    {
                        await library.forget(current)
                    }
                }
            }
        } label: {
            Label(title, systemImage: "folder")
                .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
        }
        .help("Switch recent workspaces. Other document tabs stay open. Forgetting keeps files and reading notes.")
        .accessibilityLabel("Workspace: " + title)
        .task
        {
            await library.refresh()
        }
    }

    private var title: String
    {
        if let root = session.root, root != session.url
        {
            return root.lastPathComponent
        }
        return "Workspaces"
    }
}
