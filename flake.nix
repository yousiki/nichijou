{
  description = "Nix Configurations for Daily Life";

  inputs = {
    # Nixpkgs (default: unstable)
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";

    # Snowfall
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-systems
    nix-systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
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

        # Configure the channels for your flake.
        channels = {
          # Allow unfree packages to be installed.
          allowUnfree = true;

          # Allow broken packages to be installed.
          allowBroken = false;

          # A list of insecure package that are allowed.
          permittedInsecurePackages = [
          ];
        };

        # Configure the overlays for your flake.
        overlays = [];

        # Configure the modules for home-manager.
        homes.modules = [];

        systems.modules = {
          # Configure the modules for NixOS.
          nixos = [];

          # Configure the modules for darwin.
          darwin = [
          ];
        };
      };
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
