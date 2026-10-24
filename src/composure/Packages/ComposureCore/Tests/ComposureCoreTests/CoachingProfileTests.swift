// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 79679ada-b05e-462b-92d2-e0809049cba5
// Created: 2026
// COMPONENT: Coaching profile tests
// PURPOSE: Verify bounded focus choices and a persistence shape without conversation fields.
// RELATES: CoachingProfile, AppPreferences
// FLOW: Typed preference input -> model or decoder -> valid profile or rejected value.

import Foundation
import Testing
@testable import ComposureCore

/// Uses synthetic preferences only. No meeting context belongs in this test model.
struct CoachingProfileTests
{
    @Test(arguments: CoachingFocus.allCases)
    func newProfileDoesNotAssumeFocus(focus: CoachingFocus)
    {
        #expect(CoachingProfile()[focus] == .notRelevant)
    }

    @Test(arguments: CoachingFocus.allCases)
    func focusChoiceIsIndependent(focus: CoachingFocus)
    {
        var profile = CoachingProfile()

        profile[focus] = .majorFocus

        #expect(CoachingFocus.allCases.filter
        {
            profile[$0] == .majorFocus
        } == [focus])
    }

    @Test func profileRoundTripPreservesChoices() throws
    {
        var profile = CoachingProfile()
        profile[.overExplain] = .important
        profile.executiveRestraint = true
        profile.cueFrequency = .low
        profile.cueVerbosity = .short

        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(CoachingProfile.self, from: encoded)

        #expect(decoded == profile)
    }

    @Test(arguments: [-1, 4, 100])
    func importanceRejectsValuesOutsideScale(value: Int)
    {
        #expect(throws: DecodingError.self)
        {
            try JSONDecoder().decode(FocusImportance.self, from: Data("\(value)".utf8))
        }
    }

    @Test func preferencesExposeOnlyAllowedFields() throws
    {
        let encoded = try JSONEncoder().encode(AppPreferences())
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(Set(object.keys) == ["profile", "defaultSessionStyle", "language", "hasCompletedOnboarding"])
    }
}
