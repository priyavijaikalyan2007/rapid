import Foundation
import XCTest

final class ExportFileWriterTests: XCTestCase
{
    /// Verifies an existing destination is not overwritten.
    func testAnExistingDestinationIsNotOverwritten() throws
    {
        let directory = try temporaryDirectory()
        let destination = directory.appendingPathComponent("existing.jpg")
        try Data([1]).write(to: destination)
        XCTAssertThrowsError(try ExportFileWriter.write([(Data([2]), destination)]))
        XCTAssertEqual(try Data(contentsOf: destination), Data([1]))
    }

    /// Verifies asecond destination collision rolls back the first file.
    func testASecondDestinationCollisionRollsBackTheFirstFile() throws
    {
        let directory = try temporaryDirectory()
        let first = directory.appendingPathComponent("first.jpg")
        let second = directory.appendingPathComponent("second.pdf")
        try Data([3]).write(to: second)
        XCTAssertThrowsError(try ExportFileWriter.write([(Data([1]), first), (Data([2]), second)]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        XCTAssertEqual(try Data(contentsOf: second), Data([3]))
    }

    /// Verifies successful exports contain all bytes.
    func testSuccessfulExportsContainAllBytes() throws
    {
        let destination = try temporaryDirectory().appendingPathComponent("photo.jpg")
        let data = Data(repeating: 7, count: 100_000)
        try ExportFileWriter.write([(data, destination)])
        XCTAssertEqual(try Data(contentsOf: destination), data)
    }

    /// Verifies failed exports remove their temporary files.
    func testFailedExportsRemoveTheirTemporaryFiles() throws
    {
        let directory = try temporaryDirectory()
        let destination = directory.appendingPathComponent("existing.jpg")
        try Data([1]).write(to: destination)
        _ = try? ExportFileWriter.write([(Data([2]), destination)])
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["existing.jpg"])
    }

    /// Creates an isolated temporary folder for file-publication regression tests.
    private func temporaryDirectory() throws -> URL
    {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        addTeardownBlock
        {
            try FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}
