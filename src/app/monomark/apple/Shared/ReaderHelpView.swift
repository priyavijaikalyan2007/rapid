// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b8472e35-085d-49e4-9108-cbb3b488e78c
// COMPONENT: Native offline help
// PURPOSE: Explain reading annotations, local storage, export, and recovery.
import SwiftUI

struct ReaderHelpView: View
{
    var showsDone = true
    @Environment(\.dismiss) private var dismiss
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                ForEach(ReaderInformation.help)
                { topic in
                    Section(topic.title)
                    {
                        Text(topic.detail).textSelection(.enabled)
                    }
                }
                #if os(macOS)
                Section("Reading-data folder")
                {
                    Text(URL.applicationSupportDirectory.appendingPathComponent("MonoMark").path)
                        .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
                #endif
            }
            .formStyle(.grouped)
            .navigationTitle("Monoleaf Help")
            .toolbar
            {
                if showsDone
                {
                    Button("Done")
                    {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 620, minHeight: 420)
    }
}
