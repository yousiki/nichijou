# Develop shell for nichijou
{ pkgs, mkShell, ... }:
let
  update-zed-editor = pkgs.writeShellScriptBin "update-zed-editor" ''
    ${pkgs.nix-update}/bin/nix-update \
      zed-editor \
      --flake \
      --override-filename packages/zed-editor/packages.nix \
      --version-regex "^v(?!.*(?:-pre|0\.999999\.0|0\.9999-temporary)$)(.+)$"
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
    update-zed-editor
  ];
}
