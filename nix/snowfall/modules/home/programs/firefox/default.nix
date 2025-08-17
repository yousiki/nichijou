{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.firefox = {
    enable = lib.mkEnableOption "Firefox";
  };

  config = lib.mkIf config.${namespace}.programs.firefox.enable {
    home.packages = [ pkgs.firefox ];
  };
}
