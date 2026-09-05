import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2 else {
    exit(2)
}

let ownerName = CommandLine.arguments[1]
let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

for window in windows {
    guard window[kCGWindowOwnerName as String] as? String == ownerName,
          window[kCGWindowLayer as String] as? Int == 0,
          let number = window[kCGWindowNumber as String] as? Int,
          let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
          let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary),
          bounds.width >= 1000 else {
        continue
    }

    print(
        "\(number) \(Int(bounds.minX)) \(Int(bounds.minY)) "
            + "\(Int(bounds.width)) \(Int(bounds.height))"
    )
    exit(0)
}

exit(1)
