// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b86a3d97-3372-49d7-b437-a1a11ec7e1d2
// COMPONENT: Native installed-font catalog
// PURPOSE: Read font families from the operating system rather than a fixed list.
#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
enum InstalledFonts
{
    static let families: [String] = {
        #if os(macOS)
        NSFontManager.shared.availableFontFamilies
        #else
        UIFont.familyNames
        #endif
    }()
}
