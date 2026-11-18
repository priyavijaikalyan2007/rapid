// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 186460c7-16a4-4cdb-8313-e03c7395a1bb
// COMPONENT: App-owned release screenshots
// PURPOSE: Capture this process's own window through the compositor and encode opaque RGB PNGs.
import AppKit
import ScreenCaptureKit

@MainActor enum ReviewWindowCapture
{
    static func write(_ window: NSWindow, output: String) async throws -> NSBitmapImageRep
    {
        // currentProcess exposes only content available without a general Screen Recording grant.
        let content = try await SCShareableContent.currentProcess
        guard let owned = content.windows.first(where: {
            $0.windowID == window.windowNumber
        }) else
        {
            throw ReaderFailure.unavailable
        }
        let configuration = SCStreamConfiguration()
        configuration.width = 2560
        configuration.height = 1600
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        configuration.scalesToFit = true
        let filter = SCContentFilter(desktopIndependentWindow: owned)
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        let bitmap = try opaque(image, appearance: window.effectiveAppearance)
        guard let png = bitmap.representation(using: .png, properties: [:])
        else
        {
            throw ReaderFailure.unavailable
        }
        try png.write(to: URL(fileURLWithPath: output))
        return bitmap
    }

    private static func opaque(_ image: CGImage, appearance: NSAppearance) throws -> NSBitmapImageRep
    {
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else
        {
            throw ReaderFailure.unavailable
        }
        appearance.performAsCurrentDrawingAppearance
        {
            context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        }
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.fill(bounds)
        context.draw(image, in: bounds)
        guard let result = context.makeImage()
        else
        {
            throw ReaderFailure.unavailable
        }
        return NSBitmapImageRep(cgImage: result)
    }
}
