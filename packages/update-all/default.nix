{ pkgs, namespace, ... }:
pkgs.writeShellScriptBin "update-all" (
  with pkgs.${namespace};
  ''
    ${update-alt-tab}/bin/update-alt-tab
    ${update-easydict}/bin/update-easydict
    ${update-ice}/bin/update-ice
    ${update-keepingyouawake}/bin/update-keepingyouawake
  ''
)
