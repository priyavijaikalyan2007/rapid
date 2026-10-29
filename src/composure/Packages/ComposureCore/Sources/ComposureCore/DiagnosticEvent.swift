// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 78c1e386-8448-4784-afac-66449dcf156f
// Created: 2026
// COMPONENT: Approved diagnostic events
// PURPOSE: Restrict diagnostic messages to fixed non-content identifiers.
// RELATES: DiagnosticLogger, ApplicationDiagnostics
// FLOW: Application event -> enum case -> local unified log.

/// Closed event vocabulary. Add cases only when a specific diagnostic need exists.
public enum DiagnosticEvent: String, Sendable
{
    case captureCheckStarted = "capture.check.started"
    case captureCheckStopped = "capture.check.stopped"
    case captureCheckFailed = "capture.check.failed"
    case readinessChecked = "readiness.checked"
    case speechSetupStarted = "speech.setup.started"
    case speechSetupCompleted = "speech.setup.completed"
    case speechSetupFailed = "speech.setup.failed"
    case applicationLaunched = "application.launched"
    case sessionStarted = "session.started"
    case sessionStopped = "session.stopped"
    case preferencesLoaded = "preferences.loaded"
    case preferencesSaved = "preferences.saved"
    case preferencesReset = "preferences.reset"
    case preferencesUnavailable = "preferences.unavailable"
    case preparationStarted = "preparation.started"
    case preparationCompleted = "preparation.completed"
    case preparationCanceled = "preparation.canceled"
}
