// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 1fbc41f7-86c7-4a5f-8c6b-d92f11e3585a
// COMPONENT: Native reading layout commands
// PURPOSE: Route menu choices to the current document's persisted preferences.
import AppKit

extension AppDelegate
{
    @objc func showPages(_ sender: Any?)
    {
        current?.session.setLayout("pages")
    }

    @objc func showPageless(_ sender: Any?)
    {
        current?.session.setLayout("pageless")
    }
}
