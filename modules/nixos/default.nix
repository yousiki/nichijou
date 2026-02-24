# This is your nixos configuration.
# For home configuration, see /modules/home/*
{flake, ...}: let
  inherit (flake) inputs;
in {
  imports = [
    inputs.self.nixosModules.common
  ];

  nixpkgs.overlays = [
    # Up-to-date Claude Code package
    inputs.claude-code.overlays.default
  ];

  services.openssh.enable = true;
}
