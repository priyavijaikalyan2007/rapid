// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 47ba504c-e224-4d46-b1d0-fa9a14680fa5
// COMPONENT: Reader color contrast
// PURPOSE: Check sRGB relative luminance before applying text colors.
import Foundation

enum PaletteContrast
{
    static func ratio(_ first: String, _ second: String) -> Double
    {
        guard let a = luminance(first), let b = luminance(second)
        else
        {
            return 1
        }
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private static func luminance(_ hex: String) -> Double?
    {
        guard hex.count == 7, hex.first == "#", let rgb = UInt32(hex.dropFirst(), radix: 16)
        else
        {
            return nil
        }
        let channels = [Double((rgb >> 16) & 255), Double((rgb >> 8) & 255), Double(rgb & 255)].map
        {
            let value = $0 / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
    }
}
