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

  config = lib.mkIf config.${namespace}.programs.zotero.enable {
    home.packages = [ pkgs.zotero ];
  };
}
