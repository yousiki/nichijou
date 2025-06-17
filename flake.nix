{
  description = "NixOS and nix-darwin configurations for daily life";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-drift = {
      url = "github:snowfallorg/drift";
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
    catppuccin = {
      url = "github:catppuccin/nix";
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
      channels-config = {
        allowUnfree = true;
      };
      overlays = with inputs; [
        snowfall-drift.overlays.default
      ];
      outputs-builder = channels: {
        formatter = import ./formatter.nix { inherit self inputs channels; };
      };
    };

  nixConfig = rec {
    substituters = [
      # Official cache server.
      "https://cache.nixos.org" # priority=40
      # Additional cache servers.
      "https://nichijou.cachix.org" # priority=41
      "https://nix-community.cachix.org" # priority=41
      "https://numtide.cachix.org" # priority=41
      "https://catppuccin.cachix.org" # priority=41
      # Mirrors for cache.nixos.org in China.
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
    ];
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "nichijou.cachix.org-1:rbaTU9nLgVW9BK/HSV41vsag6A7/A/caBpcX+cR/6Ps="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };
}
