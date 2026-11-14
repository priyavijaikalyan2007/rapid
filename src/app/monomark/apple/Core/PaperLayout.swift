// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 941cc3e7-f060-4eed-ac77-30f535ea3fe0
// COMPONENT: Physical paper geometry
// PURPOSE: Resolve bounded printer-point dimensions independently of native UI.
import Foundation

struct PaperLayout: Sendable
{
    let widthPoints: Double
    let heightPoints: Double
    let marginPoints = 36.0

    static func resolve(
        _ name: String,
        systemWidth: Double = 595.27559,
        systemHeight: Double = 841.88976
    ) -> PaperLayout
    {
        switch name
        {
        case "letter": return PaperLayout(widthPoints: 612, heightPoints: 792)
        case "legal": return PaperLayout(widthPoints: 612, heightPoints: 1008)
        case "system" where systemWidth.isFinite && systemHeight.isFinite &&
            (144 ... 10000).contains(systemWidth) && (144 ... 10000).contains(systemHeight):
            return PaperLayout(widthPoints: systemWidth, heightPoints: systemHeight)
        default: return PaperLayout(widthPoints: 595.27559, heightPoints: 841.88976)
        }
    }
}
