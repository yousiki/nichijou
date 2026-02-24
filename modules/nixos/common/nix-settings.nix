{
  pkgs,
  lib,
  inputs,
  ...
}: {
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Allow remote builders to use their own substitutes
      builders-use-substitutes = true;
      # Enable flakes and the unified nix CLI
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      # Fall back to building from source if a substitute fails
      fallback = true;
      # Disable the global flake registry; only local pins are used
      flake-registry = "";
      # Keep derivations and outputs so dev shells and builds remain rooted
      keep-derivations = true;
      keep-outputs = true;
      # Sandboxing only works reliably on Linux
      sandbox = pkgs.stdenv.isLinux;
      # Users with elevated Nix daemon access
      trusted-users = [
        "root"
        "@wheel"
        "@admin"
      ];
      # Suppress warnings about uncommitted changes in flake repos
      warn-dirty = false;
      # Auto-accept nixConfig from flakes (safe on a personal machine)
      accept-flake-config = true;
      # Pre-approved caches
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://claude-code.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ber+5Ccp0Tcp7faDcneTaXcJdY="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };

    # Hard-link identical store paths to save disk space
    optimise.automatic = true;
    # Periodically remove unreachable store paths
    gc.automatic = true;
    # Resolve <nixpkgs> via the flake input
    nixPath = ["nixpkgs=flake:nixpkgs"];
    # Pin the flake registry to match this flake's inputs
    registry = lib.mkForce (lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs);
  };

  nixpkgs.config = {
    allowBroken = false;
    allowUnsupported = false;
    allowUnfree = true;
  };
}
