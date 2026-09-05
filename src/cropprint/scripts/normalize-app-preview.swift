import AVFoundation
import CoreImage
import Foundation

enum PreviewError: Error {
    case invalidArguments
    case missingVideoTrack
    case cannotCreateExporter
}

@main
struct PreviewNormalizer {
    static func main() async throws {
        guard CommandLine.arguments.count == 5,
              let width = Int(CommandLine.arguments[3]),
              let height = Int(CommandLine.arguments[4]),
              width > 0,
              height > 0 else {
            throw PreviewError.invalidArguments
        }

        let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let asset = AVURLAsset(url: sourceURL)
        guard try await asset.loadTracks(withMediaType: .video).first != nil else {
            throw PreviewError.missingVideoTrack
        }

        let targetRect = CGRect(x: 0, y: 0, width: width, height: height)
        let composition = AVMutableVideoComposition(
            asset: asset,
            applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage
                let sourceSize = source.extent.size
                let scale = max(
                    targetRect.width / sourceSize.width,
                    targetRect.height / sourceSize.height
                )
                let scaled = source.transformed(
                    by: CGAffineTransform(scaleX: scale, y: scale)
                )
                let translated = scaled.transformed(
                    by: CGAffineTransform(
                        translationX: (targetRect.width - scaled.extent.width) / 2 - scaled.extent.minX,
                        y: (targetRect.height - scaled.extent.height) / 2 - scaled.extent.minY
                    )
                )
                request.finish(with: translated.cropped(to: targetRect), context: nil)
            }
        )
        composition.renderSize = targetRect.size
        composition.frameDuration = CMTime(value: 1, timescale: 30)

        guard let exporter = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw PreviewError.cannotCreateExporter
        }
        exporter.videoComposition = composition
        exporter.shouldOptimizeForNetworkUse = true

        try? FileManager.default.removeItem(at: outputURL)
        try await exporter.export(to: outputURL, as: .mp4)
    }
}
