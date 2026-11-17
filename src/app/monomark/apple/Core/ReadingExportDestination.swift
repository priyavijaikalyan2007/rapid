// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580011
// COMPONENT: Explicit reading-data export
// PURPOSE: Distinguish current-file writes, document copies, and standalone reading data.
enum ReadingExportDestination: String, CaseIterable, Sendable
{
    case currentFile
    case documentCopy
    case readingDataFile
}
