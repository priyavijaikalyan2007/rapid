// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2f056cb4-6b84-49d9-80a5-a3c73a1cecc
// COMPONENT: Annotation inspector navigation tests
// PURPOSE: Verify expansion, filtering, selection, and UTF-16 note search.
import Foundation
import Testing
@testable import MonoMarkCore

@MainActor
struct AnnotationNavigationTests
{
    func model() async -> AnnotationController
    {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("notes.sqlite")
        let model = AnnotationController(databaseURL: url)
        model.open(document: "one", path: "/book.md")
        await model.waitForLoad()
        return model
    }

    @Test func newAnnotationsExpandAfterCollapseAll() async throws
    {
        let model = await model()
        model.selection = [TextAnchor(blockID: "b", quote: "First", prefix: "", suffix: "", start: 0)]
        model.addSelection()
        let first = try #require(model.records.first)
        model.collapseAll()
        #expect(!model.isExpanded(first.id))
        model.selection = [TextAnchor(blockID: "c", quote: "Second", prefix: "", suffix: "", start: 0)]
        model.addSelection()
        #expect(model.isExpanded(try #require(model.records.last).id))
        #expect(!model.isExpanded(first.id))
        model.expandAll()
        #expect(model.isExpanded(first.id))
        #expect(await model.drain())
    }

    @Test func searchFindsCommentsAndSelectionRevealsFilteredAnnotations() async throws
    {
        let model = await model()
        let annotation = ReadingAnnotation(
            anchors: [TextAnchor(blockID: "b", quote: "A quotation", prefix: "", suffix: "", start: 0)],
            comment: "Résumé"
        )
        model.update(annotation)
        model.annotationQuery = "resume"
        #expect(model.filteredRecords.count == 1)
        model.annotationQuery = "missing"
        #expect(model.filteredRecords.isEmpty)
        model.collapseAll()
        model.inspectorTab = "Notes"
        model.selectAnnotation(annotation.id)
        #expect(model.annotationQuery.isEmpty)
        #expect(model.isExpanded(annotation.id))
        #expect(model.inspectorTab == "Annotations")
        #expect(await model.drain())
    }

    @Test func noteSearchSelectsUnicodeRangesAndWraps() async throws
    {
        let model = await model()
        model.editNotes("😀 Café café")
        model.noteQuery = "cafe"
        #expect(model.noteMatches == [NSRange(location: 3, length: 4), NSRange(location: 8, length: 4)])
        model.findNote(1)
        #expect(model.noteSelection == NSRange(location: 8, length: 4))
        model.findNote(1)
        #expect(model.noteSelection == NSRange(location: 3, length: 4))
        model.noteQuery = "absent"
        #expect(model.noteMatches.isEmpty)
        #expect(await model.drain())
    }

    @Test func previousMatchAfterEditingStartsAtLastResult() async throws
    {
        let model = await model()
        model.editNotes("one one")
        model.noteQuery = "one"
        model.editNotes("one one one")
        model.findNote(-1)
        #expect(model.noteSelection == NSRange(location: 8, length: 3))
        #expect(await model.drain())
    }
}
