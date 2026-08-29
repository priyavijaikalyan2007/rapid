import CoreGraphics
import Foundation

enum PrintOrientation: String, CaseIterable, Identifiable {
    case portrait
    case landscape

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

enum PresetCategory: String, CaseIterable, Identifiable {
    case print = "Print"
    case passport = "Passport and ID"
    case instagram = "Instagram"
    case iPhone = "iPhone wallpaper"
    case macBook = "MacBook wallpaper"
    case monitor = "Monitor wallpaper"

    var id: Self { self }
}

enum CropPreset: String, CaseIterable, Identifiable {
    case fourBySix
    case fiveBySeven
    case eightByTen
    case tenByFourteen
    case elevenByFourteen
    case twelveByEighteen
    case sixteenByTwenty
    case twentyByThirty
    case twentyFourByThirtySix
    case passportIndia
    case passportUS
    case passportCanada
    case passportEurope
    case passportUK
    case passportChina
    case passportJapan
    case passportSouthKorea
    case passportAustralia
    case passportSingaporePrint
    case passportSingaporeDigital
    case passportNewZealandPrint
    case passportNewZealandDigital
    case instagramStory
    case instagramPortrait
    case instagramSquare
    case iPhone14Pro
    case iPhone17Pro
    case iPhone16eHome
    case iPhone16eLock
    case macBookAir13
    case macBookAir15
    case macBookPro13
    case macBookPro14
    case macBookPro16
    case monitorVGA
    case monitorSVGA
    case monitorXGA
    case monitorSXGA
    case monitorUXGA
    case monitorHD
    case monitorFullHD
    case monitorDCI2K
    case monitorQHD
    case monitorWQXGA
    case monitorUltraWideQHD
    case monitorUHD4K
    case monitorDCI4K
    case monitor5K
    case monitor6K
    case monitorUHD8K

    var id: Self { self }

    var category: PresetCategory {
        switch self {
        case .fourBySix, .fiveBySeven, .eightByTen, .tenByFourteen,
             .elevenByFourteen, .twelveByEighteen, .sixteenByTwenty,
             .twentyByThirty, .twentyFourByThirtySix:
            .print
        case .passportIndia, .passportUS, .passportCanada, .passportEurope,
             .passportUK, .passportChina, .passportJapan, .passportSouthKorea,
             .passportAustralia, .passportSingaporePrint, .passportSingaporeDigital,
             .passportNewZealandPrint, .passportNewZealandDigital:
            .passport
        case .instagramStory, .instagramPortrait, .instagramSquare:
            .instagram
        case .iPhone14Pro, .iPhone17Pro, .iPhone16eHome, .iPhone16eLock:
            .iPhone
        case .macBookAir13, .macBookAir15, .macBookPro13, .macBookPro14, .macBookPro16:
            .macBook
        case .monitorVGA, .monitorSVGA, .monitorXGA, .monitorSXGA, .monitorUXGA,
             .monitorHD, .monitorFullHD, .monitorDCI2K, .monitorQHD, .monitorWQXGA,
             .monitorUltraWideQHD, .monitorUHD4K, .monitorDCI4K, .monitor5K,
             .monitor6K, .monitorUHD8K:
            .monitor
        }
    }

