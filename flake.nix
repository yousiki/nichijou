{
  description = "NixOS and nix-darwin configurations for daily life";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
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
      homes.modules = with inputs; [
        nix-index-database.hmModules.nix-index
      ];
      systems.modules = {
        nixos = with inputs; [ nix-index-database.nixosModules.nix-index ];
        darwin = with inputs; [ nix-index-database.darwinModules.nix-index ];
      };
      outputs-builder = channels: {
        formatter = import ./formatter.nix { inherit self inputs channels; };
      };
    };

  nixConfig = {
    extra-substituters = [
      # Official cache server.
      "https://cache.nixos.org" # priority=40
      # Mirrors for cache.nixos.org in China.
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
      # Additional cache servers.
      "https://cache.garnix.io" # priority=41
      "https://catppuccin.cachix.org" # priority=41
      "https://nichijou.cachix.org" # priority=41
      "https://nix-community.cachix.org" # priority=41
      "https://numtide.cachix.org" # priority=41
      "https://zed.cachix.org" # priority=41
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "nichijou.cachix.org-1:rbaTU9nLgVW9BK/HSV41vsag6A7/A/caBpcX+cR/6Ps="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
    ];
  };
}
