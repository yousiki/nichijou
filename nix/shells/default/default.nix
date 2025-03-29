{ pkgs, mkShell, ... }:
mkShell {
  packages = with pkgs; [
    cachix
    deadnix
    nil
    nixfmt-rfc-style
    statix
  ];
}
