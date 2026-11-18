// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d6c81731-1739-469f-a7b8-3988fc0b87f1
// COMPONENT: Bounded renderer recovery
// PURPOSE: Stop repeated helper crashes until the user retries or a stable interval passes.
import Foundation

struct RendererRecovery
{
    private static let stableInterval: TimeInterval = 60
    private static let maximumRetries = 2
    private var windowStart: TimeInterval?
    private var retries = 0

    mutating func permitsReload(at timestamp: TimeInterval) -> Bool
    {
        guard timestamp.isFinite
        else
        {
            return false
        }
        let start = windowStart ?? timestamp
        if windowStart == nil || timestamp < start || timestamp - start >= Self.stableInterval
        {
            reset()
            windowStart = timestamp
        }
        guard retries < Self.maximumRetries
        else
        {
            return false
        }
        retries += 1
        return true
    }

    mutating func reset()
    {
        windowStart = nil
        retries = 0
    }
}
