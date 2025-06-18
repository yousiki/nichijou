# Develop shell for nichijou
{ pkgs, mkShell, ... }:
let
  update-keepingyouawake = pkgs.writeShellScriptBin "update-keepingyouawake" ''
    ${pkgs.nix-update}/bin/nix-update \
      keepingyouawake \
      --flake \
      --override-filename packages/keepingyouawake/default.nix
  '';
in
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
    update-keepingyouawake
  ];
}