    var title: String {
        switch self {
        case .fourBySix: "4x6"
        case .fiveBySeven: "5x7"
        case .eightByTen: "8x10"
        case .tenByFourteen: "10x14"
        case .elevenByFourteen: "11x14"
        case .twelveByEighteen: "12x18"
        case .sixteenByTwenty: "16x20"
        case .twentyByThirty: "20x30"
        case .twentyFourByThirtySix: "24x36"
        case .passportIndia: "India Passport (35x45 mm)"
        case .passportUS: "United States Passport (51x51 mm)"
        case .passportCanada: "Canada Passport (50x70 mm)"
        case .passportEurope: "Europe Common / Schengen (35x45 mm)"
        case .passportUK: "United Kingdom Passport (35x45 mm)"
        case .passportChina: "China Passport (33x48 mm)"
        case .passportJapan: "Japan Passport (35x45 mm)"
        case .passportSouthKorea: "South Korea Passport (35x45 mm)"
        case .passportAustralia: "Australia Passport (35x45 mm minimum)"
        case .passportSingaporePrint: "Singapore Passport Print (35x45 mm)"
        case .passportSingaporeDigital: "Singapore Digital Passport (400x514)"
        case .passportNewZealandPrint: "New Zealand Passport Print (35x45 mm)"
        case .passportNewZealandDigital: "New Zealand Digital Passport (900x1200 minimum)"
        case .instagramStory: "Instagram Story (9:16)"
        case .instagramPortrait: "Instagram Portrait (4:5)"
        case .instagramSquare: "Instagram Square (1:1)"
        case .iPhone14Pro: "iPhone 14 Pro (1179x2556)"
        case .iPhone17Pro: "iPhone 17 Pro (1206x2622)"
        case .iPhone16eHome: "iPhone 16e Home Screen (1170x2532)"
        case .iPhone16eLock: "iPhone 16e Lock Screen (1170x2532)"
        case .macBookAir13: "MacBook Air 13-inch (2560x1664)"
        case .macBookAir15: "MacBook Air 15-inch (2880x1864)"
        case .macBookPro13: "MacBook Pro 13-inch (2560x1600)"
        case .macBookPro14: "MacBook Pro 14-inch (3024x1964)"
        case .macBookPro16: "MacBook Pro 16-inch (3456x2234)"
        case .monitorVGA: "VGA (640x480)"
        case .monitorSVGA: "SVGA (800x600)"
        case .monitorXGA: "XGA (1024x768)"
        case .monitorSXGA: "SXGA (1280x1024)"
        case .monitorUXGA: "UXGA (1600x1200)"
        case .monitorHD: "HD 720p (1280x720)"
        case .monitorFullHD: "Full HD 1080p (1920x1080)"
        case .monitorDCI2K: "DCI 2K (2048x1080)"
        case .monitorQHD: "QHD / Common 2K (2560x1440)"
        case .monitorWQXGA: "WQXGA (2560x1600)"
        case .monitorUltraWideQHD: "Ultrawide QHD (3440x1440)"
        case .monitorUHD4K: "4K UHD (3840x2160)"
        case .monitorDCI4K: "DCI 4K (4096x2160)"
        case .monitor5K: "5K (5120x2880)"
        case .monitor6K: "6K (6016x3384)"
        case .monitorUHD8K: "8K UHD (7680x4320)"
        }
    }

    var fileLabel: String {
        switch self {
        case .fourBySix: "4x6"
        case .fiveBySeven: "5x7"
        case .eightByTen: "8x10"
        case .tenByFourteen: "10x14"
        case .elevenByFourteen: "11x14"
        case .twelveByEighteen: "12x18"
        case .sixteenByTwenty: "16x20"
        case .twentyByThirty: "20x30"
        case .twentyFourByThirtySix: "24x36"
        case .passportIndia: "passport-india-35x45mm"
        case .passportUS: "passport-us-51x51mm"
        case .passportCanada: "passport-canada-50x70mm"
        case .passportEurope: "passport-europe-35x45mm"
        case .passportUK: "passport-uk-35x45mm"
        case .passportChina: "passport-china-33x48mm"
        case .passportJapan: "passport-japan-35x45mm"
        case .passportSouthKorea: "passport-south-korea-35x45mm"
        case .passportAustralia: "passport-australia-35x45mm"
        case .passportSingaporePrint: "passport-singapore-35x45mm"
        case .passportSingaporeDigital: "passport-singapore-400x514"
        case .passportNewZealandPrint: "passport-new-zealand-35x45mm"
        case .passportNewZealandDigital: "passport-new-zealand-900x1200"
        case .instagramStory: "instagram-story"
        case .instagramPortrait: "instagram-portrait"
        case .instagramSquare: "instagram-square"
        case .iPhone14Pro: "iphone-14-pro"
        case .iPhone17Pro: "iphone-17-pro"
        case .iPhone16eHome: "iphone-16e-home"
        case .iPhone16eLock: "iphone-16e-lock"
        case .macBookAir13: "macbook-air-13"
        case .macBookAir15: "macbook-air-15"
        case .macBookPro13: "macbook-pro-13"
        case .macBookPro14: "macbook-pro-14"
        case .macBookPro16: "macbook-pro-16"
        case .monitorVGA: "monitor-vga-640x480"
        case .monitorSVGA: "monitor-svga-800x600"
        case .monitorXGA: "monitor-xga-1024x768"
        case .monitorSXGA: "monitor-sxga-1280x1024"
        case .monitorUXGA: "monitor-uxga-1600x1200"
        case .monitorHD: "monitor-hd-1280x720"
        case .monitorFullHD: "monitor-full-hd-1920x1080"
        case .monitorDCI2K: "monitor-dci-2k-2048x1080"
        case .monitorQHD: "monitor-qhd-2560x1440"
        case .monitorWQXGA: "monitor-wqxga-2560x1600"
        case .monitorUltraWideQHD: "monitor-ultrawide-qhd-3440x1440"
        case .monitorUHD4K: "monitor-4k-uhd-3840x2160"
        case .monitorDCI4K: "monitor-dci-4k-4096x2160"
        case .monitor5K: "monitor-5k-5120x2880"
        case .monitor6K: "monitor-6k-6016x3384"
        case .monitorUHD8K: "monitor-8k-uhd-7680x4320"
        }
    }

