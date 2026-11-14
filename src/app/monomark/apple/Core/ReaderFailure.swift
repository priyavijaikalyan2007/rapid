// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 37be43a6-55b6-42c9-afba-2a38a5090989
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Describe recoverable local failures without logging document content.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Expected local failures use actionable, content-free descriptions.
enum ReaderFailure: LocalizedError
{
    case unavailable, oversized, denied, invalidStore, invalidEncoding
    var errorDescription: String?
    {
        switch self
        {
        case .unavailable: "The file is unavailable. Check its location and download status, then open it again."
        case .oversized: "The file exceeds this version's 100 MiB source limit. Open a smaller document."
        case .denied: "This location is outside the opened folder. Open the containing folder to grant access."
        case .invalidStore: "Reading history could not be saved or opened. Check free disk space and folder permissions."
        case .invalidEncoding: "The document is not valid UTF-8 text. Convert it to UTF-8 and open it again."
        }
    }
}
