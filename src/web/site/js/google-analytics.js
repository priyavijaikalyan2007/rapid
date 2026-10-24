// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 6d177737-711b-44c4-867a-21e6143a0787
// Created: 2026
// COMPONENT: google-analytics
// PURPOSE: Configure website-only analytics without advertising personalization.
// RELATES: PROJECT.md, instructions/WORKFLOW.md
// FLOW: Authored source -> component validation -> local result.

/**
 * Configure Google Analytics for aggregate website metrics.
 * Applications do not load this file or send analytics data.
 */

window.dataLayer = window.dataLayer || [];

/** Queues website-only analytics calls using the Google tag command format. */
function gtag()
{
    window.dataLayer.push(arguments);
}

const analyticsScript = document.currentScript;
const measurementId = analyticsScript?.dataset.measurementId;

if (measurementId)
{
    gtag("js", new Date());
    gtag("config", measurementId, {
        allow_ad_personalization_signals: false,
        allow_google_signals: false,
    });
}
