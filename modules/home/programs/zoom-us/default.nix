{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.zoom-us = {
    enable = lib.mkEnableOption "zoom.us";
  };

  config = lib.mkIf config.${namespace}.programs.zoom-us.enable {
    home.packages = [ pkgs.zoom-us ];
  };
}
