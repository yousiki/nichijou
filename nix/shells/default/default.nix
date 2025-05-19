{ pkgs, mkShell, ... }:
mkShell {
  packages = with pkgs; [
    deadnix
    nil
    nix
    nixfmt-rfc-style
    statix
  ];
}
