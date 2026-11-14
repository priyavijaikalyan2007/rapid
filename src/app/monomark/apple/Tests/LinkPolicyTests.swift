// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5aae4221-6703-4ff7-a978-6b1e36c7228c
// Created: 2026
// COMPONENT: Link permission regression tests
// PURPOSE: Link permission regression tests.
// RELATES: specs/monomark.implementation.md
// FLOW: Input -> validated processing -> result.

import Foundation
import Testing
@testable import MonoMarkCore

/// Destination resolution must never turn a document link into filesystem authority.
struct LinkPolicyTests
{
    let root = URL(fileURLWithPath: "/tmp/books")
    var source: URL
    {
        root.appendingPathComponent("guide.md")
    }

    @Test func resolvesRelativeFragment()
    {
        #expect(LinkPolicy.resolve("next.md#part", relativeTo: source, root: root)
            == .document(root.appendingPathComponent("next.md"), "part"))
    }

    @Test func resolvesCurrentFragment()
    {
        #expect(LinkPolicy.resolve("#part", relativeTo: source, root: root) == .fragment("part"))
    }

    @Test(arguments: ["javascript:alert(1)", "data:text/html,x", "../../secret.md", "%2e%2e/private.md"])
    func deniesUnsafeTarget(_ target: String)
    {
        #expect(LinkPolicy.resolve(target, relativeTo: source, root: root) == .denied)
    }

    @Test func preservesExternalAddress()
    {
        #expect(LinkPolicy.resolve("https://example.com/a#b", relativeTo: source, root: root)
            == .external(URL(string: "https://example.com/a#b")!))
    }

    @Test func rootPrefixCannotGrantSiblingAccess()
    {
        #expect(!DocumentAccess.contains(URL(fileURLWithPath: "/tmp/books-private/a.md"), in: root))
    }

    @Test(arguments: ["", "   ", "x".padding(toLength: 17000, withPad: "x", startingAt: 0)])
    func deniesEmptyOrOversizedTargets(_ target: String)
    {
        #expect(LinkPolicy.resolve(target, relativeTo: source, root: root) == .denied)
    }

    @Test func resolvesNonMarkdownFilesWithoutBrowserNavigation()
    {
        #expect(LinkPolicy
            .resolve("image.png", relativeTo: source, root: root) == .file(root.appendingPathComponent("image.png")))
    }
}
