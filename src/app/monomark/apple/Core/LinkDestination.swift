// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: dbd0c4fb-e398-460c-98e6-e4fcdaa3853a
// Created: 2026
// COMPONENT: MonoMark core
// PURPOSE: Represent destination policy without executing navigation.
// RELATES: MonoMarkCoreTests
// FLOW: Validated input -> local processing -> typed result.

import Foundation

/// Validated destination decisions shared by native navigation and preview actions.
enum LinkDestination: Equatable, Sendable
{
    case fragment(String)
    case document(URL, String?)
    case external(URL)
    case file(URL)
    case denied
}
