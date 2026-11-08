# Lux Ferrata

Source for [lux-ferrata.org](https://lux-ferrata.org) — a personal blog built with [Quarto](https://quarto.org) and deployed to GitHub Pages.

## Local Development

Requires [Nix](https://nixos.org) with flakes enabled. [direnv](https://direnv.net) is recommended.

```bash
# Enter the dev shell (automatic with direnv)
nix develop

# Start the live preview server
quarto preview
```

The shell provides Quarto and Jupyter kernels for Python 3.14 (scientific stack, PyTorch, JAX, QuTiP, Qiskit, Plotly, Manim), Julia 1.12 and Bash. nixpkgs is pinned to the same revision as the p-bit project.

Code cells execute in CI on Akmon; `_freeze/` is a cache and is not committed.

## Writing a Post

1. Copy `_templates/post/` to a new folder: `posts/my-post-title/`
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

A post with `project:` also gets "previous / next" links through that project's posts, in date order.

## Adding a Project

1. Create `projects/my-project/index.qmd`
2. Add the listing filter pointing at the project slug:

```yaml
---
title: "Project Title"
listing:
  contents: "../../posts/*/index.qmd"   # a bare ../../posts matches nothing
  include:
    project: "my-project"
  sort: "date desc"
  type: default
  fields: [image, date, title, reading-time, description]
---
```

3. Tag posts with `project: "my-project"` — they appear automatically.

## Deployment

The primary remote is Forgejo on Akmon. Pushing to `main` there runs `.forgejo/workflows/publish.yml` → `ci/publish.sh`, which renders the site in the flake's dev shell (executing changed posts, with a freeze cache kept on the runner) and force-pushes the result to the `gh-pages` branch on GitHub, which GitHub Pages serves. `main` is mirrored to GitHub by the same job.
