// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e7ca0a67-afb3-47a1-8cee-b6a09bf387b8
// COMPONENT: Native document location
// PURPOSE: Keep the full path and Copy action stable while the pointer moves.
import SwiftUI

/// A click opens a persistent popover, independent of the system title's temporary path expansion.
struct DocumentLocationView: View
{
    @ObservedObject var session: ReaderSession
    @State private var presented = false
    @State private var copied = false

    var body: some View
    {
        Button
        {
            copied = false
            presented.toggle()
        }
        label: {
            Label("Document Location", systemImage: "folder")
        }
        .help("Show and copy the full document path")
        .disabled(session.url == nil)
        .popover(isPresented: $presented)
        {
            VStack(alignment: .leading, spacing: 12)
            {
                Text("Document path").font(.headline)
                Text(session.url?.path ?? "")
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack
                {
                    if copied
                    {
                        Text("Copied").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Copy Path")
                    {
                        if let path = session.url?.path
                        {
                            session.copy(path)
                            copied = true
                        }
                    }
                }
            }.padding().frame(minWidth: 240, idealWidth: 420, maxWidth: 420)
        }
    }
}
