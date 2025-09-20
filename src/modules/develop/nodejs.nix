_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          nodejs
          corepack
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
      nixos.develop-nodejs = commonModule;
      darwin.develop-nodejs = commonModule;
      home.deveop-nodejs = homeModule;
    };
}
