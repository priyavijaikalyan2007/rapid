// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 62315c7e-5a17-4053-b8bc-dc0b23f637ae
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Present a lazy, native, keyboard-navigable folder tree.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Expand only the selected directory so deep trees do not block document opening.
struct FolderRow: View
{
    let entry: FolderEntry
    @ObservedObject var session: ReaderSession
    @State private var children: [FolderEntry] = []
    @State private var expanded = false

    var body: some View
    {
        if entry.isFolder
        {
            DisclosureGroup(isExpanded: $expanded)
            {
                ForEach(children)
                { child in
                    FolderRow(entry: child, session: session)
                }
            }
            label: {
                Label(entry.title, systemImage: "folder")
            }
            .onChange(of: expanded)
            { _, value in
                guard value
                else
                {
                    return
                }
                Task
                {
                    do
                    {
                        children = try await Task.detached
                        {
                            try FolderEntry.children(of: entry.url)
                        }.value
                    }
                    catch
                    {
                        session.message = "This folder cannot be listed. Check its permissions."
                    }
                }
            }
            .task(id: session.url)
            {
                if DocumentPresentation.reveals(entry.url, document: session.url)
                {
                    expanded = true
                    do
                    {
                        children = try await Task.detached
                        {
                            try FolderEntry.children(of: entry.url)
                        }.value
                    }
                    catch
                    {
                        session.message = "This folder cannot be listed. Check its permissions."
                    }
                }
            }
        }
        else
        {
            Button
            {
                openFile()
            }
            label: {
                HStack
                {
                    Label(entry.title, systemImage: "doc.text")
                    Spacer()
                    if DocumentPresentation.isSelected(session.url, file: entry.url)
                    {
                        Image(systemName: "checkmark").accessibilityLabel("Current document")
                    }
                }
                .padding(4)
                .background(
                    DocumentPresentation.isSelected(session.url, file: entry.url) ? Color.accentColor
                        .opacity(0.18) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(entry.url
                .path + "\nUse Open in New Tab from the context menu. On Mac, Command-click also opens a new tab.")
            .accessibilityValue(DocumentPresentation.isSelected(session.url, file: entry.url) ? "Current document" : "")
            .contextMenu
            {
                Button("Open in New Tab")
                {
                    session.openNewTab?(entry.url, session.root)
                }
            }
        }
    }

    /// Follow Mac file navigation conventions while preserving the ordinary single-tab action.
    private func openFile()
    {
        #if os(macOS)
        let modifiers = NSApp.currentEvent?.modifierFlags ?? NSEvent.modifierFlags
        if modifiers.contains(.command), let openNewTab = session.openNewTab
        {
            openNewTab(entry.url, session.root)
            return
        }
        #endif
        session.open(entry.url, folder: session.root)
    }
}
