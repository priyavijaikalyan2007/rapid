// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 1e16a0ef-8c4c-4770-8456-22b915a376f8
// COMPONENT: Clipboard payload boundary tests
// PURPOSE: Permit full-document copy while retaining an explicit UTF-8 memory bound.
import Testing
@testable import MonoMarkCore

struct ClipboardTextTests
{
    @Test func fullDocumentCopyCanExceedTheOldArtifactLimit()
    {
        #expect(ClipboardText.accepts(String(repeating: "x", count: 5 * 1024 * 1024)))
    }

    @Test func unicodeUsesItsByteCount()
    {
        #expect(!ClipboardText.accepts("日本語", byteLimit: 8))
    }

    @Test func exactByteBudgetIsAccepted()
    {
        #expect(ClipboardText.accepts("日本語", byteLimit: 9))
    }

    @Test func negativeBudgetsAreRejected()
    {
        #expect(!ClipboardText.accepts("", byteLimit: -1))
    }
}
