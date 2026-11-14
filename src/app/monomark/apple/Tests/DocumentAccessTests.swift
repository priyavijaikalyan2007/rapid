// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c632632c-3355-4360-b3d8-c02a738ea8fc
// Created: 2026
// COMPONENT: Document boundary tests
// PURPOSE: Document boundary tests.
// RELATES: specs/monomark.implementation.md
// FLOW: Input -> validated processing -> result.

import Foundation
import Testing
@testable import MonoMarkCore

/// Validate bounded reads, symlinks, identity, and privacy-safe previews on real files.
struct DocumentAccessTests
{
    func folder() throws -> URL
    {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func rejectsOversizedSource() throws
    {
        let file = try folder().appendingPathComponent("book.md")
        try Data(repeating: 65, count: 200).write(to: file)
        #expect(throws: (any Error).self) { _ = try DocumentAccess.read(file, limit: 100) }
    }

    @Test func renamePreservesIdentity() throws
    {
        let first = try folder().appendingPathComponent("a.md")
        try "# A".write(to: first, atomically: true, encoding: .utf8)
        let identity = try DocumentAccess.identity(first)
        let next = first.deletingLastPathComponent().appendingPathComponent("b.md")
        try FileManager.default.moveItem(at: first, to: next)
        #expect(try DocumentAccess.identity(next) == identity)
    }

    @Test func symlinkCannotEscapeRoot() throws
    {
        let root = try folder()
        let link = root.appendingPathComponent("outside.md")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: URL(fileURLWithPath: "/etc/hosts"))
        #expect(!DocumentAccess.contains(link, in: root))
    }

    @Test func previewSkipsFrontMatterAndBoundsOutput() throws
    {
        let root = try folder()
        let file = root.appendingPathComponent("book.md")
        try "---\nsecret: yes\n---\n# Title\n\nOpening prose."
            .write(to: file, atomically: true, encoding: .utf8)
        #expect(try PreviewLoader.load(file, root: root).contains("Opening prose"))
        #expect(try !PreviewLoader.load(file, root: root).contains("secret"))
    }

    @Test func rejectsInvalidPreferences()
    {
        var preferences = ReaderPreferences()
        preferences.bodySize = .infinity
        preferences.fontFamily = "bad; url(secret)"
        preferences.normalize()
        #expect(preferences.bodySize.isFinite)
        #expect(preferences.fontFamily == "ui-monospace")
    }

    @Test func fontOverridesRejectStyleInjection()
    {
        var preferences = ReaderPreferences()
        preferences.codeFontFamily = "Menlo; background: url(secret)"
        preferences.normalize()
        #expect(preferences.codeFontFamily.isEmpty)
    }

    @Test func preferencesDecodeAnOlderRecord() throws
    {
        let preferences = try JSONDecoder().decode(ReaderPreferences.self, from: Data("{\"bodySize\":19}".utf8))
        #expect(preferences.bodySize == 19)
        #expect(preferences.codeFontFamily.isEmpty)
    }

    @Test func boundsAllTypographyAndPreservesFontNames() throws
    {
        var preferences = ReaderPreferences()
        preferences.headingSizes = [500]
        preferences.codeSize = -100
        preferences.tableSize = 100
        preferences.captionSize = 0
        preferences.lineHeight = 10
        preferences.pageWidth = 0
        preferences.fontFamily = "Menlo"
        preferences.codeFontFamily = "Monaco"
        preferences.normalize()
        let copy = try JSONDecoder().decode(ReaderPreferences.self, from: JSONEncoder().encode(preferences))
        #expect(copy == preferences)
        #expect(copy.headingSizes.count == 6)
        #expect(copy.codeFontFamily == "Monaco")
    }

    @Test func rejectsInvalidUTF8() throws
    {
        let file = try folder().appendingPathComponent("bad.md")
        try Data([0xff, 0xfe, 0xff]).write(to: file)
        #expect(throws: (any Error).self) { _ = try DocumentAccess.read(file) }
    }

    @Test func readsExactlyTheSupportedByteBoundary() throws
    {
        let file = try folder().appendingPathComponent("exact.md")
        try Data(repeating: 65, count: 100).write(to: file)
        #expect(try DocumentAccess.read(file, limit: 100).count == 100)
    }

    @Test func rejectsDirectoryAsDocument() throws
    {
        let directory = try folder()
        #expect(throws: (any Error).self) { _ = try DocumentAccess.read(directory) }
    }

    @Test func previewsDoNotReadAnUnrelatedFolder() throws
    {
        let root = try folder()
        #expect(throws: (any Error).self) { _ = try PreviewLoader.load(URL(fileURLWithPath: "/etc/hosts"), root: root) }
    }

    @Test func previewSkipsCodeAndImageBodies() throws
    {
        let root = try folder()
        let file = root.appendingPathComponent("preview.md")
        try "```swift\nprivate code\n```\n![Image](a.png)\nOpening prose.".write(
            to: file,
            atomically: true,
            encoding: .utf8
        )
        let text = try PreviewLoader.load(file, root: root)
        #expect(text == "Opening prose.")
    }

    @Test(arguments: [ReaderFailure.unavailable, .oversized, .denied, .invalidStore, .invalidEncoding])
    func expectedFailuresGiveRecoveryAdvice(_ failure: ReaderFailure)
    {
        #expect((failure.errorDescription?.count ?? 0) > 30)
    }
}
