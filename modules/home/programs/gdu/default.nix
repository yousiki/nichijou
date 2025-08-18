{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.gdu = {
    enable = lib.mkEnableOption "gdu";
  };

  config = lib.mkIf config.${namespace}.programs.gdu.enable {
    home.packages = with pkgs; [ gdu ];
  };
}
