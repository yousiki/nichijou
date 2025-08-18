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
    home.packages =
      let
        zotero = with pkgs; if stdenv.hostPlatform.isDarwin then brewCasks.zotero else zotero;
      in
      [ zotero ];
  };
}
