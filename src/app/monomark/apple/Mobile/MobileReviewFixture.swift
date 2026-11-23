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
    private static let testID: UUID? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--smoke-test") || arguments.contains("--demo")
        else
        {
            return nil
        }
        if let index = arguments.firstIndex(of: "--mobile-test-session"), arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1])
        {
            return id
        }
        return UUID()
    }()

    private static var root: URL?
    {
        testID.map
        {
            FileManager.default.temporaryDirectory
                .appendingPathComponent("monoleaf-mobile-tests-\($0.uuidString)")
        }
    }

    static var storageDirectory: URL?
    {
        root?.appendingPathComponent("ReadingData")
    }

    static var defaults: UserDefaults?
    {
        testID.flatMap
        {
            UserDefaults(suiteName: "us.outcrop.Monoleaf.tests.\($0.uuidString)")
        }
    }

    static func create() throws -> URL?
    {
        guard ProcessInfo.processInfo.arguments.contains("--smoke-test"),
              ProcessInfo.processInfo.arguments.contains("--mobile-ui-test"),
              let folder = root?.appendingPathComponent("Documents")
        else
        {
            return nil
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, text) in [
            ("First.md", "# Mobile first document\n\nSelect this passage for a reading note.\n\n[Second](Second.md)\n"),
            ("Second.md", "# Mobile second document\n\nThe second tab has its own document.\n\n[Third](Third.md)\n"),
            ("Third.md", "# Mobile third document\n\nThe third tab also supports navigation.\n"),
            ("Rich.md", richSource)
        ]
        {
            let file = folder.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: file.path)
            {
                try Data(text.utf8).write(to: file)
            }
        }
        return folder
    }

    private static let richSource = """
        # Mobile rich content

        | Feature | Value |
        | --- | --- |
        | Local | Yes |

        ```csharp
        public bool IsReady(int count)
        {
            return count > 0;
        }
        ```

        $$
        E = mc^2
        $$

        ```mermaid
        flowchart LR
            A[Read] --> B[Take notes]
        ```
        """
}
#endif
