# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal blog at [luxferrata.org](https://luxferrata.org) built with [Quarto](https://quarto.org) and deployed to GitHub Pages via the `gh-pages` branch. Source lives on `main`; CI renders and publishes automatically on push.

## Commands

The dev environment requires Nix with flakes. `direnv` activates it automatically; otherwise:

```bash
nix develop          # enter the dev shell
quarto preview       # live-reload preview server at localhost:4848
quarto render        # full build to _site/
```

There is no linter, test suite, or build step beyond `quarto render`.

## Architecture

### Content model

- **Posts** — `posts/<slug>/index.qmd`. All posts inherit `posts/_metadata.yml` (freeze, TOC, article layout). Copy `posts/template/index.qmd` for a new post.
- **Projects** — `projects/<slug>/index.qmd`. A project page is a Quarto listing that filters posts by `project: "slug"` in their frontmatter.
- **Top-level pages** — `index.qmd` (landing), `blog.qmd`, `projects.qmd`, `archive.qmd`, `author.qmd`, `content-policies.qmd`.

### Freeze / code execution

`execute: freeze: auto` is set globally in `_quarto.yml`. All posts default to `freeze: true` via `posts/_metadata.yml`, so code cells never re-execute unless the post explicitly overrides with `freeze: false`. Frozen outputs live in `_freeze/`.

### Post frontmatter fields

```yaml
title: "..."
description: "..."       # used in listings and OG tags
author: "Lux Ferrata"
date: YYYY-MM-DD
categories: [...]
image: thumbnail.png     # listing card image
draft: true              # omit or set false to publish
project: "slug"          # links post to projects/<slug>/
series:
  name: "Series Name"
  order: 1               # controls prev/next navigation
```

### Available Jupyter kernels (in dev shell)

Python (matplotlib, numpy, scipy, pandas, seaborn, sympy, mcpyrate), Hy (Lisp on Python), Bash, Julia (IJulia). Coconut (functional Python compiler) is also available as the `coconut` CLI.

### Site config

- `_quarto.yml` — site metadata, navbar, HTML theme (flatly/darkly), MathJax, Giscus comments, GoatCounter analytics.
- `styles.css` — custom CSS overrides.
- `CNAME` — included as a resource so GitHub Pages uses the custom domain.
