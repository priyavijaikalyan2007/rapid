// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e61a7351-2bb3-4fa2-bbe0-adc7ae77b1ab
// COMPONENT: Adaptive palette swatches
// PURPOSE: Provide bounded text colors and quiet surface colors for each appearance.
import Foundation

enum PaletteSwatch: String, CaseIterable, Sendable
{
    case neutral, gray, blue, teal, green, purple, orange, red

    var label: String
    {
        rawValue.capitalized
    }

    func hex(dark: Bool, surface: Bool) -> String
    {
        let values: [String]
        switch self
        {
        case .neutral: values = ["#222226", "#ededf0", "#ffffff", "#1e1e20"]
        case .gray: values = ["#575761", "#b4b4bd", "#f1f2f5", "#29292e"]
        case .blue: values = ["#164b91", "#9ecbff", "#eaf2ff", "#222f44"]
        case .teal: values = ["#00645d", "#8edbd5", "#e7f5f2", "#1d3532"]
        case .green: values = ["#2f6126", "#a9d899", "#edf5e9", "#283525"]
        case .purple: values = ["#654195", "#d7b5ff", "#f2edff", "#342b44"]
        case .orange: values = ["#873c00", "#ffc18a", "#fff0e3", "#3e3026"]
        case .red: values = ["#9c2533", "#ffb4bc", "#ffebee", "#3e282e"]
        }
        return values[(surface ? 2 : 0) + (dark ? 1 : 0)]
    }
}
