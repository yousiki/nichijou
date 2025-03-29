# Nix configurations for both NixOS and darwin.
{
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
let
  flake = import "${inputs.self}/flake.nix";

  inherit (flake.nixConfig) substituters trusted-substituters trusted-public-keys;

  registry = lib.mapAttrs (_n: v: { flake = v; }) (
    lib.filterAttrs (n: _v: !(lib.hasPrefix "nixpkgs" n) && n != "self") inputs
  );
in
{
  nix = {
    settings = {
      # Nix will instruct remote build machines to use their own binary substitutes if available.
      builders-use-substitutes = true;
      # Experimental nix features.
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      # Nix will fall back to building from source if a binary substitute fails.
      fallback = true;
      # The garbage collector will keep the derivations from which non-garbage store paths were built.
      keep-derivations = true;
      # The garbage collector will keep the outputs of non-garbage derivations.
      keep-outputs = true;
      # Builds will be performed in a sandboxed environment on Linux.
      sandbox = pkgs.stdenv.isLinux;
      # These users will have additional rights when connecting to the Nix daemon.
      trusted-users = [
        "root"
        "@wheel"
        "@admin"
      ];
      # Never warn about dirty Git/Mercurial trees.
      warn-dirty = false;
      # Substituters and public keys.
      inherit substituters trusted-substituters trusted-public-keys;
    };
    # Nix automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy.
    optimise.automatic = true;
    # Garbage collector
    gc.automatic = true;
    # List of directories to be searched for <...> file references.
    nixPath = [
      "nixpkgs=flake:nixpkgs"
      "home-manager=flake:home-manager"
    ];
    inherit registry;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;
}
