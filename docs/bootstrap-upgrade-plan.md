# Bootstrap 5.3 Upgrade and Dark Mode Implementation Plan

## Overview

Upgrade from Bootstrap 4.3.1 to Bootstrap 5.3.3 and implement dark mode with system preference detection and manual toggle.

## Current State

- **Bootstrap:** 4.3.1 via CDN (StackPath)
- **Dependencies:** jQuery 3.3.1 slim, Popper.js 1.14.7
- **CSS:** Jekyll SCSS compilation, custom partials in `_sass/`
- **Dark mode:** None

---

## Phase 1: Update Bootstrap CDN References

### 1.1 Update CSS (`_includes/head.html` line 38)

```html
<!-- Remove -->
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" ...>

<!-- Add -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
```

### 1.2 Update JS (`_includes/footer.html` lines 75-77)

```html
<!-- Remove jQuery, Popper, and Bootstrap 4 JS -->
<!-- Add Bootstrap 5 Bundle (includes Popper) -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
```

### 1.3 Remove jQuery Dependency

Create vanilla JS replacement `scripts/readingTime-vanilla.js`:
```javascript
function calculateReadingTime(element, wordsPerMinute = 270) {
  const text = element.textContent || element.innerText;
  const words = text.trim().split(/\s+/).length;
  const minutes = Math.ceil(words / wordsPerMinute);
  return minutes < 1 ? 'Less than a minute' : minutes + ' min';
}

document.addEventListener('DOMContentLoaded', function() {
  const content = document.querySelector('.post-content');
  const eta = document.querySelector('.eta');
  if (content && eta) {
    eta.textContent = calculateReadingTime(content);
  }
});
```

- Remove jQuery from `_includes/head.html` (line 56)
- Remove `readingTime.min.js` reference
- Remove jQuery call from `_layouts/post.html` (lines 61-63)

---

## Phase 2: Migrate Data Attributes

Bootstrap 5 changes `data-*` to `data-bs-*`.

### Files to update: `_includes/header.html`

| Line | Before | After |
|------|--------|-------|
| 6 | `data-toggle="collapse" data-target="#main-navbar"` | `data-bs-toggle="collapse" data-bs-target="#main-navbar"` |
| 25 | `data-toggle="dropdown"` | `data-bs-toggle="dropdown"` |
| 37 | `data-toggle="dropdown"` | `data-bs-toggle="dropdown"` |

---

## Phase 3: Replace Deprecated Classes

### 3.1 Replace `card-columns` with Masonry (removed in Bootstrap 5)

Add Masonry JS to `_includes/footer.html` (after Bootstrap bundle):
```html
<script src="https://cdn.jsdelivr.net/npm/masonry-layout@4.2.2/dist/masonry.pkgd.min.js" integrity="sha384-GNFwBvfVxBkLMJpYMOABq3c+d3KnQxudP/mGPkzpZSTYykLBNsZEnG2D9G/X/+7D" crossorigin="anonymous" async></script>
```

Update card container markup in these files:
- `index.html` (line 85)
- `talks.html` (line 15)
- `tags.html` (line 10)
- `_layouts/series.html` (line 20)

Change from:
```html
<div class="card-columns">
```

To:
```html
<div class="row" data-masonry='{"percentPosition": true}'>
```

And wrap each card in a column:
```html
<div class="col-sm-6 col-lg-4 mb-4">
  <div class="card">...</div>
</div>
```

Add CSS to `_sass/_layout.scss` for proper card sizing:
```scss
.row[data-masonry] .card {
  width: 100%;
}
```

### 3.2 Replace `font-italic` with `fst-italic`

Update `_includes/sidebar.html` (lines 53, 72, 99)

---

## Phase 4: Implement Dark Mode

### 4.1 Add theme attribute (`_layouts/default.html` line 3)

```html
<html data-bs-theme="light">
```

### 4.2 Create theme toggle button (`_includes/header.html`)

