/**
 * Configure Google Analytics for aggregate website metrics.
 * Applications do not load this file or send analytics data.
 */

window.dataLayer = window.dataLayer || [];

function gtag() {
  window.dataLayer.push(arguments);
}

const analyticsScript = document.currentScript;
const measurementId = analyticsScript?.dataset.measurementId;

if (measurementId) {
  gtag("js", new Date());
  gtag("config", measurementId, {
    allow_ad_personalization_signals: false,
    allow_google_signals: false
  });
}
