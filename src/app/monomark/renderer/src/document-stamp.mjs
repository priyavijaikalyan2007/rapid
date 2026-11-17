// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b8507ba2-b843-4571-b573-2b488330b501
// COMPONENT: Source freshness contract
// PURPOSE: Keep only a SHA-256 stamp after parsing, rather than retaining a second full source copy.

export async function documentStamp(source)
{
    const canonical = source.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').replace(/\0/g, '\uFFFD');
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(canonical));
    return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
}
