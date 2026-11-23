// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 1b9fb7cb-63be-48ba-9c5f-48171dfeed58
// Created: 2026
// COMPONENT: Monoleaf mobile scene
// PURPOSE: Adapt document sessions, picker grants and background saves to phone and tablet navigation.
// FLOW: Platform event -> mobile tab coordinator -> reader session.
import SwiftUI
import UniformTypeIdentifiers

struct MobileReaderView: View
{
    @StateObject private var tabs = MobileReaderTabs()
    @State private var picker = false
    @State private var folderPicker = false
    @State private var preparedTestFixture = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View
    {
        NavigationStack
        {
            ReaderView(session: tabs.current, openFile: {
                picker = true
            }, openFolder: {
                folderPicker = true
            })
            // A WKWebView and its resource/message handlers belong to exactly one document session.
            .id(tabs.selection.selectedID)
            .navigationTitle(tabs.current.url?.lastPathComponent ?? "Monoleaf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar
            {
                ToolbarItem(placement: .topBarLeading)
                {
                    documents
                }
            }
        }
        .fileImporter(isPresented: $picker, allowedContentTypes: [.plainText], allowsMultipleSelection: true)
        { result in
            if case .success(let files) = result, let first = files.first
            {
                tabs.current.open(first)
                for file in files.dropFirst()
                {
                    tabs.newTab(file: file)
                }
            }
        }
        .fileImporter(isPresented: $folderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false)
        { result in
            if case .success(let folders) = result, let folder = folders.first
            {
                tabs.current.openWorkspace(folder)
            }
        }
        .onOpenURL
        {
            tabs.current.open($0)
        }
        .onChange(of: scenePhase)
        { _, phase in
            if phase != .active
            {
                let background = UIApplication.shared.beginBackgroundTask()
                Task
                {
                    await tabs.checkpointAll()
                    if background != .invalid
                    {
                        UIApplication.shared.endBackgroundTask(background)
                    }
                }
            }
        }
        .onChange(of: horizontalSizeClass)
        { _, size in
            tabs.current.showSidebar = size == .regular
        }
        .onAppear(perform: prepareScene)
    }

    private var documents: some View
    {
        Menu
        {
            ForEach(tabs.selection.ids, id: \.self)
            { id in
                if let session = tabs.session(id)
                {
                    Button
                    {
                        tabs.select(id)
                    } label: {
                        Label(
                            session.url?.lastPathComponent ?? "Untitled",
                            systemImage: id == tabs.selection.selectedID ? "checkmark" : "doc"
                        )
                    }
                }
            }
            Divider()
            Button("New Tab")
            {
                tabs.newTab()
                picker = true
            }.keyboardShortcut("t")
            Button("Close Tab")
            {
                Task
                {
                    await tabs.closeCurrent()
                }
            }.keyboardShortcut("w").disabled(tabs.selection.ids.count == 1)
        } label: {
            Label("Documents", systemImage: "square.on.square")
        }
    }

    private func prepareScene()
    {
        tabs.current.showSidebar = horizontalSizeClass == .regular
        #if DEBUG
        guard !preparedTestFixture
        else
        {
            return
        }
        preparedTestFixture = true
        do
        {
            if let folder = try MobileReviewFixture.create()
            {
                tabs.current.open(folder.appendingPathComponent("First.md"), folder: folder)
            }
        }
        catch
        {
            tabs.current.fail(error)
        }
        #endif
    }
}
