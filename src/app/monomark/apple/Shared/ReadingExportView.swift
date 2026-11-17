// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b4e5085b-713d-4dc7-b89e-72defa4cc663
// COMPONENT: Native reading-data export options
// PURPOSE: Make content, placement, and destination explicit before a Markdown write.
import SwiftUI

struct ReadingExportView: View
{
    var export: (ReadingExportOptions, ReadingExportDestination) -> Void
    var cancel: () -> Void
    @State private var options = ReadingExportOptions()
    @State private var destination = ReadingExportDestination.readingDataFile

    var body: some View
    {
        VStack(spacing: 0)
        {
            Form
            {
                Section("Include")
                {
                    Toggle("Annotations", isOn: $options.includeAnnotations)
                    Toggle("Notes", isOn: $options.includeNotes)
                }
                Section("Destination")
                {
                    Picker("Destination", selection: $destination)
                    {
                        #if os(macOS)
                        Text("Current Markdown file").tag(ReadingExportDestination.currentFile)
                        #endif
                        Text("Annotated document copy").tag(ReadingExportDestination.documentCopy)
                        Text("Separate reading-data file").tag(ReadingExportDestination.readingDataFile)
                    }
                }
                Section("Placement")
                {
                    Picker("Annotation placement", selection: $options.layout)
                    {
                        Text("Section at the end").tag(ReadingExportLayout.endSection)
                        Text("Inline after highlighted blocks").tag(ReadingExportLayout.inline)
                    }.disabled(!options.includeAnnotations || destination == .readingDataFile)
                    Text(
                        "Inline annotations follow complete blocks, including tables and code. Notes appear at the end."
                    )
                    .font(.caption).foregroundStyle(.secondary)
                    Text("Exports replace marked MonoMark sections. Reading data remains saved separately in the app.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
            Divider()
            HStack
            {
                Button("Cancel", action: cancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Export")
                {
                    var selected = options
                    selected.dataOnly = destination == .readingDataFile
                    export(selected, destination)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!options.includeAnnotations && !options.includeNotes)
            }.padding()
        }
        .frame(minWidth: 320, idealWidth: 560, minHeight: 440)
    }
}
