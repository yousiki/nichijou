{ pkgs, ... }:
pkgs.writeShellScriptBin "update-ice" ''
  ${pkgs.nix-update}/bin/nix-update \
    ice \
    --flake \
    --override-filename packages/ice/default.nix
''
