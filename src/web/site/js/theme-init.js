// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4229c8a8-7ecc-4373-80a6-a58e4993ec8d
// Created: 2026
// COMPONENT: theme-init
// PURPOSE: Apply the locally stored or operating-system theme before display.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

/**
 * Apply the saved or operating-system theme before styles render.
 * The preference stays in this browser and is never transmitted.
 */

(function initializeTheme()
{
    "use strict";

    const mode = readThemePreference();

    const useDarkTheme =
        mode === "dark" || (mode === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches);

    document.documentElement.setAttribute("data-bs-theme", useDarkTheme ? "dark" : "light");
    document.documentElement.setAttribute("data-theme-mode", mode);
})();

/** Read a valid local preference and fall back when browser storage is unavailable. */
function readThemePreference()
{
    const allowedModes = ["light", "auto", "dark"];
    try
    {
        const savedMode = window.localStorage.getItem("outcrop-theme");
        if (allowedModes.indexOf(savedMode) !== -1)
        {
            return savedMode;
        }
    }
    catch
    {
        return "auto";
    }

    return "auto";
}
