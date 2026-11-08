#!/usr/bin/env bash
# Publish lux-ferrata.org. Run by .forgejo/workflows/publish.yml on Akmon's host runner
# for every push to main on Forgejo; nothing is ever committed back to the repo.
#
#   1. restore:  copy the runner's freeze cache into _freeze/
#   2. render:   `quarto render` in the flake's full dev shell; with `freeze: auto`,
#                only posts whose source changed since their cached output execute
#   3. save:     after a successful render, replace the cache with the new _freeze/
#   4. deploy:   force-push _site/ as a single commit to GitHub's gh-pages branch,
#                which GitHub Pages serves (Settings -> Pages -> Deploy from branch)
#   5. source:   push main to GitHub, so the public repo shows the source
#
# MODE=dry-run does 1-3 and builds the gh-pages commit, but pushes nothing.
# Needs DEPLOY_KEY: an SSH private key added to the GitHub repo as a deploy key
# with write access.
set -euo pipefail

MODE=${MODE:-live}
GITHUB_REPO=git@github.com:Lux-Ferrata/lux-ferrata.github.io.git
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/lux-ferrata/freeze
SHA=$(git rev-parse HEAD)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

log()  { printf '\n==== %s ====\n' "$*"; }
die()  { echo "ABORT: $*" >&2; exit 1; }
push() { if [ "$MODE" = live ]; then git "$@"; else echo "[dry-run] git $*"; fi; }

# Quarto skips every input file when the project's path has a dot-directory in it,
# and the runner's workspace lives under ~/.cache/act/...: rendered there, the site
# comes out empty (only robots.txt and sitemap.xml). So work in a clone under $WORK.
log "clone ${SHA:0:12} to $WORK/src"
git clone -q --no-checkout "$PWD" "$WORK/src"
git -C "$WORK/src" checkout -q --detach "$SHA"
cd "$WORK/src"

log "restore freeze cache"
rm -rf _freeze
if [ -d "$CACHE" ]; then
  cp -a "$CACHE" _freeze
  echo "restored from $CACHE"
else
  echo "no cache at $CACHE: every post with code executes"
fi

log "render ${SHA:0:12}"
# Quarto's Sass cache (a Deno KV / SQLite file) can't be opened under the runner's
# ~/.cache ("unable to open database file"), so Quarto gets a per-run cache in $WORK.
# Set inside the shell only: nix itself keeps using ~/.cache/nix.
nix develop --command env XDG_CACHE_HOME="$WORK/cache" quarto render

# never deploy a site that's missing its pages
pages=$(find _site -name '*.html' | wc -l)
echo "$pages HTML pages rendered"
[ -f _site/index.html ] && [ -f _site/CNAME ] && [ "$pages" -ge 5 ] \
  || die "_site looks incomplete (index.html, CNAME, >= 5 pages expected); not deploying"

log "save freeze cache"
mkdir -p "$(dirname "$CACHE")"
rm -rf "$CACHE.new"
if [ -d _freeze ]; then cp -a _freeze "$CACHE.new"; else mkdir "$CACHE.new"; fi
rm -rf "$CACHE"
mv "$CACHE.new" "$CACHE"

log "ssh to GitHub"
if [ "$MODE" = live ]; then
  : "${DEPLOY_KEY:?DEPLOY_KEY secret is not set}"
  install -m 600 /dev/null "$WORK/key"
  printf '%s\n' "$DEPLOY_KEY" > "$WORK/key"
  # github.com's published ed25519 host key (api.github.com/meta, checked 2026-11-08)
  echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' \
    > "$WORK/known_hosts"
  export GIT_SSH_COMMAND="ssh -i $WORK/key -o IdentitiesOnly=yes -o UserKnownHostsFile=$WORK/known_hosts -o StrictHostKeyChecking=yes"
else
  echo "[dry-run] skipped"
fi

log "deploy _site to gh-pages"
touch _site/.nojekyll   # serve as-is; Quarto's site_libs/ would otherwise be hidden by Jekyll
(
  export GIT_DIR="$WORK/pages.git" GIT_WORK_TREE="$PWD/_site"
  git init -q -b gh-pages
  git add -A
  git -c user.name="lux-ferrata publish" -c user.email="homelab@ironshark.org" \
    commit -q -m "Publish ${SHA:0:12}"
  git log --stat --oneline -1 | tail -1
  push push --force "$GITHUB_REPO" gh-pages:gh-pages
)

log "mirror source to GitHub main"
push push "$GITHUB_REPO" "$SHA:refs/heads/main"

log "done ($MODE)"