    var physicalInches: CGSize? {
        switch self {
        case .fourBySix: CGSize(width: 4, height: 6)
        case .fiveBySeven: CGSize(width: 5, height: 7)
        case .eightByTen: CGSize(width: 8, height: 10)
        case .tenByFourteen: CGSize(width: 10, height: 14)
        case .elevenByFourteen: CGSize(width: 11, height: 14)
        case .twelveByEighteen: CGSize(width: 12, height: 18)
        case .sixteenByTwenty: CGSize(width: 16, height: 20)
        case .twentyByThirty: CGSize(width: 20, height: 30)
        case .twentyFourByThirtySix: CGSize(width: 24, height: 36)
        case .passportIndia, .passportEurope, .passportUK, .passportJapan,
             .passportSouthKorea, .passportAustralia, .passportSingaporePrint,
             .passportNewZealandPrint:
            CGSize(width: 35 / 25.4, height: 45 / 25.4)
        case .passportUS:
            CGSize(width: 51 / 25.4, height: 51 / 25.4)
        case .passportCanada:
            CGSize(width: 50 / 25.4, height: 70 / 25.4)
        case .passportChina:
            CGSize(width: 33 / 25.4, height: 48 / 25.4)
        default: nil
        }
    }

    /// Pixel sizes use the natural orientation for each digital destination.
    var targetPixels: CGSize? {
        switch self {
        case .instagramStory: CGSize(width: 1080, height: 1920)
        case .instagramPortrait: CGSize(width: 1080, height: 1350)
        case .instagramSquare: CGSize(width: 1080, height: 1080)
        case .iPhone14Pro: CGSize(width: 1179, height: 2556)
        case .iPhone17Pro: CGSize(width: 1206, height: 2622)
        case .iPhone16eHome, .iPhone16eLock: CGSize(width: 1170, height: 2532)
        case .macBookAir13: CGSize(width: 2560, height: 1664)
        case .macBookAir15: CGSize(width: 2880, height: 1864)
        case .macBookPro13: CGSize(width: 2560, height: 1600)
        case .macBookPro14: CGSize(width: 3024, height: 1964)
        case .macBookPro16: CGSize(width: 3456, height: 2234)
        case .passportSingaporeDigital: CGSize(width: 400, height: 514)
        case .passportNewZealandDigital: CGSize(width: 900, height: 1200)
        case .monitorVGA: CGSize(width: 640, height: 480)
        case .monitorSVGA: CGSize(width: 800, height: 600)
        case .monitorXGA: CGSize(width: 1024, height: 768)
        case .monitorSXGA: CGSize(width: 1280, height: 1024)
        case .monitorUXGA: CGSize(width: 1600, height: 1200)
        case .monitorHD: CGSize(width: 1280, height: 720)
        case .monitorFullHD: CGSize(width: 1920, height: 1080)
        case .monitorDCI2K: CGSize(width: 2048, height: 1080)
        case .monitorQHD: CGSize(width: 2560, height: 1440)
        case .monitorWQXGA: CGSize(width: 2560, height: 1600)
        case .monitorUltraWideQHD: CGSize(width: 3440, height: 1440)
        case .monitorUHD4K: CGSize(width: 3840, height: 2160)
        case .monitorDCI4K: CGSize(width: 4096, height: 2160)
        case .monitor5K: CGSize(width: 5120, height: 2880)
        case .monitor6K: CGSize(width: 6016, height: 3384)
        case .monitorUHD8K: CGSize(width: 7680, height: 4320)
        default: nil
        }
    }

