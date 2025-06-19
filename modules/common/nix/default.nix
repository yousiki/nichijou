# Common configuration for nix and nixpkgs
{
  lib,
  inputs,
  system,
  ...
}:
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
      sandbox = lib.snowfall.system.is-linux system;
      # These users will have additional rights when connecting to the Nix daemon.
      trusted-users = [
        "root"
        "@wheel"
        "@admin"
      ];
      # Never warn about dirty Git/Mercurial trees.
      warn-dirty = false;
      # Substituters and public keys.
      substituters = [
        # Official cache server.
        "https://cache.nixos.org" # priority=40
        # Mirrors for cache.nixos.org in China.
        "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
        # Additional cache servers.
        "https://nichijou.cachix.org" # priority=41
        "https://nix-community.cachix.org" # priority=41
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nichijou.cachix.org-1:rbaTU9nLgVW9BK/HSV41vsag6A7/A/caBpcX+cR/6Ps="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Nix automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy.
    optimise.automatic = true;
    # Garbage collector
    gc.automatic = true;
    # List of directories to be searched for <...> file references.
    nixPath = [
      "nixpkgs=flake:nixpkgs"
      "home-manager=flake:home-manager"
    ] ++ lib.optional (lib.snowfall.system.is-darwin system) "darwin=/etc/nix/inputs/darwin";
    # Registry of flakes that are not nixpkgs or self
    registry = lib.mapAttrs (_n: v: { flake = v; }) (
      lib.filterAttrs (n: _v: !(lib.hasPrefix "nixpkgs" n) && n != "self") inputs
    );
  };
  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = system;
    # Nixpkgs configs.
    config = {
      allowUnfree = true;
    };
  };
}
