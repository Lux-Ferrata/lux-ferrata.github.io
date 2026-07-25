{
  description = "Personal Blog Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        coconut = pkgs.python3Packages.buildPythonPackage rec {
          pname = "coconut";
          version = "3.2.0";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "0c64554deef3a35b2688368315cc2087dd8244e1b13d6b869fe5c2e679d6a0ad";
          };
          doCheck = false;
        };
        mcpyrate = pkgs.python3Packages.buildPythonPackage rec {
          pname = "mcpyrate";
          version = "4.2.0";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "b6b7f3efb205e34aa77ac26715c380882d371ed123b0a508447534f451a3d558";
          };
          doCheck = false;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git

            # Publishing engine
            quarto

            # Python kernel + scientific stack
            python3
            python3Packages.jupyter
            python3Packages.matplotlib
            python3Packages.numpy
            python3Packages.scipy
            python3Packages.pandas
            python3Packages.seaborn
            python3Packages.sympy

            # Coconut (functional Python compiler)
            coconut

            # mcpyrate (Lisp-style macros and AST metaprogramming for Python)
            mcpyrate

            # Hy (Lisp dialect on Python — uses the Python kernel)
            python3Packages.hy

            # Bash kernel
            python3Packages.bash-kernel

            # Julia kernel (scientific computing / physics)
            (julia.withPackages [ "IJulia" ])
          ];

          shellHook = ''
            echo "=========================================="
            echo "Quarto version: $(quarto --version)"
            echo "Python version: $(python3 --version)"
            echo "Julia version:  $(julia --version)"
            echo "=========================================="
            echo "Run 'quarto preview' to start the live server."
            echo "=========================================="
          '';
        };
      }
    );
}
