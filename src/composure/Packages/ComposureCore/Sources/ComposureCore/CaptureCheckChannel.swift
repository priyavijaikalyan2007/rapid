// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 764867a7-a6d3-4128-a392-1f5aa09ac7e0
// Created: 2026
// COMPONENT: Early capture experiment
// PURPOSE: Keep the developer check bounded and require distinct microphone and meeting streams.
// RELATES: MacCaptureCheck, CaptureCheckMetrics
// FLOW: Separate sample metadata -> bounded validation -> explicit activity or failure.

/// Keeps the two native audio outputs distinct throughout the developer experiment.
public enum CaptureCheckChannel: Sendable
{
    case microphone
    case meeting
}
