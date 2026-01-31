# Bootstrap 5.3 Upgrade and Dark Mode Implementation Summary

**Implementation Date:** 2026-01-31
**Plan Reference:** [bootstrap-upgrade-plan.md](./bootstrap-upgrade-plan.md)

---

## Overview

Successfully upgraded from Bootstrap 4.3.1 to Bootstrap 5.3.3 and implemented dark mode with system preference detection and manual toggle.

---

## Phase 1: Update Bootstrap CDN References

| Plan Item | Status | File(s) Modified |
|-----------|--------|------------------|
| Update CSS CDN to Bootstrap 5.3.3 | Done | `_includes/head.html` |
| Update JS to Bootstrap Bundle 5.3.3 | Done | `_includes/footer.html` |
| Remove jQuery dependency | Done | `_includes/head.html`, `_includes/footer.html` |
| Remove Popper.js (included in bundle) | Done | `_includes/footer.html` |
| Create vanilla JS readingTime | Done | `scripts/readingTime-vanilla.js` (new) |
| Remove jQuery readingTime call | Done | `_layouts/post.html` |

### Changes Detail

**`_includes/head.html`:**
- Changed Bootstrap CSS from StackPath 4.3.1 to jsDelivr 5.3.3
- Removed jQuery 1.9.1 and readingTime.min.js
- Added theme-switcher.js and readingTime-vanilla.js

**`_includes/footer.html`:**
- Removed jQuery 3.3.1 slim
- Removed Popper.js 1.14.7
- Removed Bootstrap 4.3.1 JS
- Added Bootstrap 5.3.3 bundle (includes Popper)

**`scripts/readingTime-vanilla.js`** (new file):
- Pure vanilla JS implementation
- Calculates reading time at 270 words per minute
- Auto-initializes on DOMContentLoaded

---

## Phase 2: Migrate Data Attributes

| Plan Item | Status | File(s) Modified |
|-----------|--------|------------------|
| `data-toggle` → `data-bs-toggle` | Done | `_includes/header.html` |
| `data-target` → `data-bs-target` | Done | `_includes/header.html` |
| Add theme toggle button | Done | `_includes/header.html` |

### Changes Detail

**`_includes/header.html`:**
- Line 6: Updated navbar toggler attributes
- Line 25: Updated Series dropdown toggle
- Line 37: Updated Archive dropdown toggle
- Added theme toggle button with sun/moon SVG icons before closing `</nav>`

---

## Phase 3: Replace Deprecated Classes

| Plan Item | Status | File(s) Modified |
|-----------|--------|------------------|
| Replace `card-columns` with Masonry | Done | `index.html`, `talks.html`, `tags.html`, `_layouts/series.html` |
| Add Masonry JS library | Done | `_includes/footer.html` |
| Replace `font-italic` → `fst-italic` | Done | `_includes/sidebar.html` |
| Add Masonry CSS styles | Done | `_sass/_layout.scss` |

### Changes Detail

**Card Layout Migration:**
- Changed `<div class="card-columns">` to `<div class="row" data-masonry='{"percentPosition": true}'>`
- Wrapped each card in `<div class="col-sm-6 col-lg-4 mb-4">`
- Removed old card-columns media query styles from `_sass/_layout.scss`
- Added `.row[data-masonry] .card { width: 100%; }` for proper sizing

**Files Updated:**
- `index.html` - Home page post cards
- `talks.html` - Talks listing
- `tags.html` - Tags listing
- `_layouts/series.html` - Series post listing

**`_includes/sidebar.html`:**
- Replaced 3 instances of `font-italic` with `fst-italic` (lines 53, 72, 99)

---

## Phase 4: Implement Dark Mode

