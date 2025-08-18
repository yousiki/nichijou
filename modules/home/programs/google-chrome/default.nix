{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.google-chrome = {
    enable = lib.mkEnableOption "Google Chrome";
  };

  config = lib.mkIf config.${namespace}.programs.google-chrome.enable {
    home.packages = [ pkgs.google-chrome ];
  };
}
