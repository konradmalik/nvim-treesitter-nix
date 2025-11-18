{
  description = "nvim-treesitter-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter/main";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
              }
            )
          );
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = nvim-treesitter;
        nvim-treesitter = pkgs.vimUtils.buildVimPlugin {
          pname = "nvim-treesitter-nix";
          src = inputs.nvim-treesitter;
          version = inputs.nvim-treesitter.shortRev;
          nvimSkipModule = [ "nvim-treesitter._meta.parsers" ];
          dependencies = (
            let
              nvimTreesitterQueries = pkgs.linkFarm "nvim-treesitter-queries" [
                {
                  name = "queries";
                  path = "${inputs.nvim-treesitter}/runtime/queries";
                }
              ];

              grammars = pkgs.callPackage ./generated.nix { inherit (pkgs.tree-sitter) buildGrammar; };
              grammarDerivations = pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) grammars;
              grammarPlugins = map pkgs.neovimUtils.grammarToPlugin (pkgs.lib.attrValues grammarDerivations);
            in
            [
              nvimTreesitterQueries
            ]
            ++ grammarPlugins
          );
        };
      });

      devShells = forAllSystems (
        pkgs:
        with pkgs;
        let
          pythonEnv = pkgs.python3.withPackages (
            ps:
            (with ps; [
              requests
            ])
          );
        in
        rec {
          python = mkShell {
            packages = [
              pythonEnv
              nurl
            ];
          };
          default = mkShell {
            name = "nvim-treesitter-nix";
            inputsFrom = [
              python
            ];
            packages = [ ];
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
