// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: ca78b404-38e2-45ab-8bbf-e4b561835b45
// Created: 2026
// COMPONENT: Website JavaScript source conventions
// PURPOSE: Enforce the shared brace and indentation rules on authored browser and build code.
// RELATES: package.json, ../../instructions/javascript/JAVASCRIPT.md
// FLOW: Authored JavaScript -> ESLint -> actionable source diagnostics.

import stylistic from "@stylistic/eslint-plugin";

/** Scope checks to authored code and keep generated or installed files outside lint input. */
export default [
    {
        ignores: ["dist/**", "node_modules/**", ".wrangler/**"],
    },
    {
        files: ["**/*.js", "**/*.mjs"],
        plugins: { "@stylistic": stylistic },
        rules: {
            "@stylistic/brace-style": ["error", "allman", { allowSingleLine: false }],
            "@stylistic/indent": ["error", 4, { SwitchCase: 1 }],
            "@stylistic/no-tabs": "error",
            "@stylistic/no-trailing-spaces": "error",
            "@stylistic/max-statements-per-line": ["error", { max: 1 }],
            "no-var": "error",
            "prefer-const": "error",
        },
    },
];