| Plan Item | Status | File(s) Modified |
|-----------|--------|------------------|
| Add `data-bs-theme` attribute | Done | `_layouts/default.html` |
| Create theme-switcher.js | Done | `scripts/theme-switcher.js` (new) |
| Add CSS custom properties | Done | `css/main.scss` |
| Add dark syntax highlighting | Done | `_sass/_syntax-highlighting.scss` |
| Add dark mode component styles | Done | `_sass/_layout.scss`, `_sass/_base.scss` |

### Changes Detail

**`_layouts/default.html`:**
- Added `data-bs-theme="light"` to `<html>` tag

**`scripts/theme-switcher.js`** (new file):
- IIFE pattern for encapsulation
- localStorage persistence with key `theme`
- System preference detection via `prefers-color-scheme`
- Real-time system preference change listener
- Navbar theme class switching (navbar-light/dark, bg-light/dark)
- Toggle icon switching (sun shown in dark, moon shown in light)

**`css/main.scss`:**
- Added CSS custom properties in `:root` for light mode
- Added `[data-bs-theme="dark"]` selector with dark mode values
- Properties: text colors, background, brand color, grey variants, code styling

**`_sass/_syntax-highlighting.scss`:**
- Added Monokai-based dark theme under `[data-bs-theme="dark"] .highlight`
- Full token coverage for all syntax elements

**`_sass/_layout.scss`:**
- Added dark mode for `.upcoming-event` background (#2a2a2a)
- Added dark mode for table borders (rgb(80, 80, 80))
- Added dark mode for `th` background (#3a3a3a)

**`_sass/_base.scss`:**
- Updated `pre, code` to use CSS custom properties for background/border
- Updated `a.muted-link` to use CSS custom property for color

---

## Files Summary

### Modified Files

| File | Phase | Changes |
|------|-------|---------|
| `_includes/head.html` | 1 | Bootstrap CSS CDN, removed jQuery, added theme scripts |
| `_includes/footer.html` | 1, 3 | Bootstrap JS bundle, Masonry JS |
| `_includes/header.html` | 2 | data-bs-* attributes, theme toggle button |
| `_includes/sidebar.html` | 3 | fst-italic class |
| `_layouts/default.html` | 4 | data-bs-theme attribute |
| `_layouts/post.html` | 1 | Removed jQuery readingTime call |
| `_layouts/series.html` | 3 | Masonry layout |
| `css/main.scss` | 4 | CSS custom properties |
| `_sass/_base.scss` | 4 | Dark mode code/link styles |
| `_sass/_layout.scss` | 3, 4 | Masonry styles, dark mode overrides |
| `_sass/_syntax-highlighting.scss` | 4 | Dark theme colors |
| `index.html` | 3 | Masonry layout |
| `talks.html` | 3 | Masonry layout |
| `tags.html` | 3 | Masonry layout |

### New Files

| File | Purpose |
|------|---------|
| `scripts/theme-switcher.js` | Dark mode toggle and persistence logic |
| `scripts/readingTime-vanilla.js` | Vanilla JS reading time calculator |

---

## Verification Checklist

Per the plan's verification section:

- [ ] **Build:** `bundle exec jekyll serve` - no errors
- [ ] **Navbar:** Mobile toggle works, dropdowns function
- [ ] **Grid:** Card layouts display correctly at all breakpoints
- [ ] **Dark mode toggle:** Clicking switches theme
- [ ] **Persistence:** Theme persists after page refresh
- [ ] **System preference:** Respects OS dark/light setting when no stored preference
- [ ] **Syntax highlighting:** Code blocks readable in both themes
- [ ] **Cross-browser:** Test Chrome, Firefox, Safari

---

## Notes

1. The theme-switcher.js is loaded in `<head>` to apply theme immediately and prevent flash of wrong theme on page load.

2. Bootstrap 5.3's built-in color mode support (`data-bs-theme`) handles most component theming automatically. Custom CSS properties were added for site-specific elements.

3. Masonry library loads asynchronously to avoid blocking page render.

4. The navbar theme classes are toggled programmatically since Bootstrap's color modes don't automatically update legacy navbar classes.
