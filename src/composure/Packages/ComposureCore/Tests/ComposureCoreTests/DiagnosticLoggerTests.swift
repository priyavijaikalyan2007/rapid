// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e4ac09df-c96a-4eae-8b3e-1cad66d06666
// Created: 2026
// COMPONENT: Diagnostic logging tests
// PURPOSE: Verify approved event forwarding and numeric bounds without content strings.
// RELATES: DiagnosticLogger, DiagnosticMetadata
// FLOW: Typed event -> injected synchronous sink -> recorded observation.

import Synchronization
import Testing
@testable import ComposureCore

/// Keeps logging tests isolated and safe under concurrent test execution.
struct DiagnosticLoggerTests
{
    @Test func loggerForwardsApprovedEvent()
    {
        let received = Mutex<DiagnosticEvent?>(nil)
        let logger = DiagnosticLogger
        { event, _ in
            received.withLock
            {
                $0 = event
            }
        }

        logger.record(.applicationLaunched)

        #expect(received.withLock
        {
            $0
        } == .applicationLaunched)
    }

    @Test func loggerForwardsBoundedMetadata()
    {
        let received = Mutex<Int?>(nil)
        let logger = DiagnosticLogger
        { _, metadata in
            received.withLock
            {
                $0 = metadata.itemCount
            }
        }

        logger.record(.sessionStopped, metadata: DiagnosticMetadata(itemCount: 12))

        #expect(received.withLock
        {
            $0
        } == 12)
    }

    @Test func negativeCountIsBounded()
    {
        #expect(DiagnosticMetadata(itemCount: -1).itemCount == 0)
    }

    @Test func excessiveCountIsBounded()
    {
        #expect(DiagnosticMetadata(itemCount: .max).itemCount == DiagnosticMetadata.maximumItemCount)
    }

    @Test func eventEnumCannotConstructConversationText()
    {
        #expect(DiagnosticEvent(rawValue: "synthetic meeting content") == nil)
    }
}