Add before closing `</nav>`:
```html
<button type="button" class="btn btn-link nav-link ms-auto" id="theme-toggle" aria-label="Toggle dark mode">
  <svg id="theme-icon-light" xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16" style="display: none;">
    <!-- Sun icon (shown in dark mode) -->
    <path d="M8 11a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm0 1a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0zm0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13zm8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5zM3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8zm10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0zm-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0zm9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707zM4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708z"/>
  </svg>
  <svg id="theme-icon-dark" xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
    <!-- Moon icon (shown in light mode) -->
    <path d="M6 .278a.768.768 0 0 1 .08.858 7.208 7.208 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277.527 0 1.04-.055 1.533-.16a.787.787 0 0 1 .81.316.733.733 0 0 1-.031.893A8.349 8.349 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.752.752 0 0 1 6 .278z"/>
  </svg>
</button>
```

### 4.3 Create theme switcher script (`scripts/theme-switcher.js`)

```javascript
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
```

### 4.4 Add CSS custom properties (`css/main.scss`)

```scss
:root {
  --site-text-color: #111;
  --site-text-color-light: #{lighten(#111, 25%)};
  --site-background-color: #fdfdfd;
  --site-brand-color: #2a7ae2;
  --site-grey-color: #828282;
  --site-grey-color-light: #{lighten(#828282, 25%)};
  --site-grey-color-dark: #{darken(#828282, 25%)};
  --site-code-background: #eef;
  --site-code-border: #{lighten(#828282, 25%)};
}

[data-bs-theme="dark"] {
  --site-text-color: #e0e0e0;
  --site-text-color-light: #b0b0b0;
  --site-background-color: #1a1a1a;
  --site-brand-color: #5a9cf0;
  --site-grey-color: #a0a0a0;
  --site-grey-color-light: #6a6a6a;
  --site-grey-color-dark: #c0c0c0;
  --site-code-background: #2d2d2d;
  --site-code-border: #4a4a4a;
}
```

### 4.5 Add dark syntax highlighting (`_sass/_syntax-highlighting.scss`)

Add Monokai-based dark theme colors:

```scss
// Dark mode syntax highlighting
[data-bs-theme="dark"] .highlight {
    background: #272822;

    .c     { color: #75715e; font-style: italic } // Comment
    .err   { color: #f92672; background-color: transparent } // Error
    .k     { color: #66d9ef; font-weight: bold } // Keyword
    .o     { color: #f92672; font-weight: bold } // Operator
    .cm    { color: #75715e; font-style: italic } // Comment.Multiline
    .cp    { color: #75715e; font-weight: bold } // Comment.Preproc
    .c1    { color: #75715e; font-style: italic } // Comment.Single
    .cs    { color: #75715e; font-weight: bold; font-style: italic } // Comment.Special
    .gd    { color: #f92672 } // Generic.Deleted
    .gd .x { color: #f92672 } // Generic.Deleted.Specific
    .ge    { font-style: italic } // Generic.Emph
    .gr    { color: #f92672 } // Generic.Error
    .gh    { color: #a6e22e } // Generic.Heading
    .gi    { color: #a6e22e } // Generic.Inserted
    .gi .x { color: #a6e22e } // Generic.Inserted.Specific
    .go    { color: #888 } // Generic.Output
    .gp    { color: #f8f8f2 } // Generic.Prompt
    .gs    { font-weight: bold } // Generic.Strong
    .gu    { color: #75715e } // Generic.Subheading
    .gt    { color: #f92672 } // Generic.Traceback
    .kc    { color: #66d9ef; font-weight: bold } // Keyword.Constant
    .kd    { color: #66d9ef; font-weight: bold } // Keyword.Declaration
    .kp    { color: #66d9ef; font-weight: bold } // Keyword.Pseudo
    .kr    { color: #66d9ef; font-weight: bold } // Keyword.Reserved
    .kt    { color: #66d9ef; font-weight: bold } // Keyword.Type
    .m     { color: #ae81ff } // Literal.Number
    .s     { color: #e6db74 } // Literal.String
    .na    { color: #a6e22e } // Name.Attribute
    .nb    { color: #f8f8f2 } // Name.Builtin
    .nc    { color: #a6e22e; font-weight: bold } // Name.Class
    .no    { color: #66d9ef } // Name.Constant
    .ni    { color: #f8f8f2 } // Name.Entity
    .ne    { color: #a6e22e; font-weight: bold } // Name.Exception
    .nf    { color: #a6e22e; font-weight: bold } // Name.Function
    .nn    { color: #f8f8f2 } // Name.Namespace
    .nt    { color: #f92672 } // Name.Tag
    .nv    { color: #f8f8f2 } // Name.Variable
    .ow    { color: #f92672; font-weight: bold } // Operator.Word
    .w     { color: #f8f8f2 } // Text.Whitespace
    .mf    { color: #ae81ff } // Literal.Number.Float
    .mh    { color: #ae81ff } // Literal.Number.Hex
    .mi    { color: #ae81ff } // Literal.Number.Integer
    .mo    { color: #ae81ff } // Literal.Number.Oct
    .sb    { color: #e6db74 } // Literal.String.Backtick
    .sc    { color: #e6db74 } // Literal.String.Char
    .sd    { color: #e6db74 } // Literal.String.Doc
    .s2    { color: #e6db74 } // Literal.String.Double
    .se    { color: #ae81ff } // Literal.String.Escape
    .sh    { color: #e6db74 } // Literal.String.Heredoc
    .si    { color: #e6db74 } // Literal.String.Interpol
    .sx    { color: #e6db74 } // Literal.String.Other
    .sr    { color: #e6db74 } // Literal.String.Regex
    .s1    { color: #e6db74 } // Literal.String.Single
    .ss    { color: #e6db74 } // Literal.String.Symbol
    .bp    { color: #f8f8f2 } // Name.Builtin.Pseudo
    .vc    { color: #f8f8f2 } // Name.Variable.Class
    .vg    { color: #f8f8f2 } // Name.Variable.Global
    .vi    { color: #f8f8f2 } // Name.Variable.Instance
    .il    { color: #ae81ff } // Literal.Number.Integer.Long
}
```

