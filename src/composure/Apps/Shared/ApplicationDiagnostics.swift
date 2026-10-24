// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: f76fa56e-bfa9-4240-a648-4d5780c0d7dc
// Created: 2026
// COMPONENT: Native diagnostic composition
// PURPOSE: Configure local unified logging at the application boundary.
// RELATES: DiagnosticLogger
// FLOW: Typed event -> native OSLog identifier and count -> local system diagnostics.

import ComposureCore
import OSLog

/// Owns the production sink. Product code cannot supply arbitrary log messages.
enum ApplicationDiagnostics
{
    /// Uses system-managed logging without a file sink, backend, or analytics dependency.
    static func makeLogger() -> DiagnosticLogger
    {
        let logger = Logger(subsystem: "us.outcrop.apps.composure", category: "lifecycle")
        return DiagnosticLogger
        { event, metadata in
            logger.info("event=\(event.rawValue, privacy: .public) count=\(metadata.itemCount, privacy: .public)")
        }
    }
}
