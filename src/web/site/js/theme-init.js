/**
 * Apply the saved or operating-system theme before styles render.
 * The preference stays in this browser and is never transmitted.
 */

(function initializeTheme() {
  "use strict";

  var allowedModes = ["light", "auto", "dark"];
  var mode = "auto";

  try {
    var savedMode = window.localStorage.getItem("outcrop-theme");
    if (allowedModes.indexOf(savedMode) !== -1) {
      mode = savedMode;
    }
  } catch (error) {
    mode = "auto";
  }

  var useDarkTheme = mode === "dark" || (
    mode === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches
  );

  document.documentElement.setAttribute("data-bs-theme", useDarkTheme ? "dark" : "light");
  document.documentElement.setAttribute("data-theme-mode", mode);
}());
