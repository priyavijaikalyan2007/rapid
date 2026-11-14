// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 9e027f4b-6bbf-41c9-8442-07a278ab1cf6
// COMPONENT: Active document presentation tests
// PURPOSE: Verify document identity, visible paths, and ancestor expansion boundaries.
import Foundation
import Testing
@testable import MonoMarkCore

struct DocumentPresentationTests
{
    @Test func identifiesNormalizedOpenPath() throws
    {
        #expect(DocumentPresentation.isSelected(
            URL(fileURLWithPath: "/tmp/book.md"),
            file: URL(fileURLWithPath: "/tmp/folder/../book.md")
        ))
        #expect(!DocumentPresentation.isSelected(nil, file: URL(fileURLWithPath: "/tmp/book.md")))
    }

    @Test func titleRetainsCopyableFullUnicodePath() throws
    {
        let file = URL(fileURLWithPath: "/tmp/My Folder/日本語.md")
        #expect(DocumentPresentation.title(file) == file.path)
    }

    @Test func revealsOnlyActualAncestors() throws
    {
        let file = URL(fileURLWithPath: "/tmp/books/chapter/book.md")
        #expect(DocumentPresentation.reveals(URL(fileURLWithPath: "/tmp/books"), document: file))
        #expect(!DocumentPresentation.reveals(URL(fileURLWithPath: "/tmp/book"), document: file))
    }
}
