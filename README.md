# Lux Ferrata

Source for [luxferrata.org](https://luxferrata.org) — a personal blog built with [Quarto](https://quarto.org) and deployed to GitHub Pages.

## Local Development

Requires [Nix](https://nixos.org) with flakes enabled. [direnv](https://direnv.net) is recommended.

```bash
# Enter the dev shell (automatic with direnv)
nix develop

# Start the live preview server
quarto preview
```

The shell provides Quarto, Python (with scientific stack), Hy, Bash kernel, and Julia with IJulia.

## Writing a Post

1. Copy `posts/template/` to a new folder: `posts/my-post-title/`
2. Edit `index.qmd` — fill in the frontmatter and write
3. Add a `thumbnail.svg` or `.png` for the listing card
4. Set `draft: false` when ready to publish

### Frontmatter reference

```yaml
title: "Post Title"
description: "One sentence for listings and link previews."
author: "Lux Ferrata"
date: 2026-01-01
categories: [Category]
image: thumbnail.png
draft: true
```

To assign a post to a project, add:

```yaml
project: "project-slug"
```

For sequential series with prev/next navigation:

```yaml
series:
  name: "Series Name"
  order: 1
```

## Adding a Project

1. Create `projects/my-project/index.qmd`
2. Add the listing filter pointing at the project slug:

```yaml
---
title: "Project Title"
listing:
  contents: ../../posts
  include:
    project: ["my-project"]
  sort: "date desc"
  type: default
  fields: [image, date, title, reading-time, description]
---
```

3. Tag posts with `project: "my-project"` — they appear automatically.

## Deployment

Pushing to `main` triggers the GitHub Actions workflow which renders and deploys to the `gh-pages` branch. No manual steps required.
