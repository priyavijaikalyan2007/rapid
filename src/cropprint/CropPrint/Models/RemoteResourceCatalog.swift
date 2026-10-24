// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7cbaa95b-cf61-4d6c-bba7-5c2a9739f49b
// Created: 2026
// COMPONENT: RemoteResourceCatalog
// PURPOSE: Carries a versioned collection of licensed resource entries for validation.
// RELATES: [[CropPrint]]
// FLOW: Native application -> RemoteResourceCatalog -> local result.

import Foundation

/// Carries a versioned collection of licensed resource entries for validation.
struct RemoteResourceCatalog: Codable
{
    /// The version value supplied to this RemoteResourceCatalog instance.
    let version: Int
    /// Current validated catalog entries available for explicit download.
    let resources: [RemoteResource]
}
