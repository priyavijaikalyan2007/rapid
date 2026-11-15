// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9462abee-62a8-49de-a514-50fca99660ea
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Render native Files, Contents, Links, and paged History navigation.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import SwiftUI

/// Four navigation sections always refer to the active document or its complete local history.
struct SidebarView: View
{
    @ObservedObject var session: ReaderSession
    var openFolder: () -> Void
    var body: some View
    {
        VStack(spacing: 0)
        {
            WorkspaceMenu(session: session, openFolder: openFolder).padding(.horizontal, 10).padding(.top, 8)
            Divider()
            Picker("Navigation", selection: $session.section)
            {
                ForEach(["Files", "Contents", "Links", "History"], id: \.self)
                {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)
            Divider()
            content
        }
        .frame(minWidth: 210, idealWidth: 260, maxWidth: 420)
        .onChange(of: session.section)
        { _, value in
            if value == "History"
            {
                session.refreshHistory()
            }
        }
    }

    @ViewBuilder private var content: some View
    {
        switch session.section
        {
        case "Files":
            List(session.entries)
            {
                FolderRow(entry: $0, session: session)
            }
            .overlay
            {
                if session.entries
                    .isEmpty
                {
                    Text(session.root != nil && session.root != session
                        .url ? "No Markdown files in this workspace." : "Open a folder to browse Markdown files.")
                        .foregroundStyle(.secondary).padding()
                }
            }
        case "Contents":
            List(session.outline)
            { entry in
                Button
                {
                    session.command(["type": "jump", "id": entry.id])
                }
                label: {
                    Text(entry.title).padding(.leading, CGFloat(max(0, entry.level - 1) * 10))
                        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(entry.kind.capitalized)
            }
        case "Links":
            List(Array(session.links.enumerated()), id: \.offset)
            { _, link in
                VStack(alignment: .leading, spacing: 4)
                {
                    Button(link.title)
                    {
                        session.navigate(link.href)
                    }
                    Text(link.href).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                .contextMenu
                {
                    Button("Open")
                    {
                        session.navigate(link.href)
                    }
                    Button("Open in New Tab")
                    {
                        session.navigate(link.href, newTab: true)
                    }
                    Button("Copy Link")
                    {
                        session.copy(link.href)
                    }
                    Button("Show in Document")
                    {
                        session.command(["type": "jump", "id": link.blockID])
                    }
                }
            }
        default: history
        }
    }

    private var history: some View
    {
        VStack
        {
            TextField("Search history", text: $session.historyQuery).textFieldStyle(.roundedBorder).padding(8)
                .onChange(of: session.historyQuery)
                { _, _ in
                    session.refreshHistory()
                }
            List
            {
                ForEach(session.history)
                { record in
                    Button
                    {
                        session.reopen(record)
                    }
                    label: {
                        VStack(alignment: .leading)
                        {
                            Text(record.title)
                            Text(record.path).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu
                    {
                        Button("Forget")
                        {
                            session.forget(record)
                        }
                    }
                }
                if session.history.count >= 100
                {
                    Button("Load More History")
                    {
                        session.refreshHistory(append: true)
                    }
                }
            }
        }
    }
}
