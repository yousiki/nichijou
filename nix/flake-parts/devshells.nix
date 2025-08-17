{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      devshells.default =
        let
          inherit (pkgs) nh;
          nh-os-alias =
            if pkgs.stdenv.hostPlatform.isDarwin then "${nh}/bin/nh darwin" else "${nh}/bin/nh os";
          flake-fmt = inputs.flake-fmt.packages.${pkgs.system}.default;
        in
        {
          commands = [
            {
              name = "fmt";
              help = "format files";
              command = "${flake-fmt}/bin/flake-fmt";
            }
            {
              name = "bd";
              help = "build nixos/darwin configuration";
              command = "${nh-os-alias} build .";
            }
            {
              name = "sw";
              help = "switch nixos/darwin configuration";
              command = "${nh-os-alias} switch .";
            }
            {
              name = "cl";
              help = "clean all nix profiles";
              command = "${nh}/bin/nh clean all";
            }
          ];

          packages = [
            nh
          ];
        };
    };
}
