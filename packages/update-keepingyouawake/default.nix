{ pkgs, ... }:
pkgs.writeShellScriptBin "update-keepingyouawake" ''
  ${pkgs.nix-update}/bin/nix-update \
    keepingyouawake \
    --flake \
    --override-filename packages/keepingyouawake/default.nix
''
