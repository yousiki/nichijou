{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.qq = {
    enable = lib.mkEnableOption "QQ";
  };

  config = lib.mkIf config.${namespace}.programs.qq.enable {
    home.packages = [ pkgs.qq ];
  };
}
