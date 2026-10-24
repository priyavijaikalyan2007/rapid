// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 31fdad78-2aee-4414-bca1-d75c7e2b3a9b
// Created: 2026
// COMPONENT: DecorationRenderError
// PURPOSE: Reports a recoverable failure to render text or frames.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DecorationRenderError -> local result.

import Foundation

/// Reports a recoverable failure to render text or frames.
enum DecorationRenderError: LocalizedError
{
    /// The native renderer cannot create an output image.
    case renderFailed

    /// Recovery guidance shown to the user or calling tool.
    var errorDescription: String?
    {
        "The app could not render the text or frame. Reset the decoration or choose a smaller image."
    }
}
