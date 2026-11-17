// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: fdd97d7b-40dd-4c81-adc8-f2dff18e29d6
// COMPONENT: Inline and selective export contracts
// PURPOSE: Protect source bytes, repeatability, and complete Markdown blocks.
import Foundation
import Testing
@testable import MonoMarkCore

struct InlineExportTests
{
    let source = "# Document\n\nFirst source.\n\n## Next\n\nSecond source.\n"

    private func annotation(_ quote: String, line: Int, endLine: Int? = nil) -> ReadingAnnotation
    {
        ReadingAnnotation(anchors: [TextAnchor(
            blockID: "b",
            quote: quote,
            prefix: "",
            suffix: "",
            start: 0,
            location: SourceLocation(line: line, endLine: endLine ?? line, section: "Document")
        )], comment: "A comment")
    }

    private func notes(_ source: String, annotations: [ReadingAnnotation], text: String = "") -> ReadingNotes
    {
        ReadingNotes(annotations: annotations, text: text, sourceHash: DocumentStamp.make(source))
    }

    @Test func inlineAnnotationsFollowTheirSourceBlocksAndNotesRemainAtTheEnd() throws
    {
        let mark = annotation("First source.", line: 3)
        let output = try InlineAnnotationExporter.render(
            source: source,
            notes: notes(source, annotations: [mark], text: "My note")
        )
        let start = try #require(output.range(of: "<!-- monomark:inline:"))
        let next = try #require(output.range(of: "## Next"))
        #expect(start.lowerBound < next.lowerBound)
        #expect(output.contains("**Comment:**\n\nA comment"))
        #expect(output.contains("**Highlighted text:**\n\n> First source\\."))
        #expect(output.range(of: "My note")!.lowerBound > next.lowerBound)
        #expect(try GeneratedReadingSections.clean(output).text == source)
    }

    @Test func tableAnnotationsNeverSplitRows() throws
    {
        let source = "# Table\n\n| A | B |\n| --- | --- |\n| X | Y |\n\nTail.\n"
        let mark = annotation("X", line: 3, endLine: 5)
        let output = try InlineAnnotationExporter.render(source: source, notes: notes(source, annotations: [mark]))
        #expect(output.hasPrefix("# Table\n\n| A | B |\n| --- | --- |\n| X | Y |\n<!-- monomark:inline:"))
    }

    @Test(arguments: ["Text without final newline", "# CRLF\r\n\r\nA paragraph.\r\n"])
    func removesOnlyGeneratedBytes(_ source: String) throws
    {
        let mark = annotation("Text", line: 1)
        let output = try InlineAnnotationExporter.render(
            source: source,
            notes: notes(source, annotations: [mark], text: "Notes")
        )
        #expect(try GeneratedReadingSections.clean(output).text == source)
        if source.contains("\r\n")
        {
            #expect(!output.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
        }
    }

    @Test func repeatExportReplacesGeneratedBlocksAndTranslatesLaterReferences() throws
    {
        let firstMark = annotation("First source.", line: 3)
        var secondMark = annotation("Second source.", line: 7)
        let first = try InlineAnnotationExporter.render(
            source: source,
            notes: notes(source, annotations: [firstMark, secondMark])
        )
        let currentLine = try #require(first.components(separatedBy: "\n").firstIndex(of: "Second source.")) + 1
        secondMark.anchors[0].location = SourceLocation(line: currentLine, endLine: currentLine, section: "Document")
        let second = try InlineAnnotationExporter.render(
            source: first,
            notes: notes(first, annotations: [firstMark, secondMark])
        )
        #expect(second == first)
        #expect(second.contains("**Source lines:** \(currentLine)"))
    }

    @Test func missingAndOutOfRangeLocationsRefuseInlineExport() throws
    {
        var mark = annotation("First source.", line: 3)
        mark.anchors[0].location = nil
        #expect(throws: AnnotationFailure.unresolvedLocations)
        { try InlineAnnotationExporter.render(source: source, notes: notes(source, annotations: [mark])) }
        mark.anchors[0].location = SourceLocation(line: 999, endLine: 999, section: "Document")
        #expect(throws: AnnotationFailure.unresolvedLocations)
        { try InlineAnnotationExporter.render(source: source, notes: notes(source, annotations: [mark])) }
    }

    @Test func markerTextInCodeRemainsLiteralAndMalformedMarkersRefuseExport() throws
    {
        let marker = "<!-- monomark:inline:notes:start -->"
        let literal = "```html\n" + marker + "\n```\n"
        #expect(try GeneratedReadingSections.clean(literal).text == literal)
        #expect(throws: AnnotationFailure.invalidMarkers) { try GeneratedReadingSections.clean(marker) }
        #expect(throws: AnnotationFailure.invalidMarkers) { try GeneratedReadingSections.clean("```\n") }
    }

    @Test func readingDataOnlyAndNotesOnlyDoNotIncludeTheDocument() throws
    {
        let options = ReadingExportOptions(
            includeAnnotations: false,
            includeNotes: true,
            layout: .endSection,
            dataOnly: true
        )
        let result = try options.render(
            source: source,
            notes: notes(source, annotations: [annotation("First", line: 3)], text: "My note")
        )
        #expect(result.contains("My note"))
        #expect(!result.contains("First source"))
        #expect(!result.contains("### Annotation"))
        #expect(!result.contains("## Next"))
    }
}
