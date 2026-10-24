// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: a6d8b1ed-49ef-4e53-83c8-1df8e6726268
// Created: 2026
// COMPONENT: theme-toggle-init
// PURPOSE: Connect native browser storage to the existing theme component.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

/**
 * Initialize the Enterprise Application ThemeToggle component.
 */

document.addEventListener("DOMContentLoaded", function initializeThemeToggle()
{
    "use strict";

    const container = document.getElementById("theme-toggle");
    if (!container || typeof window.createThemeToggle !== "function")
    {
        return;
    }

    const mode = document.documentElement.getAttribute("data-theme-mode") || "auto";

    window.createThemeToggle({
        container: container,
        defaultTheme: mode,
        onChange: function saveThemePreference(theme, selectedMode)
        {
            document.documentElement.setAttribute("data-theme-mode", selectedMode);

            try
            {
                window.localStorage.setItem("outcrop-theme", selectedMode);
            }
            catch
            {
                return;
            }
        },
    });
});
