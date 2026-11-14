# Copy of Technonomicon Modules/Knowledge/_tn_tikz.py (the %%tikz magic). Keep it
# identical by hand, like tn.theme; the flake installs it and the python3 kernel loads it.
"""%%tikz: a TikZ cell compiled to SVG (IPython extension `tn_tikz`).

The cell takes the same text as a ```tikz block in Grimoire markdown
(Obsidian's TikZJax format, drawn in nvim by Technonomicon
Modules/Core/_nvim-tikz.lua): optional preamble lines such as
\\usepackage{tikz-cd} or \\usetikzlibrary{arrows}, then \\begin{document} ...
\\end{document}; or just a tikzpicture (any environment); or bare drawing
commands, which are wrapped in a tikzpicture.

    %%tikz
    \\draw[->] (0,0) -- (1,1) node[right] {$x^2$};

Compiled with pdflatex, converted with pdf2svg (both from PATH), shown as an
SVG output, so it is saved in the notebook and appears in Molten, VSCodium,
Jupyter and Quarto alike. On a white background by default, like
matplotlib's figures, so it reads on dark themes too; --transparent drops it.

pdf2svg names every figure's glyphs and clip paths the same way (glyph-0-0,
...). VSCodium and JupyterLab put all of a notebook's SVG outputs into one
page, where those ids collide and a figure draws another's glyphs, so each
figure's ids get a prefix made from its own content.

Loaded by the Grimoire kernel (`--ext=tn_tikz`), or by hand with
`%load_ext tn_tikz`. The blog keeps a copy in python/tn_tikz.py; update it by
hand when this file changes.
"""

import hashlib
import pathlib
import re
import shutil
import subprocess
import tempfile

from IPython.core.error import UsageError
from IPython.core.magic_arguments import argument, magic_arguments, parse_argstring
from IPython.display import SVG

PREAMBLE = r"""\documentclass[border=2pt]{standalone}
\usepackage{tikz}
\usepackage{amsmath,amssymb}
"""


def _document(cell, transparent):
    body = cell.strip()
    if "\\begin{" not in body:
        body = "\\begin{tikzpicture}\n" + body + "\n\\end{tikzpicture}"
    if "\\begin{document}" not in body:
        body = "\\begin{document}\n" + body + "\n\\end{document}"
    background = "" if transparent else "\\pagecolor{white}\n"
    return PREAMBLE + background + body + "\n"


def _latex_errors(log):
    """The '!' lines of a LaTeX log, each with the two lines after it."""
    lines = log.splitlines()
    out = []
    for i, line in enumerate(lines):
        if line.startswith("!"):
            out.extend(lines[i : i + 3])
    return "\n".join(out) or log[-1500:]


def _prefix_ids(svg):
    prefix = "tikz-" + hashlib.sha1(svg.encode()).hexdigest()[:10] + "-"
    svg = re.sub(r'\bid="([^"]+)"', lambda m: f'id="{prefix}{m[1]}"', svg)
    svg = re.sub(r'\bhref="#([^"]+)"', lambda m: f'href="#{prefix}{m[1]}"', svg)
    return re.sub(r"url\(#([^)]+)\)", lambda m: f"url(#{prefix}{m[1]})", svg)


def compile_tikz(cell, transparent=False):
    """The cell's TikZ as SVG text."""
    for tool in ("pdflatex", "pdf2svg"):
        if shutil.which(tool) is None:
            raise UsageError(f"%%tikz: {tool} isn't on PATH")
    with tempfile.TemporaryDirectory(prefix="tn-tikz-") as tmp:
        d = pathlib.Path(tmp)
        (d / "fig.tex").write_text(_document(cell, transparent))
        run = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "fig.tex"],
            cwd=d, capture_output=True, text=True,
        )
        if run.returncode != 0:
            log = (d / "fig.log").read_text(errors="replace") if (d / "fig.log").exists() else run.stdout
            raise UsageError("%%tikz: LaTeX failed\n" + _latex_errors(log))
        subprocess.run(["pdf2svg", "fig.pdf", "fig.svg"], cwd=d, check=True)
        return _prefix_ids((d / "fig.svg").read_text())


@magic_arguments()
@argument("--transparent", action="store_true", help="no white background")
def tikz(line, cell):
    """Compile the cell's TikZ and show it as SVG."""
    args = parse_argstring(tikz, line)
    return SVG(data=compile_tikz(cell, transparent=args.transparent))


def load_ipython_extension(ip):
    ip.register_magic_function(tikz, magic_kind="cell", magic_name="tikz")
