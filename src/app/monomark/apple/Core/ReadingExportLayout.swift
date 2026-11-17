// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580010
// COMPONENT: Explicit reading-data export
// PURPOSE: Choose annotation placement without changing local autosave.
enum ReadingExportLayout: String, CaseIterable, Sendable
{
    case endSection
    case inline
}
