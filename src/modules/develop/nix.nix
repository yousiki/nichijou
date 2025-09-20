_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          nil
          nixd
        ];

      cond =
        { config, lib, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        (lib.elem "develop" tags) || (lib.elem "nodejs" tags);

      commonModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          environment.systemPackages = packages pkgs;
        };

      homeModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          home.packages = packages pkgs;
        };
    in
    {
      nixos.develop-nix = commonModule;
      darwin.develop-nix = commonModule;
      home.deveop-nix = homeModule;
    };
}
