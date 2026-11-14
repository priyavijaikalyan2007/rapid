// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a7d2804b-09f3-4e00-ae34-e31bf57d4deb
// Created: 2026
// COMPONENT: MonoMark session adapter
// PURPOSE: Isolate Clipboard from document lifecycle and persistence.
// RELATES: ReaderSession.swift
// FLOW: Native action -> validated session operation.

import Foundation
import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension ReaderSession
{
    func copyPNG(_ message: [String: Any])
    {
        lastCopyRequest = message
        guard let webView, let x = message["x"] as? Double, let y = message["y"] as? Double,
              let width = message["width"] as? Double, let height = message["height"] as? Double,
              [x, y, width, height].allSatisfy({
                  $0.isFinite
              }), width > 0, height > 0,
              width * height <= 4_000_000
        else
        {
            return
        }
        let ticket = documentEpoch
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(x: x, y: y, width: width, height: height).intersection(webView.bounds)
        configuration.afterScreenUpdates = true
        Task
        { @MainActor in
            defer { command(["type": "copyComplete"]) }
            do
            {
                let image = try await webView.takeSnapshot(configuration: configuration)
                guard ticket == documentEpoch
                else
                {
                    return
                }
                #if os(macOS)
                guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:])
                else
                {
                    return
                }
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "--smoke-test"), arguments.indices.contains(index + 1)
                {
                    try png.write(to: URL(fileURLWithPath: arguments[index + 1] + ".artifact.png"))
                }
                else
                {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setData(png, forType: .png)
                }
                #else
                if let png = image.pngData()
                {
                    UIPasteboard.general.setData(png, forPasteboardType: "public.png")
                }
                #endif
                self.message = "Copied rendering as PNG."
            }
            catch
            {
                self.message = "The rendering could not be copied. Try a smaller view or copy its source."
            }
        }
    }

    func copy(_ text: String)
    {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}
