// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 0dd385ac-f3e9-41e9-a3eb-b2137f43d45c
// COMPONENT: Native Markdown export document
// PURPOSE: Hand an explicit generated copy to the system document exporter.
// FLOW: Rendered export bytes -> system file picker -> user-selected destination.

import SwiftUI
import UniformTypeIdentifiers

struct MarkdownExportDocument: FileDocument
{
    static var readableContentTypes: [UTType]
    {
        [.plainText]
    }

    static var writableContentTypes: [UTType]
    {
        [UTType(filenameExtension: "md") ?? .plainText]
    }

    var data: Data

    init(data: Data)
    {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws
    {
        guard let data = configuration.file.regularFileContents
        else
        {
            throw ReaderFailure.invalidEncoding
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        FileWrapper(regularFileWithContents: data)
    }
}
