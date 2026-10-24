// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: c17eb60e-aac8-4999-90de-d15ca3940ef4
// Created: 2026
// COMPONENT: DisplayCalibration
// PURPOSE: Defines the DisplayCalibration domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> DisplayCalibration -> local result.

import SwiftUI

/// Defines the DisplayCalibration domain values and their contracts.
enum DisplayCalibration
{
    /// Shared points per inch key metadata used by DisplayCalibration.
    static let pointsPerInchKey = "CropPrint.trueSize.pointsPerInch"
    /// Shared completed key metadata used by DisplayCalibration.
    static let completedKey = "CropPrint.trueSize.isCalibrated"

    /// Default points per inch used by DisplayCalibration.
    static var defaultPointsPerInch: Double
    {
        #if os(macOS)
        110
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? 132 : 163
        #endif
    }
}
