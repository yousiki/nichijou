{ pkgs, ... }:
let
  nix-update-template = package:
    pkgs.writeShellScriptBin "update-${package}" ''
      ${pkgs.nix-update}/bin/nix-update \
        ${package} \
        --flake \
        --override-filename packages/${package}/default.nix
    '';

  update-alt-tab = nix-update-template "alt-tab";
  update-easydict = nix-update-template "easydict";
  update-ice = nix-update-template "ice";
  update-keepingyouawake = nix-update-template "keepingyouawake";
in
pkgs.writeShellScriptBin "update-all" ''
  ${update-alt-tab}/bin/update-alt-tab
  ${update-easydict}/bin/update-easydict
  ${update-ice}/bin/update-ice
  ${update-keepingyouawake}/bin/update-keepingyouawake
''