    var supportsOrientation: Bool { category == .print || category == .monitor }

    func dimensions(for orientation: PrintOrientation) -> CGSize {
        let base = physicalInches ?? targetPixels ?? CGSize(width: 1, height: 1)
        switch category {
        case .print:
            return orientation == .portrait ? base : CGSize(width: base.height, height: base.width)
        case .monitor:
            return orientation == .landscape ? base : CGSize(width: base.height, height: base.width)
        default:
            return base
        }
    }

    func aspectRatio(for orientation: PrintOrientation) -> CGFloat {
        let size = dimensions(for: orientation)
        return size.width / size.height
    }
}

enum PaperSize: String, CaseIterable, Identifiable {
    case postcard = "Postcard (4x6)"
    case fiveBySeven = "5x7"
    case eightByTen = "8x10"
    case letter = "Letter"
    case a4 = "A4"
    case tenByFourteen = "10x14"
    case twentyFourByThirtySix = "24x36"

    var id: Self { self }

    var fileLabel: String {
        switch self {
        case .postcard: "postcard"
        case .fiveBySeven: "5x7-paper"
        case .eightByTen: "8x10-paper"
        case .letter: "letter"
        case .a4: "a4"
        case .tenByFourteen: "10x14-paper"
        case .twentyFourByThirtySix: "24x36-paper"
        }
    }

    var inches: CGSize {
        switch self {
        case .postcard: CGSize(width: 4, height: 6)
        case .fiveBySeven: CGSize(width: 5, height: 7)
        case .eightByTen: CGSize(width: 8, height: 10)
        case .letter: CGSize(width: 8.5, height: 11)
        case .a4: CGSize(width: 8.27, height: 11.69)
        case .tenByFourteen: CGSize(width: 10, height: 14)
        case .twentyFourByThirtySix: CGSize(width: 24, height: 36)
        }
    }

    func orientedSize(for orientation: PrintOrientation) -> CGSize {
        orientation == .portrait ? inches : CGSize(width: inches.height, height: inches.width)
    }
}

struct PrintSettings {
    var preset: CropPreset = .fourBySix
    var orientation: PrintOrientation = .portrait
    var paperSize: PaperSize = .postcard
    var includesMargin = false

    var aspectRatio: CGFloat { preset.aspectRatio(for: orientation) }
    var isPrintPreset: Bool { preset.category == .print }
    var isPassportPreset: Bool { preset.category == .passport }
    var outputPixels: CGSize? {
        guard preset.targetPixels != nil else { return nil }
        return preset.dimensions(for: orientation)
    }

    var fileSuffix: String {
        if isPrintPreset {
            let margin = includesMargin ? "margin" : "no-margin"
            return "\(preset.fileLabel)-\(orientation.rawValue)-\(paperSize.fileLabel)-\(margin)"
        }
        if preset.supportsOrientation {
            return "\(preset.fileLabel)-\(orientation.rawValue)"
        }
        return preset.fileLabel
    }

    var fitsPaper: Bool {
        guard let physicalSize = preset.physicalInches else { return true }
        let photo = orientation == .portrait
            ? physicalSize
            : CGSize(width: physicalSize.height, height: physicalSize.width)
        let paper = paperSize.orientedSize(for: orientation)
        return photo.width <= paper.width && photo.height <= paper.height
    }
}
