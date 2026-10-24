// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5d7367eb-ec6b-42dc-8170-511cbdcba89b
// Created: 2026
// COMPONENT: PreviewNormalizer
// PURPOSE: Exports a new bounded App Store preview without deleting source or existing output media.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PreviewNormalizer -> local result.

import AVFoundation
import CoreImage
import Foundation

/// Exports a new bounded App Store preview without deleting source or existing output media.
@main
struct PreviewNormalizer
{
    /// Reports actionable command failures without a Swift runtime crash or source deletion.
    static func main() async
    {
        do
        {
            try await export(PreviewExportRequest(CommandLine.arguments))
        }
        catch
        {
            let message = "Preview export failed: \(error.localizedDescription)\n"
            try? FileHandle.standardError.write(contentsOf: Data(message.utf8))
            exit(EXIT_FAILURE)
        }
    }

    /// Opens the source only after validation and lets AVFoundation reject a destination created by another process.
    private static func export(_ request: PreviewExportRequest) async throws
    {
        let asset = AVURLAsset(url: request.sourceURL)
        guard try await asset.loadTracks(withMediaType: .video).first != nil
        else
        {
            throw PreviewError.missingVideoTrack
        }
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        else
        {
            throw PreviewError.cannotCreateExporter
        }
        exporter.videoComposition = composition(asset: asset, size: request.size)
        exporter.shouldOptimizeForNetworkUse = true
        try await exporter.export(to: request.outputURL, as: .mp4)
    }

    /// Fits every frame into the requested preview rectangle without changing the source media.
    private static func composition(asset: AVAsset, size: CGSize) -> AVMutableVideoComposition
    {
        let target = CGRect(origin: .zero, size: size)
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler:
            { request in
                request.finish(with: fitted(request.sourceImage, into: target), context: nil)
            }
        )
        composition.renderSize = size
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        return composition
    }

    /// Applies a centered aspect-fill transform before clipping the encoded frame.
    private static func fitted(_ source: CIImage, into target: CGRect) -> CIImage
    {
        let scale = max(target.width / source.extent.width, target.height / source.extent.height)
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let offset = CGAffineTransform(
            translationX: (target.width - scaled.extent.width) / 2 - scaled.extent.minX,
            y: (target.height - scaled.extent.height) / 2 - scaled.extent.minY
        )
        return scaled.transformed(by: offset).cropped(to: target)
    }
}
