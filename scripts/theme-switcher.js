(function() {
  'use strict';

  const STORAGE_KEY = 'theme';
  const THEME_LIGHT = 'light';
  const THEME_DARK = 'dark';

  function getStoredTheme() {
    return localStorage.getItem(STORAGE_KEY);
  }

  function setStoredTheme(theme) {
    localStorage.setItem(STORAGE_KEY, theme);
  }

  function getPreferredTheme() {
    const storedTheme = getStoredTheme();
    if (storedTheme) {
      return storedTheme;
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? THEME_DARK : THEME_LIGHT;
  }

  function setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    updateToggleIcon(theme);
    updateNavbarTheme(theme);
  }

  function updateToggleIcon(theme) {
    const lightIcon = document.getElementById('theme-icon-light');
    const darkIcon = document.getElementById('theme-icon-dark');
    if (lightIcon && darkIcon) {
      if (theme === THEME_DARK) {
        lightIcon.style.display = 'block';
        darkIcon.style.display = 'none';
      } else {
        lightIcon.style.display = 'none';
        darkIcon.style.display = 'block';
      }
    }
  }

  function updateNavbarTheme(theme) {
    const navbar = document.querySelector('.navbar');
    if (navbar) {
      if (theme === THEME_DARK) {
        navbar.classList.remove('navbar-light', 'bg-light');
        navbar.classList.add('navbar-dark', 'bg-dark');
      } else {
        navbar.classList.remove('navbar-dark', 'bg-dark');
        navbar.classList.add('navbar-light', 'bg-light');
      }
    }
  }

  // Apply theme immediately to prevent flash
  setTheme(getPreferredTheme());

  // Listen for system preference changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
    if (!getStoredTheme()) {
      setTheme(e.matches ? THEME_DARK : THEME_LIGHT);
    }
  });

  // Initialize toggle button when DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    const toggle = document.getElementById('theme-toggle');
    if (toggle) {
      toggle.addEventListener('click', function() {
        const currentTheme = document.documentElement.getAttribute('data-bs-theme');
        const newTheme = currentTheme === THEME_DARK ? THEME_LIGHT : THEME_DARK;
        setTheme(newTheme);
        setStoredTheme(newTheme);
      });
    }
    // Ensure icons are correctly set after DOM load
    updateToggleIcon(getPreferredTheme());
  });
})();
