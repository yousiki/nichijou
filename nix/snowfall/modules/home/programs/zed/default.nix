{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.zed = {
    enable = lib.mkEnableOption "Zed";
  };

  config = lib.mkIf config.${namespace}.programs.zed.enable {
    home.packages = [ pkgs.zed ];
  };
}
