{ pkgs, ... }:
pkgs.writeShellScriptBin "update-easydict" ''
  ${pkgs.nix-update}/bin/nix-update \
    easydict \
    --flake \
    --override-filename packages/easydict/default.nix
''
