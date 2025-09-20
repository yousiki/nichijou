_: {
  flake.modules =
    let
      packages = pkgs: with pkgs; ([ _1password-cli ] ++ (lib.optional stdenv.isLinux _1password-gui));

      cond =
        { config, lib, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        (lib.elem "desktop" tags) || (lib.elem "1password" tags);

      nixosModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          environment.systemPackages = packages pkgs;

          nixpkgs.config.allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
              "1password-cli"
            ];
        };

      darwinModule =
        {
          config,
          lib,
          pkgs,
          ...
        }@args:
        lib.mkMerge [
          (nixosModule { inherit config lib pkgs; })
          (lib.mkIf (cond args) {
            homebrew.casks = [ "1password" ];
          })
        ];

      homeModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          home.packages = packages pkgs;
        };
    in
    {
      nixos.app-1password = nixosModule;
      darwin.app-1password = darwinModule;
      home.app-1password = homeModule;
    };
}
