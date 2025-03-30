{
  description = "Nix Configurations for Daily Life";

  inputs = {
    # Nixpkgs: using unstable as default
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";

    # Snowfall lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Sops-nix: secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-index-database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-ld: run dynamic binaries on NixOS
    nix-ld = {
      url = "github:nix-community/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin: my favorite theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Treefmt-nix: code formatting all in one
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deploy-rs: deployment tool
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Haumea: filesystem-based module system for Nix
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      snowfall-lib,
      self,
      ...
    }@inputs:
    snowfall-lib.mkFlake {
      inherit inputs;

      src = ./.;

      snowfall = {
        root = ./nix;

        # Choose a namespace to use for your flake.
        namespace = "nichijou";

        # Add flake metadata that can be processed by tools like Snowfall Frost.
        meta = {
          # A slug to use in documentation when displaying things like file paths.
          name = "nichijou";

          # A title to show for your flake, typically the name.
          title = "Nix Configurations for Daily Life";
        };
      };

      # Configure the channels for your flake.
      channels-config = {
        # Allow unfree packages to be installed.
        allowUnfree = true;

        # Allow broken packages to be installed.
        allowBroken = false;

        # A list of insecure package that are allowed.
        permittedInsecurePackages = [
        ];
      };

      # Configure the overlays for your flake.
      overlays = [ ];

      # Configure the modules for home-manager.
      homes.modules = [
        inputs.catppuccin.homeManagerModules.catppuccin
        inputs.nix-index-database.hmModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
      ];

      # Configure the modules for NixOS and Darwin.
      systems = {
        modules = {
          # Configure the modules for NixOS.
          nixos = [
            inputs.nix-index-database.nixosModules.nix-index
            inputs.nix-ld.nixosModules.nix-ld
            inputs.sops-nix.nixosModules.sops
          ];

          # Configure the modules for darwin.
          darwin = [
            inputs.nix-index-database.darwinModules.nix-index
            inputs.sops-nix.darwinModules.sops
          ];
        };

        # Add modules for NixOS host hakase.
        hosts.hakase.modules = with inputs; [
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
          nixos-hardware.nixosModules.common-pc-ssd
        ];
      };

      outputs-builder = channels: {
        formatter = import ./nix/formatter { inherit self inputs channels; };
      };
    }
    // {
      deploy = import ./nix/deploy { inherit self inputs; };
      # checks = builtins.mapAttrs (
      #   _system: deployLib: deployLib.deployChecks self.deploy
      # ) inputs.deploy-rs.lib;
    };

  nixConfig = rec {
    substituters = [
      # Official cache server.
      "https://cache.nixos.org" # priority=40
      # Additional cache servers.
      "https://cache.garnix.io" # priority=50
      "https://deadnix.cachix.org" # priority=41
      "https://nichijou.cachix.org" # priority=41
      "https://nix-community.cachix.org" # priority=41
      "https://numtide.cachix.org" # priority=41
      # Mirrors for cache.nixos.org in China.
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
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
