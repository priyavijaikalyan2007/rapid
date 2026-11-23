// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 6a39fb77-7fac-41a9-8034-41dfac56f1b6
// COMPONENT: Isolated mobile native test documents
// PURPOSE: Exercise actual file navigation without opening personal documents or reading data.
// FLOW: Explicit Debug test argument -> app-owned temporary examples -> native reader.
#if DEBUG
import Foundation

enum MobileReviewFixture
{
    static func create() throws -> URL?
    {
        guard ProcessInfo.processInfo.arguments.contains("--smoke-test"),
              ProcessInfo.processInfo.arguments.contains("--mobile-ui-test")
        else
        {
            return nil
        }
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("monoleaf-mobile-examples-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, text) in [
            ("First.md", "# Mobile first document\n\nSelect this passage for a reading note.\n\n[Second](Second.md)\n"),
            ("Second.md", "# Mobile second document\n\nThe second tab has its own document.\n\n[Third](Third.md)\n"),
            ("Third.md", "# Mobile third document\n\nThe third tab also supports navigation.\n")
        ]
        {
            try Data(text.utf8).write(to: folder.appendingPathComponent(name))
        }
        return folder
    }
}
#endif
