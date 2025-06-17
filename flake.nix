{
  description = "NixOS and nix-darwin configurations for daily life";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, snowfall-lib, ... }:
    snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
      snowfall = {
        root = ./.;
        namespace = "nichijou";
        meta = {
          name = "nichijou";
          title = "NixOS and nix-darwin configurations for daily life";
        };
      };
      channels-configs = {
        allowUnfree = true;
        allowBroken = false;
        permittedInsecurePackages = [ ];
      };
      overlays = [ ];
      home.modules = [ ];
      system = {
        modules = {
          darwin = [ ];
          nixos = [ ];
        };
      };
      outputs-builder = channels: {
        formatter = import ./formatter.nix { inherit self inputs channels; };
      };
    };
}
