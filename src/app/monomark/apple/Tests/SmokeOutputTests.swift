// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 5939f130-868e-48b6-8287-13b24c0e2920
// COMPONENT: Sandboxed native acceptance output
// PURPOSE: Route test artifacts to writable app-owned storage when reports use standard output.
import Foundation
import Testing
@testable import MonoMarkCore

struct SmokeOutputTests
{
    @Test func stdoutReportsKeepArtifactsInTheProcessTemporaryDirectory() throws
    {
        let path = SmokeOutput.resolve("-")
        let file = URL(fileURLWithPath: path)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("Synthetic report".utf8).write(to: file)
        #expect(try Data(contentsOf: file) == Data("Synthetic report".utf8))
        #expect(file.deletingLastPathComponent().standardizedFileURL == FileManager.default.temporaryDirectory
            .standardizedFileURL)
    }

    @Test func explicitOutputPathsRemainUnchanged()
    {
        #expect(SmokeOutput.resolve("/tmp/MonoMark QA/report.json") == "/tmp/MonoMark QA/report.json")
    }
}
