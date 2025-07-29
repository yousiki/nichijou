{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        commands = [
          {
            name = "fmt";
            help = "format files";
            command =
              let
                flake-fmt = inputs.flake-fmt.packages.${pkgs.system}.default;
              in
              "${flake-fmt}/bin/flake-fmt";
          }
          {
            name = "switch";
            help = "switch nixos/darwin configuration";
            command =
              let
                inherit (pkgs) nh;
              in
              if pkgs.stdenv.hostPlatform.isDarwin then
                "${nh}/bin/nh darwin switch ."
              else
                "${nh}/bin/nh os switch .";
          }
        ];
      };
    };
}
