{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem =
    { inputs', pkgs, ... }:
    {
      devshells.default = {
        name = "nichijou";

        packages = with (pkgs // inputs'.flake-fmt.packages); [
          flake-fmt
          gitMinimal
          nh
        ];

        commands = [
          {
            name = "fmt";
            help = "format the code";
            command = "flake-fmt";
          }
          {
            name = "check";
            help = "check the code format";
            command = "nix flake check --all-systems";
          }
        ];
      };
    };
}
