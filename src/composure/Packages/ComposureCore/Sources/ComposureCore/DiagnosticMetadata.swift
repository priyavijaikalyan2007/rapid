// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: db2909f1-06fc-49e3-9e5b-89cb59184763
// Created: 2026
// COMPONENT: Safe diagnostic metadata
// PURPOSE: Permit bounded counts without accepting arbitrary content strings.
// RELATES: DiagnosticLogger
// FLOW: Operational count -> bounded scalar -> diagnostic sink.

/// A non-sensitive operation count. Never encode conversation content as numeric metadata.
public struct DiagnosticMetadata: Sendable
{
    /// Bounds diagnostic magnitude independently from any processing limits.
    public static let maximumItemCount = 10_000

    /// Count after clamping to the closed range zero through `maximumItemCount`.
    public let itemCount: Int

    /// Bounds negative and excessive counts before any log sink receives them.
    public init(itemCount: Int = 0)
    {
        self.itemCount = min(max(itemCount, 0), Self.maximumItemCount)
    }
}
