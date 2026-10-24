// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ad3800d5-d4b4-43ed-bd55-b0777d4fe00e
// Created: 2026
// COMPONENT: CropPreset
// PURPOSE: Defines physical and digital crop dimensions and their native selection labels.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropPreset -> local result.

import CoreGraphics
import Foundation

/// Defines physical and digital crop dimensions and their native selection labels.
enum CropPreset: String, CaseIterable, Identifiable
{
    /// Selects four by six within this type's supported choices.
    case fourBySix
    /// Selects five by seven within this type's supported choices.
    case fiveBySeven
    /// Selects eight by ten within this type's supported choices.
    case eightByTen
    /// Selects ten by fourteen within this type's supported choices.
    case tenByFourteen
    /// Selects eleven by fourteen within this type's supported choices.
    case elevenByFourteen
    /// Selects twelve by eighteen within this type's supported choices.
    case twelveByEighteen
    /// Selects sixteen by twenty within this type's supported choices.
    case sixteenByTwenty
    /// Selects twenty by thirty within this type's supported choices.
    case twentyByThirty
    /// Selects twenty four by thirty six within this type's supported choices.
    case twentyFourByThirtySix
    /// Selects passport india within this type's supported choices.
    case passportIndia
    /// Selects passport us within this type's supported choices.
    case passportUS
    /// Selects passport canada within this type's supported choices.
    case passportCanada
    /// Selects passport europe within this type's supported choices.
    case passportEurope
    /// Selects passport uk within this type's supported choices.
    case passportUK
    /// Selects passport china within this type's supported choices.
    case passportChina
    /// Selects passport japan within this type's supported choices.
    case passportJapan
    /// Selects passport south korea within this type's supported choices.
    case passportSouthKorea
    /// Selects passport australia within this type's supported choices.
    case passportAustralia
    /// Selects passport singapore print within this type's supported choices.
    case passportSingaporePrint
    /// Selects passport singapore digital within this type's supported choices.
    case passportSingaporeDigital
    /// Selects passport new zealand print within this type's supported choices.
    case passportNewZealandPrint
    /// Selects passport new zealand digital within this type's supported choices.
    case passportNewZealandDigital
    /// Selects instagram story within this type's supported choices.
    case instagramStory
    /// Selects instagram portrait within this type's supported choices.
    case instagramPortrait
    /// Selects instagram square within this type's supported choices.
    case instagramSquare
    /// Selects i phone14 pro within this type's supported choices.
    case iPhone14Pro
    /// Selects i phone17 pro within this type's supported choices.
    case iPhone17Pro
    /// Selects i phone16e home within this type's supported choices.
    case iPhone16eHome
    /// Selects i phone16e lock within this type's supported choices.
    case iPhone16eLock
    /// Selects mac book air13 within this type's supported choices.
    case macBookAir13
    /// Selects mac book air15 within this type's supported choices.
    case macBookAir15
    /// Selects mac book pro13 within this type's supported choices.
    case macBookPro13
    /// Selects mac book pro14 within this type's supported choices.
    case macBookPro14
    /// Selects mac book pro16 within this type's supported choices.
    case macBookPro16
    /// Selects monitor vga within this type's supported choices.
    case monitorVGA
    /// Selects monitor svga within this type's supported choices.
    case monitorSVGA
    /// Selects monitor xga within this type's supported choices.
    case monitorXGA
    /// Selects monitor sxga within this type's supported choices.
    case monitorSXGA
    /// Selects monitor uxga within this type's supported choices.
    case monitorUXGA
    /// Selects monitor hd within this type's supported choices.
    case monitorHD
    /// Selects monitor full hd within this type's supported choices.
    case monitorFullHD
    /// Selects monitor dci2 k within this type's supported choices.
    case monitorDCI2K
    /// Selects monitor qhd within this type's supported choices.
    case monitorQHD
    /// Selects monitor wqxga within this type's supported choices.
    case monitorWQXGA
    /// Selects monitor ultra wide qhd within this type's supported choices.
    case monitorUltraWideQHD
    /// Selects monitor uhd4 k within this type's supported choices.
    case monitorUHD4K
    /// Selects monitor dci4 k within this type's supported choices.
    case monitorDCI4K
    /// Selects monitor5 k within this type's supported choices.
    case monitor5K
    /// Selects monitor6 k within this type's supported choices.
    case monitor6K
    /// Selects monitor uhd8 k within this type's supported choices.
    case monitorUHD8K

    /// Identity used by native selection controls.
    var id: Self
    {
        self
    }

