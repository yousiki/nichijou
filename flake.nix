{
  inputs = {
    # nixpkgs: Nix Packages collection
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-nixos.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake-parts: Core of a distributed framework for writing Nix Flakes
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # default-systems: Default systems for Nix
    default-systems.url = "github:nix-systems/default";

    # haumea: Filesystem-based module system for Nix
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt-nix: Fast and convenient multi-file formatting with Nix
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake-fmt: A smart formatter wrapper for Nix flakes
    flake-fmt = {
      url = "github:Mic92/flake-fmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # devshell: Per project developer environments
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin: Manage your macOS using Nix
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      haumea,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.default-systems;

      imports = nixpkgs.lib.collect builtins.isPath (
        haumea.lib.load {
          src = ./src/flake-parts;
          loader = haumea.lib.loaders.path;
        }
      );
    };
}
