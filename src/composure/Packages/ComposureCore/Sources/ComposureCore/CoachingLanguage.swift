// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 00d234c6-4ed9-4467-bcda-89afc726ccce
// Created: 2026
// COMPONENT: Supported coaching language
// PURPOSE: Avoid persisting arbitrary locale strings or advertising unsupported coaching languages.
// RELATES: AppPreferences
// FLOW: Supported language -> preference record -> future speech/model readiness.

/// English is the only language promised by the V1 specification.
public enum CoachingLanguage: String, Codable, Sendable
{
    case english = "English"
}
