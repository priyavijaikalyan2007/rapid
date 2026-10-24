// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: b160f1e2-a366-4f22-b45d-5ce376e077c2
// Created: 2026
// COMPONENT: Content-safe diagnostic facade
// PURPOSE: Keep transcript, cue, and preparation strings outside the logging interface.
// RELATES: DiagnosticEvent, DiagnosticMetadata, ApplicationDiagnostics
// FLOW: Approved event and numeric metadata -> injected native sink.

/// Accepts fixed identifiers and bounded counts. The application owns sink configuration.
public struct DiagnosticLogger: Sendable
{
    private let sink: @Sendable (DiagnosticEvent, DiagnosticMetadata) -> Void

    /// Injects a synchronous sink. Production applications use native unified logging.
    public init(sink: @escaping @Sendable (DiagnosticEvent, DiagnosticMetadata) -> Void)
    {
        self.sink = sink
    }

    // @entrypoint
    /// Records an approved event without an arbitrary message or exception parameter.
    public func record(_ event: DiagnosticEvent, metadata: DiagnosticMetadata = DiagnosticMetadata())
    {
        sink(event, metadata)
    }
}
