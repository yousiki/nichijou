# Catppuccin configuration for all users
{
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = lib.mkDefault true;
    flavor = lib.mkDefault "mocha";
  };
}