### 4.6 Update component styles for dark mode

Files: `_sass/_base.scss`, `_sass/_layout.scss`
- Code blocks use CSS custom properties
- Tables get dark header background
- Custom sections (upcoming-event) get dark variants

```scss
// In _sass/_layout.scss
.home {
  .upcoming-event {
    background-color: #f5f5f5;

    [data-bs-theme="dark"] & {
      background-color: #2a2a2a;
    }
  }
}

th {
  background-color: gainsboro;

  [data-bs-theme="dark"] & {
    background-color: #3a3a3a;
  }
}

table, th, td {
  border: 1px solid rgb(180, 180, 180);

  [data-bs-theme="dark"] & {
    border-color: rgb(80, 80, 80);
  }
}
```

---

## Files Summary

### Modify:
| File | Changes |
|------|---------|
| `_includes/head.html` | Bootstrap CSS CDN, add theme-switcher.js, remove jQuery |
| `_includes/footer.html` | Bootstrap JS CDN, add Masonry JS |
| `_includes/header.html` | data-bs-* attributes, theme toggle button |
| `_includes/sidebar.html` | fst-italic class |
| `_layouts/default.html` | data-bs-theme attribute |
| `_layouts/post.html` | Remove jQuery readingTime call, use vanilla JS |
| `css/main.scss` | CSS custom properties |
| `_sass/_base.scss` | Use CSS custom properties |
| `_sass/_layout.scss` | Masonry card styles, dark mode overrides |
| `_sass/_syntax-highlighting.scss` | Dark theme colors |
| `index.html`, `talks.html`, `tags.html`, `_layouts/series.html` | Masonry row + column markup |

### Create:
| File | Purpose |
|------|---------|
| `scripts/theme-switcher.js` | Dark mode toggle logic |
| `scripts/readingTime-vanilla.js` | Vanilla JS reading time calculator |

---

## Verification

1. **Build:** `bundle exec jekyll serve` - no errors
2. **Navbar:** Mobile toggle works, dropdowns function
3. **Grid:** Card layouts display correctly at all breakpoints
4. **Dark mode toggle:** Clicking switches theme
5. **Persistence:** Theme persists after page refresh
6. **System preference:** Respects OS dark/light setting when no stored preference
7. **Syntax highlighting:** Code blocks readable in both themes
8. **Cross-browser:** Test Chrome, Firefox, Safari
