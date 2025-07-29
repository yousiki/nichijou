{
  inputs,
  ...
}:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt.programs = {
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rfc-style;
        };
        deadnix.enable = true;
        statix.enable = true;
      };
    };
}
