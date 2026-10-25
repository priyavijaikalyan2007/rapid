// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1950ce09-603e-4f24-867f-f0132f940ea4
// Created: 2026
// COMPONENT: Native importance labels
// PURPOSE: Present the bounded profile scale without displaying a numerical score.
// RELATES: ProfileFields, FocusImportance
// FLOW: Typed importance -> readable picker label.

import ComposureCore

extension FocusImportance
{
    var label: String
    {
        switch self
        {
        case .notRelevant: return "Not relevant"
        case .sometimes: return "Sometimes"
        case .important: return "Important"
        case .majorFocus: return "Major focus"
        }
    }
}
