{
  description = "Nix configurations for daily life";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Nix-dariwn
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Code formatting all in one
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-index-database for comma
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VSCode server on NixOS
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Run dynamic binaries on NixOS
    nix-ld = {
      url = "github:nix-community/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git hooks
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin-cursors = {
      url = "github:catppuccin/cursors";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {snowfall-lib, ...} @ inputs:
    snowfall-lib.mkFlake {
      inherit inputs;

      src = ./.;

      snowfall = {
        namespace = "nichijou";
      };

      channels-config = {
        allowUnfree = true;
        allowBroken = false;
        permittedInsecurePackages = [];
      };

      overlays = [];

      homes.modules = with inputs; [
        catppuccin.homeManagerModules.catppuccin
        nix-index-database.hmModules.nix-index
        nixos-vscode-server.homeModules.default
        sops-nix.homeManagerModules.sops
      ];

      systems.modules = {
        darwin = with inputs; [
          nix-index-database.darwinModules.nix-index
          sops-nix.darwinModules.sops
        ];
        nixos = with inputs; [
          nix-index-database.nixosModules.nix-index
          nix-ld.nixosModules.nix-ld
          nixos-vscode-server.nixosModules.default
          sops-nix.nixosModules.sops
        ];
      };

      systems.hosts.hakase.modules = with inputs; [
        nixos-hardware.nixosModules.common-cpu-intel-cpu-only
        nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
        nixos-hardware.nixosModules.common-pc-ssd
      ];

      outputs-builder = channels: let
        treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs ./treefmt.nix;
      in {
        formatter = treefmtEval.config.build.wrapper;
      };
    };

  nixConfig = rec {
    substituters = [
      "https://cache.garnix.io"
      "https://cache.nixos.org"
      "https://deadnix.cachix.org"
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
      "https://nichijou.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "deadnix.cachix.org-1:R7kK+K1CLDbLrGph/vSDVxUslAmq8vhpbcz6SH9haJE="
      "nichijou.cachix.org-1:rbaTU9nLgVW9BK/HSV41vsag6A7/A/caBpcX+cR/6Ps="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };
}
