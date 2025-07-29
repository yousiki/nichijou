# Nix configurations for all systems.
# Use additional mirrors for hosts in China (tagged with "china").
{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
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
      sandbox = pkgs.stdenv.hostPlatform.isLinux;

      # These users will have additional rights when connecting to the Nix daemon.
      trusted-users = [
        "root"
        "@wheel"
        "@admin"
      ];

      # Never warn about dirty Git/Mercurial trees.
      warn-dirty = false;

      # Substituters.
      substituters =
        let
          # Official Nix cache server.
          official = [
            "https://cache.nixos.org"
          ];
          # cachix caches for binary substitutes.
          cachix = [
            "https://nichijou.cachix.org"
            "https://nix-community.cachix.org"
          ];
          # garnix caches for binary substitutes.
          garnix = [
            "https://cache.garnix.io"
          ];
          # Mirrors for cache.nixos.org in China.
          mirrors = [
            "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=38"
            "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=39"
            "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
          ];
          # Enable additional mirrors for China if the system has the "china" tag.
          isChina = builtins.elem "china" config.${namespace}.tags;
        in
        official ++ cachix ++ garnix ++ lib.optionals isChina mirrors;

      # Public keys for the substituters.
      trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
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
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "darwin=/etc/nix/inputs/darwin";

    # Registry of flakes that are not nixpkgs or self
    registry = lib.mapAttrs (_n: v: { flake = v; }) (
      lib.filterAttrs (n: _v: !(lib.hasPrefix "nixpkgs" n) && n != "self") inputs
    );
  };
}
