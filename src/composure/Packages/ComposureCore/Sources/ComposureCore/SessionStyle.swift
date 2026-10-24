// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 90e3040a-572b-4130-b452-a87e491c3ae1
// Created: 2026
// COMPONENT: Session style vocabulary
// PURPOSE: Represent explicit user-selected conversation styles.
// RELATES: AppPreferences
// FLOW: User choice -> default style -> future session setup.

/// Never infer these styles from participant identity, voices, or titles.
public enum SessionStyle: String, Codable, CaseIterable, Sendable
{
    case normal = "Normal"
    case highStakes = "High stakes / executive"
    case difficultConversation = "Difficult conversation"
}
