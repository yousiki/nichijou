# Develop shell for nichijou
{
  pkgs,
  mkShell,
  ...
}:
mkShell {
  packages = with pkgs; [
    colmena
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
