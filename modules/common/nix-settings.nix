{
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
      sandbox = pkgs.stdenv.isLinux;
      # These users will have additional rights when connecting to the Nix daemon.
      trusted-users = [
        "root"
        "@wheel"
        "@admin"
      ];
      # Never warn about dirty Git/Mercurial trees.
      warn-dirty = false;
      # Trusted substituters
      trusted-substituters = [
        "https://cache.clan.lol"
        "https://cache.nixos.org"
        "https://nichijou.cachix.org"
        "https://nix-community.cachix.org"
      ];
    };

    # Nix automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy.
    optimise.automatic = true;
    # Garbage collector
    gc.automatic = true;
    # List of directories to be searched for <...> file references.
    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };

  nixpkgs.config = {
    # Allow unfree packages.
    allowUnfree = true;
    # Disallow broken or unsupported packages.
    allowBroken = false;
    allowUnsupported = false;
  };
}
