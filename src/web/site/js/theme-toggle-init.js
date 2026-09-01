/**
 * Initialize the Enterprise Application ThemeToggle component.
 */

document.addEventListener("DOMContentLoaded", function initializeThemeToggle() {
  "use strict";

  var container = document.getElementById("theme-toggle");
  if (!container || typeof window.createThemeToggle !== "function") {
    return;
  }

  var mode = document.documentElement.getAttribute("data-theme-mode") || "auto";

  window.createThemeToggle({
    container: container,
    defaultTheme: mode,
    onChange: function saveThemePreference(theme, selectedMode) {
      document.documentElement.setAttribute("data-theme-mode", selectedMode);

      try {
        window.localStorage.setItem("outcrop-theme", selectedMode);
      } catch (error) {
        return;
      }
    }
  });
});
