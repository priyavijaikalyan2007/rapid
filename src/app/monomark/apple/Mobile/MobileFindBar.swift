// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 4ec310fd-e2e0-4e0b-b79b-6db9737fb8ed
// COMPONENT: Phone document search
// PURPOSE: Fit search and match navigation inside compact widths without hiding the text field.
import SwiftUI

struct MobileFindBar: View
{
    @ObservedObject var session: ReaderSession
    @FocusState private var focused: Bool

    var body: some View
    {
        VStack(spacing: 8)
        {
            HStack
            {
                TextField("Find in document", text: $session.query)
                    .textFieldStyle(.roundedBorder).focused($focused)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .submitLabel(.search).onSubmit(find)
                Button("Done")
                {
                    session.showFind = false
                }.keyboardShortcut(.cancelAction)
            }
            HStack
            {
                Button("Previous", systemImage: "chevron.up")
                {
                    session.command(["type": "next", "direction": -1])
                }
                Button("Next", systemImage: "chevron.down")
                {
                    session.command(["type": "next", "direction": 1])
                }
                Spacer()
                Button("Find", action: find)
            }
        }.padding(10).onAppear
        {
            focused = true
        }
    }

    private func find()
    {
        session.command(["type": "find", "query": session.query])
    }
}
