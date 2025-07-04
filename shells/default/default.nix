# Develop shell for nichijou
{
  pkgs,
  mkShell,
  ...
}:
mkShell {
  packages = with pkgs; [
    age
    deadnix
    deploy-rs
    gh
    git
    helix
    nh
    nil
    nixd
    nixfmt-rfc-style
    sops
    ssh-to-age
    statix
  ];
}
