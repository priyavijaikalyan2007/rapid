// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 79bb76e4-b02e-439d-ae97-4373ed0801f0
// COMPONENT: Reader appearance persistence
// PURPOSE: Apply bounded appearance values and save explicit defaults.
import Foundation
#if os(macOS)
import AppKit
#endif

extension ReaderSession
{
    var paperLayout: PaperLayout
    {
        #if os(macOS)
        let size = NSPrintInfo.shared.paperSize
        return PaperLayout.resolve(preferences.paperSize, systemWidth: size.width, systemHeight: size.height)
        #else
        let letter = ["US", "CA"].contains(Locale.current.region?.identifier ?? "")
        return PaperLayout.resolve(
            preferences.paperSize,
            systemWidth: letter ? 612 : 595.27559,
            systemHeight: letter ? 792 : 841.88976
        )
        #endif
    }

    func rendererPreferences() -> [String: Any]
    {
        var value = dictionary(preferences)
        value["palettes"] = [
            "light": preferences.palette.resolve(dark: false),
            "dark": preferences.palette.resolve(dark: true)
        ]
        let paper = paperLayout
        value["paperWidth"] = paper.widthPoints * 4 / 3
        value["paperHeight"] = paper.heightPoints * 4 / 3
        value["paperMargin"] = paper.marginPoints * 4 / 3
        return value
    }

    func updatePreferences()
    {
        preferences.normalize()
        command(["type": "preferences", "value": rendererPreferences()])
        checkpoint()
    }

    func setLayout(_ mode: String)
    {
        preferences.layoutMode = mode
        updatePreferences()
    }

    func saveDefaults()
    {
        preferences.normalize()
        if let data = try? JSONEncoder()
            .encode(preferences)
        {
            UserDefaults.standard.set(data, forKey: "reader-defaults")
        }
    }
}
