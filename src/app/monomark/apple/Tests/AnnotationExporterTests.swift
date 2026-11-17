// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 26c7a3f0-427a-459b-be5f-678b0111ce0f
// COMPONENT: Generated annotation export tests
// PURPOSE: Protect original Markdown outside the app-owned export section.

import Foundation
import Testing
@testable import MonoMarkCore

struct AnnotationExporterTests
{
    @Test func exportsSectionAndSourceLineRange() throws
    {
        let location = SourceLocation(line: 8, endLine: 11, section: "3. Queries › Operators")
        let anchor = TextAnchor(blockID: "b", quote: "A quote", prefix: "", suffix: "", start: 0, location: location)
        let result = try AnnotationExporter.render(
            source: "",
            notes: ReadingNotes(annotations: [ReadingAnnotation(anchors: [anchor])])
        )
        #expect(result.contains("**Section:** 3\\. Queries › Operators"))
        #expect(result.contains("**Source lines:** 8–11"))
    }

    let start = "<!-- monomark:reading-data:start -->"
    let end = "<!-- monomark:reading-data:end -->"

    @Test func repeatedExportReplacesOnlyOwnedSection() throws
    {
        let source = "# Original\n\nProse.\n"
        let notes = ReadingNotes(text: "First")
        let first = try AnnotationExporter.render(source: source, notes: notes)
        let second = try AnnotationExporter.render(source: first, notes: ReadingNotes(text: "Second"))
        #expect(second.hasPrefix(source))
        #expect(!second.contains("> First"))
        #expect(second.contains("> Second"))
        #expect(try AnnotationExporter.render(source: second, notes: ReadingNotes(text: "Second")) == second)
    }

    @Test func preservesSuffixAndCRLF() throws
    {
        let source = "# 日本語\r\n" + start + "\r\nold\r\n" + end + "\r\nSuffix  \r\n"
        let result = try AnnotationExporter.render(source: source, notes: ReadingNotes(text: "Note"))
        #expect(result.hasPrefix("# 日本語\r\n"))
        #expect(result.hasSuffix("Suffix  \r\n"))
        #expect(!result.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
    }

    @Test(arguments: ["missing-end", "duplicate", "reversed"])
    func refusesMalformedMarkers(_ kind: String) throws
    {
        let sources = [
            "missing-end": start,
            "duplicate": start + "\n" + start + "\n" + end,
            "reversed": end + "\n" + start
        ]
        #expect(throws: (any Error).self)
        {
            try AnnotationExporter.render(source: sources[kind]!, notes: ReadingNotes())
        }
    }

    @Test func ignoresLiteralMarkersInCode() throws
    {
        let source = "```html\n" + start + "\n" + end + "\n```\n"
        let result = try AnnotationExporter.render(source: source, notes: ReadingNotes(text: "Notes"))
        #expect(result.hasPrefix(source))
        #expect(try AnnotationExporter.render(source: result, notes: ReadingNotes(text: "Notes")) == result)
    }

    @Test func generatedUserTextCannotCreateExportMarkers() throws
    {
        let text = "```\n" + end + "\n" + start + "\n"
        let result = try AnnotationExporter.render(source: "Prose", notes: ReadingNotes(text: text))
        #expect(try AnnotationExporter.render(source: result, notes: ReadingNotes(text: text)) == result)
    }

    @Test func exportsQuoteColorAndComment() throws
    {
        let mark = ReadingAnnotation(
            anchors: [TextAnchor(blockID: "b", quote: "A quote", prefix: "", suffix: "", start: 0)],
            color: "green",
            comment: "A comment"
        )
        let result = try AnnotationExporter.render(source: "", notes: ReadingNotes(annotations: [mark]))
        #expect(result.contains("> A quote"))
        #expect(result.contains("green"))
        #expect(result.contains("**Comment:**\n\nA comment"))
        #expect(result.contains("**Highlighted text:**\n\n> A quote"))
        #expect(!result.contains("> A comment"))
        #expect(result.contains("Auto-generated"))
    }

    @Test func refusesToAppendInsideUnclosedFence() throws
    {
        #expect(throws: (any Error).self)
        {
            try AnnotationExporter.render(source: "```swift\nlet x = 1", notes: ReadingNotes())
        }
    }

    @Test func plainNotesRemainLiteralMarkdown() throws
    {
        let result = try AnnotationExporter.render(
            source: "",
            notes: ReadingNotes(text: "**Literal**\n```", format: "plain")
        )
        #expect(result.contains("> ````text\n> **Literal**\n> ```\n> ````"))
    }
}
