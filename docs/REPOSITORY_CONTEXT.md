# Repository Context

**Last Updated:** 2026-02-01

This document provides context about the milestone.github.io repository to help AI assistants and developers quickly understand its structure and purpose.

---

## Overview

This is a personal blog for **Mauro Servienti**, a software professional and public speaker. The site is built with **Jekyll** and hosted on **GitHub Pages** at https://milestone.topics.it.

**Site Title:** "Milestone — Mauro and the sustainable development"

---

## Technology Stack

| Component | Technology | Version/Details |
|-----------|------------|-----------------|
| Static Site Generator | Jekyll | Standard GitHub Pages |
| CSS Framework | Bootstrap | 5.3.3 (CDN) |
| Layout Engine | Masonry | 4.2.2 (for card grids) |
| Markdown | kramdown | Default parser |
| Syntax Highlighting | Rouge | Jekyll built-in |
| Hosting | GitHub Pages | master branch |
| Domain | Custom | milestone.topics.it |

**Plugins:**
- `jekyll-sitemap` - Automatic XML sitemap
- `jekyll-redirect-from` - URL redirects

---

## Directory Structure

```
/
├── _config.yml              # Jekyll configuration
├── _includes/               # Reusable template snippets
│   ├── head.html            # HTML head (meta, CSS, scripts)
│   ├── header.html          # Navigation bar
│   ├── sidebar.html         # Sidebar widgets
│   └── footer.html          # Footer with scripts
├── _layouts/                # Page templates
│   ├── default.html         # Base layout
│   ├── post.html            # Blog posts
│   ├── event.html           # Speaking events
│   ├── talk.html            # Talk descriptions
│   ├── series.html          # Article series
│   ├── tagpage.html         # Tag archives
│   └── page.html            # Generic pages
├── _posts/                  # Blog posts (~121 files)
├── _events/                 # Speaking events (~67 files)
├── _talks/                  # Reusable talks (~11 files)
├── _tags/                   # Tag definitions (~33 files)
├── _sass/                   # SCSS partials
│   ├── main.scss            # Entry point with variables
│   ├── _base.scss           # Base typography/elements
│   ├── _layout.scss         # Layout components
│   ├── _posts.scss          # Post styling
│   ├── _sidebar.scss        # Sidebar widgets
│   ├── _events.scss         # Event pages
│   ├── _talks.scss          # Talk pages
│   ├── _series.scss         # Series pages
│   └── _syntax-highlighting.scss
├── css/                     # Compiled CSS
├── scripts/                 # JavaScript
│   ├── theme-switcher.js    # Dark/light mode
│   └── readingTime-vanilla.js
├── img/                     # Images and assets
│   ├── posts/               # Post header images
│   ├── events/              # Event images
│   ├── talks/               # Talk images
│   └── series/              # Series images
├── series/                  # Series landing pages
├── docs/                    # Documentation
├── .github/                 # GitHub Actions & configs
└── .devcontainer/           # VS Code dev container
```

---

## Content Collections

### Posts (`_posts/`)
Blog articles in Markdown or HTML format.

**Naming:** `YYYY-MM-DD-slug.md`

**Frontmatter:**
```yaml
---
layout: post
title: "Post Title"
author: Mauro Servienti
header_image: /img/posts/slug/header.jpg
synopsis: "Short description for previews"
tags:
- tag1
- tag2
series: optional-series-name
---
```

**Features:**
- Excerpt separator: `<!--more-->`
- Reading time calculation (270 wpm)
- Disqus comments
- GitHub edit/history links
- Previous/next navigation

---

### Events (`_events/`)
Speaking engagements with session details.

**Frontmatter:**
```yaml
---
layout: event
status: upcoming|done
header_image: /img/events/event-name/header.jpg
title: "Event Name"
location: "City, Country"
dates: human-readable dates
event_url: https://event-website.com
calendar:
  start: YYYY-MM-DDTHH:MM:SS
sessions:
- title: "Session Title"
  speakers:
  - name: Mauro Servienti
    profileurl: https://...
  abstract: "Session description"
  language: en|it
  slides: https://...
  demos: https://...
  recording: https://...
---
```

---

### Talks (`_talks/`)
Reusable talk descriptions for event organizers.

**Frontmatter:**
```yaml
---
layout: talk
title: "Talk Title"
header_image: /img/talks/talk-name/header.jpg
languages:
- en
- it
---
```

---

### Tags (`_tags/`)
Tag archive pages.

**Frontmatter:**
```yaml
---
layout: tagpage
tag: tag-identifier
title: Tag Display Name
---
```

