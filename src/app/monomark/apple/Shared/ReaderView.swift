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
    #if os(iOS)
    @State private var exportDocument = MarkdownExportDocument(data: Data())
    @State private var showingExport = false
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
                #if os(iOS)
                Menu
                {
                    Button("Export a Copy…")
                    {
                        exportCopy()
                    }.disabled(!annotations.ready)
                    Button("Print…")
                    {
                        session.command(["type": "print"])
                    }.keyboardShortcut("p")
                } label: {
                    Label("Document Actions", systemImage: "square.and.arrow.up")
                }
                #endif
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
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .inspector(isPresented: $annotations.shown)
        {
            AnnotationInspector(session: session, controller: annotations)
                .inspectorColumnWidth(min: 260, ideal: 320, max: 480)
        }
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
        #if os(iOS)
        .fileExporter(
            isPresented: $showingExport,
            document: exportDocument,
            contentType: MarkdownExportDocument.writableContentTypes[0],
            defaultFilename: (session.url?.deletingPathExtension().lastPathComponent ?? "Document") +
                "-reading-notes"
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

    #if os(iOS)
    private func exportCopy()
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
            let notes = ReadingNotes(
                annotations: annotations.records,
                text: annotations.text,
                format: annotations.format
            )
            do
            {
                let data = try await Task.detached(priority: .userInitiated)
                {
                    let bytes = try DocumentAccess.read(source)
                    return Data(try AnnotationExporter.render(
                        source: String(decoding: bytes, as: UTF8.self),
                        notes: notes
                    ).utf8)
                }.value
                exportDocument = MarkdownExportDocument(data: data)
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
