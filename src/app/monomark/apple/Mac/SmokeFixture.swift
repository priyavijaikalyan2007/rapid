// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 351a4187-1972-4d35-a0e1-ff5e4d409b8b
// COMPONENT: Native artifact acceptance fixture
// PURPOSE: Generate local, non-private math, image, and diagram inputs for real WebKit checks.
import AppKit

@MainActor enum SmokeFixture
{
    static func create() throws -> URL
    {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("monomark-artifacts-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try image().write(to: folder.appendingPathComponent("sample.png"))
        let file = folder.appendingPathComponent("Artifacts.md")
        try Data(source.utf8).write(to: file)
        try Data("# Replacement document\n\nCopy requests from the previous document must be cancelled.\n".utf8)
            .write(to: folder.appendingPathComponent("Other.md"))
        return file
    }

    private static func image() throws -> Data
    {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 80,
            pixelsHigh: 40,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else
        {
            throw ReaderFailure.unavailable
        }
        let red = NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1)
        let blue = NSColor(deviceRed: 0, green: 0, blue: 1, alpha: 1)
        for x in 0 ..< 80
        {
            for y in 0 ..< 40
            {
                bitmap.setColor(x < 40 ? red : blue, atX: x, y: y)
            }
        }
        guard let data = bitmap.representation(using: .png, properties: [:])
        else
        {
            throw ReaderFailure.unavailable
        }
        return data
    }

    private static let source = """
        # Artifact copy checks

        $$
        \\int_0^1 x^2\\,dx = \\frac{1}{3}
        $$

        ![A red and blue local image](sample.png)

        ```mermaid
        flowchart LR
            A[Local source] --> B[Readable image]
            style A fill:#aa2233,color:#ffffff
        ```
        """
}
