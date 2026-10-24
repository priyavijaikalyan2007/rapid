// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: e8cc3c14-2ba5-4200-be59-be77f4701ae2
// Created: 2026
// COMPONENT: RemoteResource
// PURPOSE: Carries licensed font or frame metadata before validation and cache access.
// RELATES: [[CropPrint]]
// FLOW: Native application -> RemoteResource -> local result.

import Foundation

/// Carries licensed font or frame metadata before validation and cache access.
struct RemoteResource: Codable, Hashable, Identifiable
{
    /// Stable identifier used for selection and validated cache naming.
    let id: String
    /// The name value supplied to this RemoteResource instance.
    let name: String
    /// The supported font or frame resource category.
    let kind: RemoteResourceKind
    /// Required creator attribution shown with the resource license.
    let creator: String
    /// Source location retained for local access or visible attribution.
    let sourceURL: URL
    /// HTTPS resource file address validated before a network request.
    let downloadURL: URL
    /// Accepted SPDX license identifier supplied by the resource catalog.
    let licenseName: String
    /// HTTPS link to the required third-party license terms.
    let licenseURL: URL
    /// Optional resource attribution and usage details.
    let notes: String?
    /// PostScript font name used only by local platform font rendering.
    let fontName: String?
}
