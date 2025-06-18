{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.zotero = {
    enable = lib.mkEnableOption "Zotero";
  };

  config =
    let
      cfg = config.${namespace}.programs.zotero;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        zotero
      ];
    };
}
