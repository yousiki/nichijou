{ pkgs, mkShell, ... }:
mkShell {
  packages = with pkgs; [
    cachix
    deadnix
    deploy-rs
    nil
    nix
    nixfmt-rfc-style
    statix
  ];
}
