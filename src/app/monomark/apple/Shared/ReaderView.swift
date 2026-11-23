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
#if os(iOS)
import UIKit
#endif

/// Native window chrome surrounds a read-only document surface.
struct ReaderView: View
{
    @ObservedObject var session: ReaderSession
    @ObservedObject private var annotations: AnnotationController
    @AppStorage("appearance-mode") private var appearance = "system"
    @FocusState private var findFocused: Bool
    @State private var pendingExport: ReadingExportOptions?
    @State private var exportDestination = ReadingExportDestination.readingDataFile
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var exportDocument = MarkdownExportDocument(data: Data())
    @State private var showingExport = false
    @State private var exportName = "reading-notes"
    #endif
    var openFile: () -> Void
    var openFolder: () -> Void
    init(session: ReaderSession, openFile: @escaping () -> Void, openFolder: @escaping () -> Void)
    {
        self.session = session
        annotations = session.annotations
        self.openFile = openFile
        self.openFolder = openFolder
    }

    var body: some View
    {
        VStack(spacing: 0)
        {
            if session.showFind
            {
                #if os(iOS)
                MobileFindBar(session: session)
                #else
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
                #endif
            }
            navigation
            Divider()
            HStack
            {
                if session.isLoading
                {
                    ProgressView().controlSize(.small)
                }
                Text(session.message).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Spacer()
                if session.url != nil
                {
                    Text("Page \(session.currentPage) of ~\(session.totalPages)")
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        .help("Estimated from paper size and current layout. Printed page breaks can differ.")
                }
            }.padding(.horizontal, 10).padding(.vertical, 5)
        }
        .toolbar
        {
            #if os(macOS)
            ToolbarItemGroup
            {
                DocumentLocationView(session: session)
                Button
                {
                    session.refresh()
                }
                label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(session.url == nil)
                .help(session
                    .hasExternalChanges ? "The file changed. Refresh to read the latest content." :
                    "Reload this document")
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
                    annotations.shown.toggle()
                } label: {
                    Label("Notes and Annotations", systemImage: "sidebar.right")
                }
                Menu
                {
                    Button("Pageless")
                    {
                        session.setLayout("pageless")
                    }
                    Button("Pages")
                    {
                        session.setLayout("pages")
                    }
                } label: {
                    Label("Reading Layout", systemImage: "rectangle.split.1x2")
                }.help("Switch between Pages and Pageless")
                Button
                {
                    session.showSettings = true
                } label: {
                    Label("Settings", systemImage: "textformat.size")
                }
            }
            #else
            MobileReaderToolbar(session: session, openFile: openFile, openFolder: openFolder)
            {
                exportCopy()
            }
            #endif
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        #if os(macOS)
        .inspector(isPresented: $annotations.shown)
        {
            AnnotationInspector(session: session, controller: annotations)
                .inspectorColumnWidth(min: 260, ideal: 320, max: 480)
        }
        #endif
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
        .sheet(isPresented: $session.showExportOptions, onDismiss: performPendingExport)
        {
            ReadingExportView
            { options, destination in
                pendingExport = options
                exportDestination = destination
                session.showExportOptions = false
            }
            cancel: {
                session.showExportOptions = false
            }
        }
        #if os(iOS)
        .fileExporter(
            isPresented: $showingExport,
            document: exportDocument,
            contentType: MarkdownExportDocument.writableContentTypes[0],
            defaultFilename: exportName
        )
        { result in
            switch result
            {
            case .success: session.message = "Exported a copy. The original Markdown is unchanged."
            case .failure(let error): session.message = error.localizedDescription
            }
        }
        .onAppear
        {
            session.printAction = {
                guard let webView = session.webView
                else
                {
                    return
                }
                let printer = UIPrintInteractionController.shared
                let paperDelegate = ReaderPrintDelegate(paper: session.paperLayout)
                printer.delegate = paperDelegate
                printer.printFormatter = webView.viewPrintFormatter()
                printer.present(animated: true)
                { _, _, _ in
                    withExtendedLifetime(paperDelegate)
                    {
                    }
                    printer.delegate = nil
                    session.command(["type": "afterPrint"])
                }
            }
        }
        #endif
    }

    @ViewBuilder private var navigation: some View
    {
        #if os(iOS)
        if horizontalSizeClass == .compact
        {
            inspectedDocument
                .sheet(isPresented: $session.showSidebar)
                {
                    NavigationStack
                    {
                        SidebarView(session: session, openFolder: openFolder)
                            .navigationTitle("Navigation")
                            .toolbar
                            {
                                Button("Done")
                                {
                                    session.showSidebar = false
                                }
                            }
                    }.presentationDetents([.large])
                }
                .onChange(of: session.url)
                { _, _ in
                    session.showSidebar = false
                }
        }
        else
        {
            splitNavigation
        }
        #else
        splitNavigation
        #endif
    }

    private var splitNavigation: some View
    {
        NavigationSplitView(columnVisibility: Binding(
            get: {
                session.showSidebar ? .all : .detailOnly
            },
            set: {
                session.showSidebar = $0 != .detailOnly
            }
        ))
        {
            SidebarView(session: session, openFolder: openFolder)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 420)
        }
        detail: {
            inspectedDocument
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder private var inspectedDocument: some View
    {
        #if os(iOS)
        // The regular-width inspector must attach to the split view's detail column.
        document.inspector(isPresented: $annotations.shown)
        {
            AnnotationInspector(session: session, controller: annotations)
                .inspectorColumnWidth(min: 260, ideal: 320, max: 480)
        }
        #else
        document
        #endif
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
                    Label(session.root?.lastPathComponent ?? "Monoleaf", systemImage: "doc.richtext")
                }
                description: {
                    Text(session
                        .root == nil ? "Read Markdown without editing it." :
                        "Select a Markdown file in Files, or open a file.")
                }
                actions: {
                    Button("Open File", action: openFile)
                    Button("Open Folder", action: openFolder)
                }
            }
        }
    }

    private func performPendingExport()
    {
        guard let options = pendingExport
        else
        {
            return
        }
        pendingExport = nil
        #if os(macOS)
        session.exportAction?(options, exportDestination)
        #else
        exportCopy(options: options)
        #endif
    }

    #if os(iOS)
    private func exportCopy(options: ReadingExportOptions = ReadingExportOptions())
    {
        guard let source = session.url
        else
        {
            return
        }
        Task
        {
            guard await annotations.drain()
            else
            {
                return
            }
            do
            {
                let needsSource = !options.dataOnly || (options.includeAnnotations && !annotations.records.isEmpty)
                let notes = try await session.readingNotesForExport(
                    includeAnnotations: options.includeAnnotations,
                    requireSource: needsSource
                )
                let data = try await Task.detached(priority: .userInitiated)
                {
                    let text = needsSource ? String(decoding: try DocumentAccess.read(source), as: UTF8.self) : ""
                    return Data(try options.render(source: text, notes: notes).utf8)
                }.value
                exportDocument = MarkdownExportDocument(data: data)
                exportName = source.deletingPathExtension().lastPathComponent +
                    (options.dataOnly ? "-reading-data" : "-reading-notes")
                showingExport = true
            }
            catch
            {
                session.message = error.localizedDescription
            }
        }
    }
    #endif
}
