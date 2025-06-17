# Develop shell for nichijou
{ pkgs, mkShell, ... }:
mkShell {
  packages = with pkgs; [
    deadnix
    gh
    git
    helix
    nh
    nil
    nixd
    nixfmt-rfc-style
    statix
  ];
}
