_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          python3
          ruff
          uv
        ];

      cond =
        { config, lib, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        (lib.elem "develop" tags) || (lib.elem "python" tags);

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
      nixos.develop-python = commonModule;
      darwin.develop-python = commonModule;
      home.develop-python = homeModule;
    };
}
