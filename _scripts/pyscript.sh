#!/usr/bin/env bash
# Quarto post-render: copy the flake's PyScript directory (the pinned offline bundle plus
# the self-hosted Pyodide wheels) into the rendered site, so posts load PyScript and their
# packages from lux-ferrata.org (/pyscript/…) and not from a CDN.
set -euo pipefail
: "${PYSCRIPT_DIR:?not set: render inside the flake dev shell}"
out="${QUARTO_PROJECT_OUTPUT_DIR:-_site}"
rm -rf "$out/pyscript"
cp -r --no-preserve=mode "$PYSCRIPT_DIR" "$out/pyscript"
