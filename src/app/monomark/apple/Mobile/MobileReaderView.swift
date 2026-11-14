// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1b9fb7cb-63be-48ba-9c5f-48171dfeed58
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Adapt document tabs and file access to phone and tablet navigation.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import SwiftUI
import UniformTypeIdentifiers

/// A native menu keeps document tabs reachable at narrow phone widths.
struct MobileReaderView: View
{
    @State private var sessions: [ReaderSession] = [ReaderSession()]
    @State private var selected = 0
    @State private var picker = false
    @State private var folderPicker = false
    var body: some View
    {
        NavigationStack
        {
            ReaderView(session: sessions[selected], openFile: {
                picker = true
            }, openFolder: {
                folderPicker = true
            })
            .navigationTitle(sessions[selected].url?.lastPathComponent ?? "MonoMark")
            .toolbar
            {
                ToolbarItem(placement: .topBarTrailing)
                {
                    Menu("Documents")
                    {
                        ForEach(Array(sessions.enumerated()), id: \.offset)
                        { index, session in
                            Button(session.url?.lastPathComponent ?? "Untitled")
                            {
                                selected = index
                            }
                        }
                        Button("New Tab")
                        { sessions.append(ReaderSession())
                            selected = sessions.count - 1
                            picker = true
                        }
                        if sessions.count > 1
                        {
                            Button("Close Tab")
                            { sessions[selected].close()
                                sessions.remove(at: selected)
                                selected = max(0, selected - 1)
                            }
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $picker, allowedContentTypes: [.plainText], allowsMultipleSelection: false)
        { result in
            if case .success(let files) = result, let file = files.first
            {
                sessions[selected].open(file)
            }
        }
        .fileImporter(isPresented: $folderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false)
        { result in
            if case .success(let folders) = result, let folder = folders.first
            {
                if folder.startAccessingSecurityScopedResource()
                {
                }
                Task
                {
                    await sessions[selected].loadFolder(folder)
                }
            }
        }
        .onOpenURL
        {
            sessions[selected].open($0)
        }
        .onAppear
        {
            sessions[selected].showSidebar = UIDevice.current.userInterfaceIdiom == .pad
            sessions[selected].openNewTab = { file, root in
                let session = ReaderSession()
                session.open(file, folder: root)
                sessions.append(session)
                selected = sessions.count - 1
            }
        }
    }
}
