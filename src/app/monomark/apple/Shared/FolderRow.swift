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
        }
        else
        {
            Button
            {
                session.open(entry.url, folder: session.root)
            }
            label: {
                Label(entry.title, systemImage: "doc.text")
            }
            .buttonStyle(.plain)
            .help(entry.url.path)
            .contextMenu
            {
                Button("Open in New Tab")
                {
                    session.openNewTab?(entry.url, session.root)
                }
            }
        }
    }
}
