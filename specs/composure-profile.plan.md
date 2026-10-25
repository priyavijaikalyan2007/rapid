<!--
SPDX-FileCopyrightText: 2026 Outcrop Inc
SPDX-License-Identifier: GPL-3.0-or-later
Repository: rapid
File GUID: 8c324bdd-0542-4214-9869-406e3adc0946
Created: 2026
-->

<!-- AGENT: Defines privacy onboarding, typed profile storage, and native preference editing. -->

# Composure profile and onboarding

The owner confirmed that the Mac shell works after the architecture correction.
This slice implements Phase 1 while physical mobile launch checks remain open.
Neither that confirmation nor this implementation completes the release or device gates.

## Behavior

Provide four onboarding steps: introduction, privacy, listening disclosure, and Coaching Profile.
Allow Back without losing choices. Save onboarding completion and the profile together only after Finish succeeds.
Do not request audio permissions, start capture, or invoke a model.

Use eight behavioral focus choices with importance values from zero through three.
Provide an executive-restraint preference, cue frequency, cue detail, and a default session style.
English is the only supported coaching language in V1. Show that limitation rather than offering unsupported choices.
Default focus importance is zero, cue frequency is Normal, cue detail is Very Short, and session style is Normal.

Use a typed, versioned preference record under one app-owned UserDefaults key.
Bound stored input to 16 KiB before decoding. Reject invalid values, corrupt data, and unsupported schema versions.
Preserve unreadable records until the user explicitly resets saved preferences.
Reset only the owned key. A profile reset preserves onboarding completion and unrelated app preferences.
Resetting the profile must not save unrelated draft edits. Those edits remain pending until explicit Save.
No persistence API accepts conversation text or arbitrary Codable values.

Keep a draft in the app coordinator so navigation does not discard unsaved choices.
Save failures preserve both the draft and last accepted preferences. Provide Retry and explicit reset recovery.
Use fixed diagnostic events without profile values or raw error messages.

UserDefaults updates its memory immediately and writes to disk asynchronously.
The implementation does not promise crash-atomic disk durability or prevent operating-system backups of preferences.
Declare app-only UserDefaults access through CA92.1 in the privacy manifest.

## Design

No pattern required - simple function/class suffices for the bounded value types and onboarding navigation.
Use one small persistence protocol because the coordinator needs failure-injection tests and a native storage boundary.
Use the existing diagnostic facade. Use Observation for one main-actor coordinator shared by the native windows.
Keep profile rules, persistence, and save state in ComposureCore. Keep native form layout and navigation in app views.
No third-party dependency or database is needed.

Public contracts:

- CoachingProfile[focus: CoachingFocus] reads or changes a FocusImportance value.
- AppPreferences contains the profile, default session style, fixed supported language, and onboarding completion.
- PreferencesStore.load() throws(PreferencesError) returns typed preferences or an explicit failure.
- PreferencesStore.save(_:) throws(PreferencesError) accepts only AppPreferences.
- PreferencesStore.reset() removes only this feature's owned record.
- PreferencesCoordinator.state describes accepted preferences or an unavailable state.
- PreferencesCoordinator.draft retains unsaved choices across navigation.
- PreferencesCoordinator.saveDraft() returns success and preserves the draft on failure.
- PreferencesCoordinator.completeOnboarding() saves the profile and completion flag together.
- PreferencesCoordinator.resetProfile(), discardChanges(), resetAllPreferences(), and reload() expose explicit actions.

## Files

Create these files under Packages/ComposureCore/Sources/ComposureCore:

- CoachingFocus.swift
- FocusImportance.swift
- CueFrequency.swift
- CueVerbosity.swift
- SessionStyle.swift
- CoachingLanguage.swift
- CoachingProfile.swift
- AppPreferences.swift
- PreferencesError.swift
- PreferencesRecord.swift
- PreferencesStore.swift
- UserDefaultsPreferencesStore.swift
- PreferencesState.swift
- PreferencesCoordinator.swift

Create CoachingProfileTests.swift, PreferencesStoreTests.swift, and PreferencesCoordinatorTests.swift in the package test target.
Update DiagnosticEvent.swift with fixed preference lifecycle events.

Create these files under Apps/Shared:

- AppPreferencesComposition.swift
- PreferencesRootView.swift
- OnboardingStep.swift
- OnboardingView.swift
- ProfileFields.swift
- FocusImportance+Label.swift
- CoachingSettingsView.swift
- PreferencesRecoveryView.swift
- PreferenceSaveStatusView.swift

Update both app entry points, both native root views, AppSection.swift, PrivacyInfo.xcprivacy, and project.pbxproj.
Add Tests/UI/OnboardingUITests.swift and a native mobile UI test target for the onboarding and relaunch journey.
Update the shared Composure Mobile scheme to run that test target.
Keep source membership explicit in both app targets.

Update the component README, PROJECT.md, ADDITIONAL.md, CHANGELOG.md, CONVERSATION.md,
specs/composure.status.md, and the agentknowledge concepts, entities, decisions, and append-only history.
Update the root README and include native UI tests in PROJECT_PROFILE.md through the configurator.

## Verification and checkpoints

Write core behavior and persistence tests first. Observe their failure before adding implementation.
Cover all focus dimensions, profile round trips, enum bounds, corrupt and future records,
onboarding persistence, reset scope, failed-save draft retention, and preservation of unreadable data.
Use synthetic preferences and isolated test domains. Never use real meeting content as test data.

Build both native targets and run relevant tests before each code checkpoint.
Commit and push the verified core, then the native UI integration.
Run the complete repository suite and source-style checks for the completed slice.
Record automated results separately from physical-device, VoiceOver, and interactive checks that remain open.
