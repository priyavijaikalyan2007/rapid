// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 79bb76e4-b02e-439d-ae97-4373ed0801f0
// COMPONENT: Reader appearance persistence
// PURPOSE: Apply bounded appearance values and save explicit defaults.
import Foundation
import OSLog
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

    /// Workspace paths are transferred only for parsing, rather than on every typography update.
    func rendererReferences() -> [String: Any]
    {
        var value: [String: Any] = [
            "implicitFileLinks": preferences.implicitFileLinks,
            "implicitSectionLinks": preferences.implicitSectionLinks
        ]
        if preferences.implicitFileLinks, let referenceIndex, let url,
           let path = referenceIndex.relativePath(for: url)
        {
            value["linkPaths"] = referenceIndex.paths
            value["documentPath"] = path
        }
        return value
    }

    func updatePreferences()
    {
        preferences.normalize()
        let reparse = appliedFileLinks != preferences.implicitFileLinks ||
            appliedSectionLinks != preferences.implicitSectionLinks
        saveDefaults()
        command(["type": "preferences", "value": rendererPreferences()])
        checkpoint()
        if reparse
        {
            reparseReferences()
        }
    }

    func setLayout(_ mode: String)
    {
        preferences.layoutMode = mode
        updatePreferences()
    }

    func saveDefaults()
    {
        guard let settingsDefaults
        else
        {
            return
        }
        do
        {
            try preferences.store(in: settingsDefaults)
        }
        catch
        {
            Logger(subsystem: "us.outcrop.MonoMark", category: "Settings").error("Reader defaults encoding failed")
            message = "MonoMark could not save reader settings. Try changing the setting again."
        }
    }
}
