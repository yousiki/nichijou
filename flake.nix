{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "nix-darwin";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    inputs@{
      flake-parts,
      haumea,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.clan-core.flakeModules.default
        inputs.treefmt-nix.flakeModule
      ];

      # https://docs.clan.lol/guides/flake-parts
      clan = {
        imports = [ ./clan.nix ];
      };

      flake =
        let
          modules = haumea.lib.load {
            src = ./modules;
            loader = haumea.lib.loaders.path;
            transformer = _: m: if builtins.isAttrs m && m ? default then m.default else m;
          };
        in
        {
          modules = {
            darwin = (modules.common or { }) // (modules.darwin or { });
            nixos = (modules.common or { }) // (modules.nixos or { });
            home = (modules.common or { }) // (modules.home or { });
          };
        };

      perSystem =
        { pkgs, inputs', ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = [
              inputs'.clan-core.packages.clan-cli
              pkgs.nh
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };
        };
    };
}
