_: {
  flake.modules =
    let
      commonModule =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          tags = config.manifest.tags or [ ];
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
              # Trusted substituters
              trusted-substituters = [
                "https://cache.nixos.org"
                "https://nichijou.cachix.org"
                "https://nix-community.cachix.org"
              ]
              ++ lib.optionals (builtins.elem "china" tags) [
                "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=30"
                "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store?priority=35"
                "https://mirrors.ustc.edu.cn/nix-channels/store?priority=35"
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
        };
    in
    {
      nixos.nix-settings = commonModule;
      darwin.nix-settings = commonModule;
    };
}
