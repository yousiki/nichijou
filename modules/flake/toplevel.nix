# Top-level flake glue to get our configuration working
{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
  ];

  systems = lib.mkForce [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  perSystem = {self', ...}: {
    # Enables 'nix run' to activate.
    packages.default = self'.packages.activate;
  };
}
