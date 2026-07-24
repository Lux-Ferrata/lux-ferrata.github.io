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
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git

            # Publishing engine
            quarto

            # Required for executing Jupyter notebooks and Python code blocks!
            python3
            python3Packages.jupyter
            python3Packages.matplotlib
            python3Packages.numpy
            python3Packages.scipy
            python3Packages.pandas
            python3Packages.seaborn
            python3Packages.sympy
          ];

          shellHook = ''
            echo "=========================================="
            echo "Quarto version: $(quarto --version)"
            echo "Python version: $(python3 --version)"
            echo "=========================================="
            echo "Run 'quarto preview' to start the live server."
            echo "=========================================="
          '';
        };
      }
    );
}
