# Virtualisation for darwin systems using Orbstack.
# Only applied to systems tagged with "virtualisation".
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  enableVirtualisation = builtins.elem "virtualisation" config.${namespace}.tags;
in
lib.mkIf enableVirtualisation {
  environment.systemPackages = [
    pkgs.brewCasks.orbstack
  ];
}
