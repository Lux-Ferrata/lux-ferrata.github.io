{
  description = "lux-ferrata.org: Quarto blog";

  # flake.lock is pinned to the same nixpkgs revision as
  # ~/Projects/Probabilistic_Computer/flake.lock (and the Wiki's Anki-deck checks),
  # so the library versions match what the decks were checked against.
  # Move the two pins together.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python314;

        # Lisp-style macros for Python; not in nixpkgs.
        mcpyrate = python.pkgs.buildPythonPackage rec {
          pname = "mcpyrate";
          version = "4.2.0";
          pyproject = true;
          src = python.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "b6b7f3efb205e34aa77ac26715c380882d371ed123b0a508447534f451a3d558";
          };
          build-system = [ python.pkgs.pdm-backend ];
          dependencies = [ python.pkgs.colorama ];
          pythonImportsCheck = [ "mcpyrate" ];
          doCheck = false;
        };

        # The %%tikz cell magic (python/tn_tikz.py, kept by hand from Technonomicon), loaded
        # by the python3 kernel below. It compiles with pdflatex and pdf2svg from `tex` and
        # the dev shell.
        tnTikz = python.pkgs.toPythonModule (
          pkgs.runCommand "tn-tikz" { } ''
            install -Dm644 ${./python/tn_tikz.py} $out/${python.sitePackages}/tn_tikz.py
          ''
        );
        tex = pkgs.texliveBasic.withPackages (
          ps: with ps; [
            standalone
            pgf
            tikz-cd
            amsfonts
          ]
        );

        # PyScript (Python in the reader's browser) for interactive posts, served from the
        # site itself rather than a CDN, like the fonts: the official offline bundle
        # (PyScript core, Pyodide = Python 3.14, MicroPython) plus the Pyodide wheels in
        # _scripts/pyodide-packages.nix (the science stack and its dependencies, ~41 MB,
        # pinned by the sha256 in Pyodide's lock file; regenerate it with
        # _scripts/pyodide-packages.py). `_scripts/pyscript.sh` (Quarto post-render)
        # copies the result into _site/pyscript/. A package not on the list would still
        # come from Pyodide's CDN.
        pyscriptBundle = pkgs.fetchzip {
          url = "https://github.com/pyscript/pyscript/releases/download/2026.7.3/offline_2026.7.3.zip";
          hash = "sha256-8w0+sY+V8nGgyi+HA52QrI6dmQG8D7SxceihUkb6IqU=";
        };
        pyodidePackages = import ./_scripts/pyodide-packages.nix;
        pyscript = pkgs.runCommand "pyscript-site" { } (
          ''
            cp -r ${pyscriptBundle}/pyscript $out
            chmod -R u+w $out
            cp ${pyscriptBundle}/mini-coi-fd.js $out/
          ''
          + pkgs.lib.concatMapStrings (w: ''
            cp ${
              pkgs.fetchurl {
                url = "https://cdn.jsdelivr.net/pyodide/v${pyodidePackages.version}/full/${w.file}";
                inherit (w) sha256;
              }
            } $out/pyodide/${w.file}
          '') pyodidePackages.wheels
        );

        pythonEnv = python.withPackages (
          ps: with ps; [
            # Quarto's Jupyter engine
            jupyter
            ipykernel
            nbclient
            nbformat
            pyyaml

            # p-bit stack
            numpy
            scipy
            numba
            sympy
            matplotlib
            pytest
            hypothesis

            # wider science toolkit
            pandas
            seaborn
            scikit-learn
            torch
            jax
            jaxlib
            qutip
            qiskit
            qiskit-aer

            # explainer posts
            plotly
            manim

            # other kernels and languages
            bash-kernel
            mcpyrate
            tnTikz
          ]
        );

        # 1.12, not 1.13: at this pin julia_113.withPackages fails to resolve its depot
        # ("cannot find name corresponding to UUID 66db9d55-…"). Retry on the next pin move.
        julia = pkgs.julia_112.withPackages [ "IJulia" ];

        # Jupyter kernels, put on JUPYTER_PATH with absolute interpreter paths. Quarto doesn't
        # search the Python env's own share/jupyter, IJulia from Nix registers no kernelspec, and
        # nixpkgs' bash spec points at a bare interpreter without bash_kernel.
        # Posts select one with `jupyter: python3`, `jupyter: julia` or `jupyter: bash`.
        kernelspec =
          name: spec:
          pkgs.writeTextDir "kernels/${name}/kernel.json" (builtins.toJSON spec);
        kernels = pkgs.symlinkJoin {
          name = "blog-jupyter-kernels";
          paths = [
            (kernelspec "python3" {
              display_name = "Python ${python.version}";
              language = "python";
              argv = [
                "${pythonEnv}/bin/python"
                "-m"
                "ipykernel_launcher"
                "--ext=tn_tikz"
                "-f"
                "{connection_file}"
              ];
            })
            (kernelspec "julia" {
              display_name = "Julia ${pkgs.julia_112.version}";
              language = "julia";
              interrupt_mode = "message";
              argv = [
                "${julia}/bin/julia"
                "-i"
                "--color=yes"
                "-e"
                "import IJulia; IJulia.run_kernel()"
                "{connection_file}"
              ];
            })
            (kernelspec "bash" {
              display_name = "Bash";
              language = "bash";
              argv = [
                "${pythonEnv}/bin/python"
                "-m"
                "bash_kernel"
                "-f"
                "{connection_file}"
              ];
            })
          ];
        };
      in
      {
        # Everything: for writing, previewing, and for CI (ci/publish.sh on Akmon).
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.quarto
            pythonEnv
            julia
            pkgs.pyrefly
            pkgs.git
            tex
            pkgs.pdf2svg
          ];
          QUARTO_PYTHON = "${pythonEnv}/bin/python";
          JUPYTER_PATH = "${kernels}";
          PYSCRIPT_DIR = "${pyscript}";
        };
      }
    );
}
