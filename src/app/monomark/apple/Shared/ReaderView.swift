// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a098e35d-df1c-435d-a822-ab6ba708abc7
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Compose native toolbar, sidebar, search, and rendered-document surfaces.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import SwiftUI

/// Native window chrome surrounds a read-only document surface.
struct ReaderView: View
{
    @ObservedObject var session: ReaderSession
    @AppStorage("appearance-mode") private var appearance = "system"
    @FocusState private var findFocused: Bool
    var openFile: () -> Void
    var openFolder: () -> Void
    var body: some View
    {
        VStack(spacing: 0)
        {
            if session.showFind
            {
                HStack
                {
                    TextField("Find in document", text: $session.query).textFieldStyle(.roundedBorder)
                        .focused($findFocused)
                        .onSubmit
                        {
                            session.command(["type": "find", "query": session.query])
                        }
                    Button("Find")
                    {
                        session.command(["type": "find", "query": session.query])
                    }
                    Button("Previous")
                    {
                        session.command(["type": "next", "direction": -1])
                    }
                    Button("Next")
                    {
                        session.command(["type": "next", "direction": 1])
                    }
                    Button("Done")
                    {
                        session.showFind = false
                    }
                }.padding(8)
            }
            NavigationSplitView(columnVisibility: Binding(
                get: {
                    session.showSidebar ? .all : .detailOnly
                },
                set: {
                    session.showSidebar = $0 != .detailOnly
                }
            ))
            {
                SidebarView(session: session)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 420)
            }
            detail: {
                document
            }
            .navigationSplitViewStyle(.balanced)
            Divider()
            HStack
            {
                if session.isLoading
                {
                    ProgressView().controlSize(.small)
                }
                Text(session.message).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Spacer()
            }.padding(.horizontal, 10).padding(.vertical, 5)
        }
        .toolbar
        {
            ToolbarItemGroup
            {
                Button
                {
                    session.showSidebar.toggle()
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
                Button
                {
                    session.go(-1)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                Button
                {
                    session.go(1)
                } label: {
                    Label("Forward", systemImage: "chevron.right")
                }
                Button(action: openFile)
                {
                    Label("Open", systemImage: "doc")
                }
                Button
                {
                    session.showSettings = true
                } label: {
                    Label("Settings", systemImage: "textformat.size")
                }
            }
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .onChange(of: appearance)
        { _, value in
            session.command(["type": "appearance", "mode": value])
        }
        .onChange(of: session.rendererReady)
        { _, ready in
            if ready
            {
                session.command(["type": "appearance", "mode": appearance])
            }
        }
        .onChange(of: session.showFind)
        { _, value in
            findFocused = value
        }
        .sheet(isPresented: $session.showSettings)
        {
            ReaderSettings(session: session)
        }
    }

    private var document: some View
    {
        ZStack
        {
            if session.isSuspended
            {
                Color.clear
            }
            else
            {
                ReaderWebView(session: session)
            }
            if session.url == nil
            {
                ContentUnavailableView
                {
                    Label("MonoMark", systemImage: "doc.richtext")
                }
                description: {
                    Text("Read Markdown without editing it.")
                }
                actions: {
                    Button("Open File", action: openFile)
                    Button("Open Folder", action: openFolder)
                }
            }
        }
    }
}
