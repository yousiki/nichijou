# sops-nix secret management (darwin)
{flake, ...}: let
  inherit (flake) inputs;
in {
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];
}
