_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          rustup
        ];

      cond =
        { config, lib, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        (lib.elem "develop" tags) || (lib.elem "rust" tags);

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
      nixos.develop-rust = commonModule;
      darwin.develop-rust = commonModule;
      home.develop-rust = homeModule;
    };
}
