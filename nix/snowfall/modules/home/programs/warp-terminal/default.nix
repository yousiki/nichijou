{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.warp-terminal = {
    enable = lib.mkEnableOption "Warp Terminal";
  };

  config = lib.mkIf config.${namespace}.programs.warp-terminal.enable {
    home.packages = [ pkgs.warp-terminal ];
  };
}
