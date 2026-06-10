{
  description = "Multi-host nix-darwin and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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

    sops-nix = {
      url = "github:Mic92/sops-nix";
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

    herdr = {
      url = "github:ogulcancelik/herdr/v0.6.6";
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
  };

  outputs = inputs: let
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];

    nixpkgs = {
      config.allowUnfree = true;

      overlays = [
        inputs.claude-code.overlays.default
        inputs.codex-cli.overlays.default
        inputs.herdr.overlays.default
        (final: prev: {
          herdr = prev.herdr.overrideAttrs (oldAttrs: {
            nativeBuildInputs =
              (oldAttrs.nativeBuildInputs or [])
              ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
                final.xcbuild
                final.cctools
              ];

            buildInputs =
              (oldAttrs.buildInputs or [])
              ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
                final.apple-sdk
              ];
          });
        })
        (import ./nix/overlays/mcp-nixos.nix)
        (import ./nix/overlays/brew-nix.nix {inherit inputs;})
      ];
    };

    blueprintOutputs = inputs.blueprint {
      inherit inputs nixpkgs systems;
      prefix = "nix/";
    };
  in
    (import ./nix/flake-patches/wrap-darwin-system-checks.nix {
      inherit inputs nixpkgs systems;
    })
    blueprintOutputs;
}
