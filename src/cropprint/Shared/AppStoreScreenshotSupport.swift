import Foundation

enum AppStoreScreenshotScenario: String {
    case crop
    case decorate
    case passport
    case printSheet = "print-sheet"
    case trueSize = "true-size"
    case resources
    case preview

    static var current: AppStoreScreenshotScenario? {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let optionIndex = arguments.firstIndex(of: "--app-store-screenshot"),
              arguments.indices.contains(optionIndex + 1) else {
            return nil
        }
        return AppStoreScreenshotScenario(rawValue: arguments[optionIndex + 1])
#else
        return nil
#endif
    }

    static var samplePhotoURL: URL? {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let optionIndex = arguments.firstIndex(of: "--screenshot-photo"),
           arguments.indices.contains(optionIndex + 1) {
            return URL(fileURLWithPath: arguments[optionIndex + 1])
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CropPrint-Screenshot-Sample.png")
#else
        nil
#endif
    }
}
