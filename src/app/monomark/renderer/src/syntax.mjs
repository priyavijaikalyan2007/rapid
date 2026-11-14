// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 2d890691-bac7-4d30-855e-6bc0a12f6bdf
// COMPONENT: Offline code highlighting
// PURPOSE: Normalize language aliases and preserve grammar-specific token categories.
import highlight from 'highlight.js/lib/common';

const aliases = { 'c#': 'csharp', cs: 'csharp', 'c-sharp': 'csharp', '.cs': 'csharp',
    postgresql: 'sql', postgres: 'sql', pgsql: 'sql', tsql: 'sql', 't-sql': 'sql', mssql: 'sql' };

export function highlightSource(source, label)
{
    const requested = String(label || '').toLowerCase();
    const language = aliases[requested] || requested;
    if (source.length > 100000 || !highlight.getLanguage(language))
    {
        return { language: 'text', html: source.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;') };
    }
    return { language, html: highlight.highlight(source, { language, ignoreIllegals: true }).value };
}
