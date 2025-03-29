{ pkgs, mkShell, ... }:
mkShell {
  packages = with pkgs; [
    cachix
    deadnix
    nil
    nix
    nixfmt-rfc-style
    statix
  ];
}
