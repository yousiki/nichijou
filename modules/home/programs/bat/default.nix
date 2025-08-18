{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config = lib.mkIf config.${namespace}.programs.bat.enable {
    programs.bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ];
    };
  };
}
