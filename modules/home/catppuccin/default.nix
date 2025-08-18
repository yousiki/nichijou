# Catppuccin theme for all supported programs.
{ lib, ... }:
{
  catppuccin = {
    enable = true;
    flavor = lib.mkDefault "mocha";
  };
}
