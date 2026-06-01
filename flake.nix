{
  description = "Multi-host nix-darwin and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
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

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    aprilnea-homebrew-tap = {
      url = "github:aprilnea/homebrew-tap";
      flake = false;
    };

    buo-homebrew-cask-upgrade = {
      url = "github:buo/homebrew-cask-upgrade";
      flake = false;
    };

  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "nix/";

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
        inputs.claude-code.overlays.default
        inputs.codex-cli.overlays.default
        (
          final: prev:
          if prev.stdenv.hostPlatform.isDarwin then inputs.brew-nix.overlays.default final prev else { }
        )
      ];
    };
}
