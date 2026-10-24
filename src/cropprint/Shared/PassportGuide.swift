// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 87b34418-e260-4314-8cb4-56aed7aa19ac
// Created: 2026
// COMPONENT: PassportGuide
// PURPOSE: Describes the source and normalized head-placement bands for a passport preset.
// RELATES: [[CropPrint]]
// FLOW: Native application -> PassportGuide -> local result.

import Foundation
import SwiftUI

/// Describes the source and normalized head-placement bands for a passport preset.
struct PassportGuide
{
    /// Allowed crown band as fractional crop heights measured from the top.
    let crownBand: ClosedRange<CGFloat>
    /// Allowed chin band as fractional crop heights measured from the top.
    let chinBand: ClosedRange<CGFloat>
    /// Human-readable official measurement guidance for the visual alignment aid.
    let measurement: String
    /// Public authority displayed as the source of the measurement guidance.
    let sourceName: String
    /// HTTPS page for checking the current official photo rules.
    let sourceURL: URL
}
