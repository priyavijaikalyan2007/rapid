// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: fbd80d45-65df-494b-8a3b-3df9b03e60f1
// Created: 2026
// COMPONENT: Preference editing coordinator
// PURPOSE: Retain drafts and commit onboarding only after the typed store accepts the record.
// RELATES: PreferencesStore, PreferencesState, DiagnosticLogger
// FLOW: Native edit -> retained draft -> explicit save -> accepted state or visible failure.

import Observation

/// One main-actor instance serves the app's windows. Drafts survive navigation, not process termination.
@MainActor
@Observable
public final class PreferencesCoordinator
{
    public private(set) var state: PreferencesState
    public var draft: AppPreferences
    public private(set) var saveError: PreferencesError?
    private let store: any PreferencesStore
    private let logger: DiagnosticLogger

    public init(store: any PreferencesStore, logger: DiagnosticLogger)
    {
        self.store = store
        self.logger = logger
        do
        {
            let preferences = try store.load()
            state = .ready(preferences)
            draft = preferences
            logger.record(.preferencesLoaded)
        }
        catch
        {
            state = .unavailable(error)
            draft = AppPreferences()
            logger.record(.preferencesUnavailable)
        }
    }

    /// Reload is explicit and replaces drafts only after the user requests a retry or reset.
    public func reload()
    {
        do
        {
            let preferences = try store.load()
            state = .ready(preferences)
            draft = preferences
            saveError = nil
            logger.record(.preferencesLoaded)
        }
        catch
        {
            state = .unavailable(error)
            logger.record(.preferencesUnavailable)
        }
    }

    /// Failure retains both the draft and last accepted state. No fallback record is written.
    @discardableResult
    public func saveDraft() -> Bool
    {
        guard case .ready = state
        else
        {
            return false
        }
        return commit(draft)
    }

    /// Publishes only the selected record. Other unsaved draft fields remain untouched.
    private func commit(_ preferences: AppPreferences) -> Bool
    {
        do
        {
            try store.save(preferences)
            state = .ready(preferences)
            saveError = nil
            logger.record(.preferencesSaved)
            return true
        }
        catch
        {
            saveError = error
            logger.record(.preferencesUnavailable)
            return false
        }
    }

    /// Saves the profile and completion flag in the same bounded record.
    @discardableResult
    public func completeOnboarding() -> Bool
    {
        draft.hasCompletedOnboarding = true
        return saveDraft()
    }

    /// Preserves onboarding completion, language, and default session style.
    public func resetProfile()
    {
        guard case .ready(var accepted) = state
        else
        {
            return
        }
        accepted.profile = CoachingProfile()
        draft.profile = accepted.profile
        _ = commit(accepted)
    }

    /// Discards only unsaved edits after an explicit user action.
    public func discardChanges()
    {
        guard case .ready(let preferences) = state
        else
        {
            return
        }
        draft = preferences
        saveError = nil
    }

    /// The recovery UI confirms this action before removing unreadable saved preferences.
    public func resetAllPreferences()
    {
        store.reset()
        logger.record(.preferencesReset)
        reload()
    }
}