---

## Key Features

### Dark Mode
- Toggle button in navbar (sun/moon icons)
- System preference detection (`prefers-color-scheme`)
- LocalStorage persistence
- CSS Custom Properties for theming
- Bootstrap 5.3 `data-bs-theme` attribute

### Responsive Design
- Mobile-first with Bootstrap grid
- Sidebar hidden on screens < 992px
- Navbar collapses on mobile

### Series
Article series grouping related posts. Series pages are in `/series/` with frontmatter linking posts via `series` field.

### Search
DuckDuckGo site-search integration in navbar.

---

## Styling Architecture

### CSS Custom Properties (defined in `css/main.scss`)

```scss
:root {
  --site-text-color: #333;
  --site-background-color: #ffffff;
  --site-brand-color: #0d6efd;
  --site-grey-color: #828282;
  --site-grey-color-light: #e8e8e8;
  --site-grey-color-dark: #424242;
  --site-code-background: #f5f5f5;
  --site-code-border: #e0e0e0;
}

[data-bs-theme="dark"] {
  --site-text-color: #e0e0e0;
  --site-background-color: #212529;
  /* ... dark variants */
}
```

### SCSS Partials
Each component has its own partial file for maintainability. All use CSS custom properties for theme compatibility.

---

## Development

### Local Setup
```bash
# With dev container (recommended)
# Open in VS Code with Dev Containers extension

# Manual
bundle install
bundle exec jekyll serve --watch --livereload
```

### Server URL
- Local: http://localhost:4000
- LiveReload: port 35729

### Creating Content

**New Post:**
```bash
# Create file: _posts/YYYY-MM-DD-slug.md
```

**New Event:**
```bash
# Create file: _events/YYYY-MM-DD-event-name.md
```

---

## External Services

| Service | Purpose | Config Location |
|---------|---------|-----------------|
| Google Analytics | Tracking | `_includes/head.html` (GA4: G-NKQRS8ZKGG) |
| Disqus | Comments | `_layouts/post.html` |
| DuckDuckGo | Search | `_includes/header.html` |
| Typeform | Contact | Footer link |

---

## GitHub Actions

### Link Checker (`.github/workflows/check-links.yml`)
- **Schedule:** Weekly (Thursday 01:00 UTC)
- **Trigger:** Manual (workflow_dispatch)
- **Tool:** markdown-link-check
- **Config:** `.github/mlc_config.json`

---

## Common Tasks

### Adding a Blog Post
1. Create `_posts/YYYY-MM-DD-slug.md` with frontmatter
2. Add header image to `img/posts/slug/`
3. Write content with `<!--more-->` for excerpt break
4. Add relevant tags (must exist in `_tags/`)

### Adding an Event
1. Create `_events/YYYY-MM-DD-event-name.md`
2. Set `status: upcoming` or `status: done`
3. Add sessions with speaker details
4. Add header image to `img/events/`

### Adding a Tag
1. Create `_tags/new-tag.md` with layout and title
2. Use the tag in post frontmatter

### Modifying Styles
1. Edit appropriate SCSS partial in `_sass/`
2. Use CSS custom properties for theme compatibility
3. Jekyll automatically compiles on save

---

## Important Files

| File | Purpose |
|------|---------|
| `_config.yml` | Site-wide Jekyll configuration |
| `_includes/head.html` | Meta tags, CSS, analytics, early scripts |
| `_includes/header.html` | Navigation, theme toggle, search |
| `_includes/footer.html` | Footer content, late-loading scripts |
| `_layouts/default.html` | Base template (grid, sidebar inclusion) |
| `css/main.scss` | CSS entry point, custom properties |
| `scripts/theme-switcher.js` | Dark mode logic |
| `feed.xml` | RSS feed template |
| `CNAME` | Custom domain configuration |

---

## Architecture Decisions

1. **No Custom Ruby Plugins** - Uses only GitHub Pages compatible plugins
2. **Bootstrap CDN** - No build step for CSS framework
3. **Jekyll SCSS** - Built-in compilation, no external tools
4. **Masonry for Grids** - Replaced deprecated Bootstrap card-columns
5. **CSS Custom Properties** - Enables runtime theme switching
6. **Vanilla JavaScript** - No jQuery dependency (removed in Bootstrap 5 upgrade)

---

## Related Documentation

- [Bootstrap Upgrade Plan](./bootstrap-upgrade-plan.md) - Details of Bootstrap 4 to 5 migration
- [Upgrade Summary](./summary.md) - Bootstrap upgrade and dark mode implementation log