    /// Category used by CropPreset.
    var category: PresetCategory
    {
        switch self
        {
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

    /// User-facing label displayed by the native selection controls.
    var title: String
    {
        Self.requiredLabel(Self.titleValues, for: self)
    }

    /// File label used by CropPreset.
    var fileLabel: String
    {
        Self.requiredLabel(Self.fileLabelValues, for: self)
    }

    /// Physical inches used by CropPreset.
    var physicalInches: CGSize?
    {
        switch self
        {
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
    var targetPixels: CGSize?
    {
        Self.targetPixelsValues[self]
    }

    /// Supports orientation used by CropPreset.
    var supportsOrientation: Bool
    {
        category == .print || category == .monitor
    }

    /// Returns physical inches or target pixels after applying the supported orientation.
    func dimensions(for orientation: PrintOrientation) -> CGSize
    {
        let base = physicalInches ?? targetPixels ?? CGSize(width: 1, height: 1)
        switch category
        {
        case .print:
            return orientation == .portrait ? base : CGSize(width: base.height, height: base.width)
        case .monitor:
            return orientation == .landscape ? base : CGSize(width: base.height, height: base.width)
        default:
            return base
        }
    }

    /// Returns width divided by height for the selected orientation.
    func aspectRatio(for orientation: PrintOrientation) -> CGFloat
    {
        let size = dimensions(for: orientation)
        return size.width / size.height
    }

    /// Canonical title metadata for the preset catalog.
    private static let titleValues: [Self: String] = [
        .fourBySix: "4x6",
        .fiveBySeven: "5x7",
        .eightByTen: "8x10",
        .tenByFourteen: "10x14",
        .elevenByFourteen: "11x14",
        .twelveByEighteen: "12x18",
        .sixteenByTwenty: "16x20",
        .twentyByThirty: "20x30",
        .twentyFourByThirtySix: "24x36",
        .passportIndia: "India Passport (35x45 mm)",
        .passportUS: "United States Passport (51x51 mm)",
        .passportCanada: "Canada Passport (50x70 mm)",
        .passportEurope: "Europe Common / Schengen (35x45 mm)",
        .passportUK: "United Kingdom Passport (35x45 mm)",
        .passportChina: "China Passport (33x48 mm)",
        .passportJapan: "Japan Passport (35x45 mm)",
        .passportSouthKorea: "South Korea Passport (35x45 mm)",
        .passportAustralia: "Australia Passport (35x45 mm minimum)",
        .passportSingaporePrint: "Singapore Passport Print (35x45 mm)",
        .passportSingaporeDigital: "Singapore Digital Passport (400x514)",
        .passportNewZealandPrint: "New Zealand Passport Print (35x45 mm)",
        .passportNewZealandDigital: "New Zealand Digital Passport (900x1200 minimum)",
        .instagramStory: "Instagram Story (9:16)",
        .instagramPortrait: "Instagram Portrait (4:5)",
        .instagramSquare: "Instagram Square (1:1)",
        .iPhone14Pro: "iPhone 14 Pro (1179x2556)",
        .iPhone17Pro: "iPhone 17 Pro (1206x2622)",
        .iPhone16eHome: "iPhone 16e Home Screen (1170x2532)",
        .iPhone16eLock: "iPhone 16e Lock Screen (1170x2532)",
        .macBookAir13: "MacBook Air 13-inch (2560x1664)",
        .macBookAir15: "MacBook Air 15-inch (2880x1864)",
        .macBookPro13: "MacBook Pro 13-inch (2560x1600)",
        .macBookPro14: "MacBook Pro 14-inch (3024x1964)",
        .macBookPro16: "MacBook Pro 16-inch (3456x2234)",
        .monitorVGA: "VGA (640x480)",
        .monitorSVGA: "SVGA (800x600)",
        .monitorXGA: "XGA (1024x768)",
        .monitorSXGA: "SXGA (1280x1024)",
        .monitorUXGA: "UXGA (1600x1200)",
        .monitorHD: "HD 720p (1280x720)",
        .monitorFullHD: "Full HD 1080p (1920x1080)",
        .monitorDCI2K: "DCI 2K (2048x1080)",
        .monitorQHD: "QHD / Common 2K (2560x1440)",
        .monitorWQXGA: "WQXGA (2560x1600)",
        .monitorUltraWideQHD: "Ultrawide QHD (3440x1440)",
        .monitorUHD4K: "4K UHD (3840x2160)",
        .monitorDCI4K: "DCI 4K (4096x2160)",
        .monitor5K: "5K (5120x2880)",
        .monitor6K: "6K (6016x3384)",
        .monitorUHD8K: "8K UHD (7680x4320)"
    ]

    /// Canonical fileLabel metadata for the preset catalog.
    private static let fileLabelValues: [Self: String] = [
        .fourBySix: "4x6",
        .fiveBySeven: "5x7",
        .eightByTen: "8x10",
        .tenByFourteen: "10x14",
        .elevenByFourteen: "11x14",
        .twelveByEighteen: "12x18",
        .sixteenByTwenty: "16x20",
        .twentyByThirty: "20x30",
        .twentyFourByThirtySix: "24x36",
        .passportIndia: "passport-india-35x45mm",
        .passportUS: "passport-us-51x51mm",
        .passportCanada: "passport-canada-50x70mm",
        .passportEurope: "passport-europe-35x45mm",
        .passportUK: "passport-uk-35x45mm",
        .passportChina: "passport-china-33x48mm",
        .passportJapan: "passport-japan-35x45mm",
        .passportSouthKorea: "passport-south-korea-35x45mm",
        .passportAustralia: "passport-australia-35x45mm",
        .passportSingaporePrint: "passport-singapore-35x45mm",
        .passportSingaporeDigital: "passport-singapore-400x514",
        .passportNewZealandPrint: "passport-new-zealand-35x45mm",
        .passportNewZealandDigital: "passport-new-zealand-900x1200",
        .instagramStory: "instagram-story",
        .instagramPortrait: "instagram-portrait",
        .instagramSquare: "instagram-square",
        .iPhone14Pro: "iphone-14-pro",
        .iPhone17Pro: "iphone-17-pro",
        .iPhone16eHome: "iphone-16e-home",
        .iPhone16eLock: "iphone-16e-lock",
        .macBookAir13: "macbook-air-13",
        .macBookAir15: "macbook-air-15",
        .macBookPro13: "macbook-pro-13",
        .macBookPro14: "macbook-pro-14",
        .macBookPro16: "macbook-pro-16",
        .monitorVGA: "monitor-vga-640x480",
        .monitorSVGA: "monitor-svga-800x600",
        .monitorXGA: "monitor-xga-1024x768",
        .monitorSXGA: "monitor-sxga-1280x1024",
        .monitorUXGA: "monitor-uxga-1600x1200",
        .monitorHD: "monitor-hd-1280x720",
        .monitorFullHD: "monitor-full-hd-1920x1080",
        .monitorDCI2K: "monitor-dci-2k-2048x1080",
        .monitorQHD: "monitor-qhd-2560x1440",
        .monitorWQXGA: "monitor-wqxga-2560x1600",
        .monitorUltraWideQHD: "monitor-ultrawide-qhd-3440x1440",
        .monitorUHD4K: "monitor-4k-uhd-3840x2160",
        .monitorDCI4K: "monitor-dci-4k-4096x2160",
        .monitor5K: "monitor-5k-5120x2880",
        .monitor6K: "monitor-6k-6016x3384",
        .monitorUHD8K: "monitor-8k-uhd-7680x4320"
    ]

    /// Canonical targetPixels metadata for the preset catalog.
    private static let targetPixelsValues: [Self: CGSize] = [
        .instagramStory: CGSize(width: 1080, height: 1920),
        .instagramPortrait: CGSize(width: 1080, height: 1350),
        .instagramSquare: CGSize(width: 1080, height: 1080),
        .iPhone14Pro: CGSize(width: 1179, height: 2556),
        .iPhone17Pro: CGSize(width: 1206, height: 2622),
        .iPhone16eHome: CGSize(width: 1170, height: 2532),
        .iPhone16eLock: CGSize(width: 1170, height: 2532),
        .macBookAir13: CGSize(width: 2560, height: 1664),
        .macBookAir15: CGSize(width: 2880, height: 1864),
        .macBookPro13: CGSize(width: 2560, height: 1600),
        .macBookPro14: CGSize(width: 3024, height: 1964),
        .macBookPro16: CGSize(width: 3456, height: 2234),
        .passportSingaporeDigital: CGSize(width: 400, height: 514),
        .passportNewZealandDigital: CGSize(width: 900, height: 1200),
        .monitorVGA: CGSize(width: 640, height: 480),
        .monitorSVGA: CGSize(width: 800, height: 600),
        .monitorXGA: CGSize(width: 1024, height: 768),
        .monitorSXGA: CGSize(width: 1280, height: 1024),
        .monitorUXGA: CGSize(width: 1600, height: 1200),
        .monitorHD: CGSize(width: 1280, height: 720),
        .monitorFullHD: CGSize(width: 1920, height: 1080),
        .monitorDCI2K: CGSize(width: 2048, height: 1080),
        .monitorQHD: CGSize(width: 2560, height: 1440),
        .monitorWQXGA: CGSize(width: 2560, height: 1600),
        .monitorUltraWideQHD: CGSize(width: 3440, height: 1440),
        .monitorUHD4K: CGSize(width: 3840, height: 2160),
        .monitorDCI4K: CGSize(width: 4096, height: 2160),
        .monitor5K: CGSize(width: 5120, height: 2880),
        .monitor6K: CGSize(width: 6016, height: 3384),
        .monitorUHD8K: CGSize(width: 7680, height: 4320)
    ]

    /// Treats a missing label as a programmer error rather than publishing an incomplete preset.
    private static func requiredLabel(_ values: [Self: String], for preset: Self) -> String
    {
        guard let label = values[preset]
        else
        {
            preconditionFailure("Every crop preset requires display and filename metadata.")
        }
        return label
    }
}
