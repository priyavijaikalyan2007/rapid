// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File bf061ffa-9ad6-4fe0-b93b-7d773faa4f42: bf061ffa-9ad6-4fe0-b93b-7d773faa4f42
// Created: 2026
// COMPONENT: Preview export request
// PURPOSE: Reject unsafe video sizes and protect existing source and destination files.
// RELATES: PreviewNormalizer, PreviewError, PreviewExportRequestTests
// FLOW: CLI arguments -> validated paths and dimensions -> media export.

import Foundation

/// Validates preview export arguments before opening a media asset.
struct PreviewExportRequest
{
    /// Largest supported side, sufficient for the existing App Store preview dimensions.
    private static let maximumDimension = 7_680
    /// Source media remains unchanged throughout export.
    let sourceURL: URL
    /// The destination must not already exist or resolve to the source.
    let outputURL: URL
    /// Pixel width and height, each from one through the supported maximum.
    let size: CGSize

    /// Rejects unsafe dimensions, path aliases, and existing destinations before any output mutation.
    init(_ arguments: [String]) throws
    {
        guard arguments.count == 5, let width = Int(arguments[3]), let height = Int(arguments[4]),
              (1 ... Self.maximumDimension).contains(width), (1 ... Self.maximumDimension).contains(height)
        else
        {
            throw PreviewError.invalidArguments
        }
        sourceURL = URL(fileURLWithPath: arguments[1]).standardizedFileURL.resolvingSymlinksInPath()
        outputURL = URL(fileURLWithPath: arguments[2]).standardizedFileURL.resolvingSymlinksInPath()
        guard sourceURL != outputURL, !FileManager.default.fileExists(atPath: outputURL.path)
        else
        {
            throw PreviewError.existingDestination
        }
        size = CGSize(width: width, height: height)
    }
}
