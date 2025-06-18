{ pkgs, ... }:
pkgs.writeShellScriptBin "update-alt-tab" ''
  ${pkgs.nix-update}/bin/nix-update \
    alt-tab \
    --flake \
    --override-filename packages/alt-tab/default.nix
''
